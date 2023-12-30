#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include <zstd.h>

#include "common.h"
#include "sources.h"
#include "bootstrap.h"
#include "NSUserDefaults+appDefaults.h"

extern int decompress_tar_zstd(const char* src_file_path, const char* dst_file_path);


int getCFMajorVersion()
{
    return ((int)kCFCoreFoundationVersionNumber / 100) * 100;
}

void rebuildSignature(NSString *directoryPath)
{
    int machoCount=0, libCount=0;
    
    NSString *resolvedPath = [[directoryPath stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath isDirectory:YES] includingPropertiesForKeys:@[NSURLIsSymbolicLinkKey] options:0 errorHandler:nil];
    
    NSString* ldidPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/ldid"];
    NSString* fastSignPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/fastPathSign"];
    NSString* entitlementsPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/bootstrap.entitlements"];
    NSString* ldidEntitlements = [NSString stringWithFormat:@"-S%@", entitlementsPath];
    
    for (NSURL *enumURL in directoryEnumerator) {
        @autoreleasepool {
            NSNumber *isSymlink;
            [enumURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];
            if (isSymlink && ![isSymlink boolValue]) {
                
                FILE *fp = fopen(enumURL.fileSystemRepresentation, "rb");
                ASSERT(fp != NULL);
                
                bool ismacho=false, islib=false;
                machoGetInfo(fp, &ismacho, &islib);
                
                if(ismacho) {
                    
                    SYSLOG("重建 %@", enumURL.path);
                    
                    machoCount++;
                    
                    if(!islib) {
                        libCount++;
                        ASSERT(spawnRoot(ldidPath, @[@"-M", ldidEntitlements, enumURL.path], nil, nil) == 0);
                    }
                    
                    ASSERT(spawnRoot(fastSignPath, @[enumURL.path], nil, nil) == 0);
                }
                
                fclose(fp);

            }
        }
    }
    
    SYSLOG("重建完成! machoCount=%d, libCount=%d", machoCount, libCount);

}

void disableRootHideBlacklist()
{
    NSString* roothideDir = jbroot(@"/var/mobile/Library/RootHide");
    if(![NSFileManager.defaultManager fileExistsAtPath:roothideDir]) {
        ASSERT([NSFileManager.defaultManager createDirectoryAtPath:roothideDir withIntermediateDirectories:YES attributes:nil error:nil]);
    }
    
    NSString *configFilePath = jbroot(@"/var/mobile/Library/RootHide/RootHideConfig.plist");
    NSMutableDictionary* defaults = [NSMutableDictionary dictionaryWithContentsOfFile:configFilePath];
    if(!defaults) defaults = [[NSMutableDictionary alloc] init];
    [defaults setValue:@YES forKey:@"blacklistDisabled"];
    [defaults writeToFile:configFilePath atomically:YES];
}

int buildPackageSources()
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    ASSERT([[NSString stringWithFormat:@(DEFAULT_SOURCES), getCFMajorVersion()] writeToFile:jbroot(@"/etc/apt/sources.list.d/default.sources") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
    //Users in some regions seem to be unable to access github.io
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
    if([[NSUserDefaults.appDefaults valueForKey:@"locale"] isEqualToString:@"CN"]) {
        ASSERT([[NSString stringWithUTF8String:ALT_SOURCES] writeToFile:jbroot(@"/etc/apt/sources.list.d/sileo.sources") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    }
    
    if(![fm fileExistsAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra")])
    {
        NSDictionary* attr = @{NSFilePosixPermissions:@(0755), NSFileOwnerAccountID:@(501), NSFileGroupOwnerAccountID:@(501)};
        ASSERT([fm createDirectoryAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra") withIntermediateDirectories:YES attributes:attr error:nil]);
    }
    
    ASSERT([[NSString stringWithFormat:@(ZEBRA_SOURCES), getCFMajorVersion()] writeToFile:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
    return 0;
}

int rebuildBasebin()
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    if([fm fileExistsAtPath:jbroot(@"/basebin")]) {
        ASSERT([fm removeItemAtPath:jbroot(@"/basebin") error:nil]);
    }
    
    NSString* basebinPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin"];
    ASSERT([fm copyItemAtPath:basebinPath toPath:jbroot(@"/basebin") error:nil]);
    
    unlink(jbroot(@"/basebin/.jbroot").fileSystemRepresentation);
    ASSERT([fm createSymbolicLinkAtPath:jbroot(@"/basebin/.jbroot") withDestinationPath:jbroot(@"/") error:nil]);
    
    return 0;
}

int startBootstrapd()
{
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"daemon",@"-f"], &log, &err);
    if(status != 0) {
        STRAPLOG("引导服务器加载失败(%d):\n%@\nERR:%@", status, log, err);
        ABORT();
    }

    STRAPLOG("引导服务器加载成功");
    
    sleep(1);
    
     status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"check"], &log, &err);
    if(status != 0) {
        STRAPLOG("引导服务器检查失败(%d):\n%@\nERR:%@", status, log, err);
        ABORT();
    }
    STRAPLOG("引导服务器检查成功");
    
    return 0;
}

int InstallBootstrap(NSString* jbroot_path)
{
    STRAPLOG("安装引导...");
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    ASSERT(mkdir(jbroot_path.fileSystemRepresentation, 0755) == 0);
    ASSERT(chown(jbroot_path.fileSystemRepresentation, 0, 0) == 0);
    
    NSString* bootstrapZstFile = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"strapfiles/bootstrap-%d.tar.zst", getCFMajorVersion()]];
    if(![fm fileExistsAtPath:bootstrapZstFile]) {
        STRAPLOG("无法找到引导文件,可能此版本的应用不支持iOS%d", NSProcessInfo.processInfo.operatingSystemVersion.majorVersion);
        return -1;
    }
    
    NSString* bootstrapTarFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bootstrap.tar"];
    if([fm fileExistsAtPath:bootstrapTarFile])
        ASSERT([fm removeItemAtPath:bootstrapTarFile error:nil]);
    
    ASSERT(decompress_tar_zstd(bootstrapZstFile.fileSystemRepresentation, bootstrapTarFile.fileSystemRepresentation) == 0);
    
    NSString* tarPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"tar"];
    ASSERT(spawnRoot(tarPath, @[@"-xpkf", bootstrapTarFile, @"-C", jbroot_path], nil, nil) == 0);
    
    STRAPLOG("重新构建引导二进制文件");
    rebuildSignature(jbroot_path);
    
    NSString* jbroot_secondary = [NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", jbrand()];
    ASSERT(mkdir(jbroot_secondary.fileSystemRepresentation, 0755) == 0);
    ASSERT(chown(jbroot_secondary.fileSystemRepresentation, 0, 0) == 0);
    
    ASSERT([fm moveItemAtPath:jbroot(@"/var") toPath:[jbroot_secondary stringByAppendingPathComponent:@"/var"] error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:jbroot(@"/var") withDestinationPath:@"private/var" error:nil]);
    
    ASSERT([fm removeItemAtPath:jbroot(@"/private/var") error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:jbroot(@"/private/var") withDestinationPath:[jbroot_secondary stringByAppendingPathComponent:@"/var"] error:nil]);
    
    ASSERT([fm removeItemAtPath:[jbroot_secondary stringByAppendingPathComponent:@"/var/tmp"] error:nil]);
    ASSERT([fm moveItemAtPath:jbroot(@"/tmp") toPath:[jbroot_secondary stringByAppendingPathComponent:@"/var/tmp"] error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:jbroot(@"/tmp") withDestinationPath:@"var/tmp" error:nil]);
    
    for(NSString* item in [fm contentsOfDirectoryAtPath:jbroot_path error:nil])
    {
        if([item isEqualToString:@"var"])
            continue;

        ASSERT([fm createSymbolicLinkAtPath:[jbroot_secondary stringByAppendingPathComponent:item] withDestinationPath:[jbroot_path stringByAppendingPathComponent:item] error:nil]);
    }
    
    ASSERT([fm removeItemAtPath:[jbroot_secondary stringByAppendingPathComponent:@".jbroot"] error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:[jbroot_secondary stringByAppendingPathComponent:@".jbroot"]
                    withDestinationPath:jbroot_path error:nil]);
    
    
    STRAPLOG("状态:构建基础二进制文件");
    ASSERT(rebuildBasebin() == 0);
    
    STRAPLOG("状态:启动引导服务");
    ASSERT(startBootstrapd() == 0);
    
    STRAPLOG("状态:完成引导服务初始化");
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnBootstrap((char*[]){"/bin/sh", "/prep_bootstrap.sh", NULL}, &log, &err);
    if(status != 0) {
        STRAPLOG("失败(%d):%@\nERR:%@", status, log, err);
        ABORT();
    }

    if(![fm fileExistsAtPath:jbroot(@"/var/mobile/Library/Preferences")])
    {
        NSDictionary* attr = @{NSFilePosixPermissions:@(0755), NSFileOwnerAccountID:@(501), NSFileGroupOwnerAccountID:@(501)};
        ASSERT([fm createDirectoryAtPath:jbroot(@"/var/mobile/Library/Preferences") withIntermediateDirectories:YES attributes:attr error:nil]);
    }
    
    ASSERT(buildPackageSources() == 0);
    
    
    STRAPLOG("状态:正在安装插件包");
    NSString* libkrw0_dummy = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"libkrw0-dummy.deb"];
    ASSERT(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(libkrw0_dummy).fileSystemRepresentation, NULL}, nil, nil) == 0);
    
    NSString* sileoDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"sileo.deb"];
    ASSERT(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(sileoDeb).fileSystemRepresentation, NULL}, nil, nil) == 0);
    
    NSString* zebraDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"zebra.deb"];
    ASSERT(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(zebraDeb).fileSystemRepresentation, NULL}, nil, nil) == 0);
    
    ASSERT([[NSString stringWithFormat:@"%d",BOOTSTRAP_VERSION] writeToFile:jbroot(@"/.bootstrapped") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
    STRAPLOG("状态:引导程序安装完成");
    
    
    return 0;
}

int ReRandomizeBootstrap()
{
    //jbroot() disabled
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    uint64_t prev_jbrand = jbrand();
    uint64_t new_jbrand = jbrand_new();
    
    ASSERT( [fm moveItemAtPath:[NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", prev_jbrand]
                        toPath:[NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", new_jbrand] error:nil] );
    
    ASSERT([fm moveItemAtPath:[NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", prev_jbrand]
                       toPath:[NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", new_jbrand] error:nil]);
    
    
    NSString* jbroot_path = [NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", new_jbrand];
    NSString* jbroot_secondary = [NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", new_jbrand];

    for(NSString* item in [fm contentsOfDirectoryAtPath:jbroot_path error:nil])
    {
        if([item isEqualToString:@"var"])
            continue;

        NSString* checkpath = [jbroot_secondary stringByAppendingPathComponent:item];
        
        struct stat st;
        if(lstat(checkpath.fileSystemRepresentation, &st)==0) {
            ASSERT([fm removeItemAtPath:checkpath error:nil]);
        }
        
        ASSERT([fm createSymbolicLinkAtPath:checkpath withDestinationPath:[jbroot_path stringByAppendingPathComponent:item] error:nil]);
    }
    
    ASSERT([fm removeItemAtPath:[jbroot_path stringByAppendingPathComponent:@"/private/var"] error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:[jbroot_path stringByAppendingPathComponent:@"/private/var"]
                    withDestinationPath:[jbroot_secondary stringByAppendingPathComponent:@"/var"] error:nil]);
    
    ASSERT([fm removeItemAtPath:[jbroot_secondary stringByAppendingPathComponent:@".jbroot"] error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:[jbroot_secondary stringByAppendingPathComponent:@".jbroot"]
                    withDestinationPath:jbroot_path error:nil]);
    
    //jbroot() enabled
    
    STRAPLOG("状态:正在构建基础二进制文件");
    ASSERT(rebuildBasebin() == 0);
    
    STRAPLOG("状态:正在启动引导程序(Bootstrapd)");
    ASSERT(startBootstrapd() == 0);
    
    STRAPLOG("状态:正在更新软链接");
    ASSERT(spawnBootstrap((char*[]){"/bin/sh", "/usr/libexec/updatelinks.sh", NULL}, nil, nil) == 0);
    
    return 0;
}

int bootstrap()
{
    ASSERT(getuid()==0);
    
    STRAPLOG("引导中...");
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* jbroot_path = find_jbroot();
    
    if(!jbroot_path) {
        STRAPLOG("设备未启动...");
        
        jbroot_path = [NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", jbrand_new()];
        
        STRAPLOG("引导 @ %@", jbroot_path);
        
        ASSERT(InstallBootstrap(jbroot_path) == 0);
        
    } else if(![fm fileExistsAtPath:jbroot(@"/.bootstrapped")]) {
        STRAPLOG("删除未完成的引导程序 %@", jbroot_path);
        
        uint64_t prev_jbrand = jbrand();
        
        ASSERT([fm removeItemAtPath:jbroot_path error:nil]);
        
        NSString* jbroot_secondary = [NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", prev_jbrand];
        if([fm fileExistsAtPath:jbroot_secondary]) {
            STRAPLOG("删除未完成的引导程序 %@", jbroot_secondary);
            ASSERT([fm removeItemAtPath:jbroot_secondary error:nil]);
        }
        
        STRAPLOG("引导 @ %@", jbroot_path);
        
        ASSERT(InstallBootstrap(jbroot_path) == 0);
        
    } else {
        STRAPLOG("设备已启动: %@", jbroot_path);
        
        STRAPLOG("状态:重新随机化 jbroot");
        
        ASSERT(ReRandomizeBootstrap() == 0);
    }

    ASSERT(disableRootHideBlacklist()==0);
    
    STRAPLOG("Status: Rebuilding Apps");
    ASSERT(spawnBootstrap((char*[]){"/bin/sh", "/basebin/rebuildapps.sh", NULL}, nil, nil) == 0);

    NSDictionary* bootinfo = @{@"bootsession":getBootSession()};
    ASSERT([bootinfo writeToFile:jbroot(@"/basebin/.bootinfo.plist") atomically:YES]);
    
    STRAPLOG("状态:引导成功");
    
    return 0;
}



@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (BOOL)_LSPrivateRebuildApplicationDatabasesForSystemApps:(BOOL)arg1
                                                  internal:(BOOL)arg2
                                                      user:(BOOL)arg3;
@end

int unbootstrap()
{
    SYSLOG("取消引导...");
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* dirpath = @"/var/containers/Bundle/Application/";
    for(NSString* item in [fm directoryContentsAtPath:dirpath])
    {
        if([fm fileExistsAtPath:
             [dirpath stringByAppendingPathComponent:@".installed_dopamine"]])
            continue;
        
        if(is_jbroot_name(item.UTF8String)) {
            SYSLOG("删除 %@ @ %@", item, dirpath);
            ASSERT([fm removeItemAtPath:[dirpath stringByAppendingPathComponent:item] error:nil]);
        }
    }
    
    
    dirpath = @"/var/mobile/Containers/Shared/AppGroup/";
    for(NSString* item in [fm directoryContentsAtPath:dirpath])
    {
        if([fm fileExistsAtPath:
             [dirpath stringByAppendingPathComponent:@".installed_dopamine"]])
            continue;
        
        if(is_jbroot_name(item.UTF8String)) {
            SYSLOG("删除 %@ @ %@", item, dirpath);
            ASSERT([fm removeItemAtPath:[dirpath stringByAppendingPathComponent:item] error:nil]);
        }
    }

    SYSLOG("引导程序已卸载!");
    
    [LSApplicationWorkspace.defaultWorkspace _LSPrivateRebuildApplicationDatabasesForSystemApps:YES internal:YES user:YES];
    
    killAllForApp("/usr/libexec/backboardd");
    
    return 0;
}


bool isBootstrapInstalled()
{
    if(!find_jbroot())
        return NO;

    if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.bootstrapped")])
        return NO;
    
    return YES;
}

bool isSystemBootstrapped()
{
    if(!isBootstrapInstalled()) return false;
    
    NSDictionary* bootinfo = [NSDictionary dictionaryWithContentsOfFile:jbroot(@"/basebin/.bootinfo.plist")];
    if(!bootinfo) return false;
    
    NSString* bootsession = bootinfo[@"bootsession"];
    if(!bootsession) return false;
    
    return [bootsession isEqualToString:getBootSession()];
}
