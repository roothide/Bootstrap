#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include <zstd.h>

#include "common.h"
#include "sources.h"
#include "NSUserDefaults+appDefaults.h"

extern int decompress_tar_zstd(const char* src_file_path, const char* dst_file_path);


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
                    
                    SYSLOG("rebuild %@", enumURL.path);
                    
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
    
    SYSLOG("rebuild finished! machoCount=%d, libCount=%d", machoCount, libCount);

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
    
    ASSERT([[NSString stringWithUTF8String:DEFAULT_SOURCES] writeToFile:jbroot(@"/etc/apt/sources.list.d/default.sources") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
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
    
    ASSERT([[NSString stringWithUTF8String:ZEBRA_SOURCES] writeToFile:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
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

int bootstrap()
{
    ASSERT(getuid()==0);
    
    SYSLOG("bootstrap...");
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* jbroot_path = find_jbroot();
    
    if(!jbroot_path) {
        SYSLOG("device is not strapped...");
        
        jbroot_path = [NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", jbrand_new()];
        SYSLOG("bootstrap @ %@", jbroot_path);
        
        ASSERT(mkdir(jbroot_path.fileSystemRepresentation, 0755) == 0);
        ASSERT(chown(jbroot_path.fileSystemRepresentation, 0, 0) == 0);
        
        NSString* bootstrapZstFile = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"bootstrap-ssh.tar.zst"];
        NSString* bootstrapTarFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bootstrap-ssh.tar"];
        if([fm fileExistsAtPath:bootstrapTarFile])
            ASSERT([fm removeItemAtPath:bootstrapTarFile error:nil]);
        
        ASSERT(decompress_tar_zstd(bootstrapZstFile.fileSystemRepresentation, bootstrapTarFile.fileSystemRepresentation) == 0);
        
        NSString* tarPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"tar"];
        ASSERT(spawnRoot(tarPath, @[@"-xpkf", bootstrapTarFile, @"-C", jbroot_path], nil, nil) == 0);
        
    } else {
        SYSLOG("device is strapped: %@", jbroot_path);
    }
    
    if(![fm fileExistsAtPath:jbroot(@"/.bootstrapped")]) {
        SYSLOG("bootstrap not finished...");
        
        rebuildSignature(jbroot_path);
        
        NSString* jbroot_secondary = [NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", jbrand()];
        ASSERT(mkdir(jbroot_secondary.fileSystemRepresentation, 0755) == 0);
        ASSERT(chown(jbroot_secondary.fileSystemRepresentation, 0, 0) == 0);
        
        ASSERT([fm moveItemAtPath:jbroot(@"/var") toPath:[jbroot_secondary stringByAppendingPathComponent:@"/var"] error:nil]);
        ASSERT([fm createSymbolicLinkAtPath:jbroot(@"/var") withDestinationPath:[jbroot_secondary stringByAppendingPathComponent:@"/var"] error:nil]);
        
        ASSERT([fm removeItemAtPath:[jbroot_secondary stringByAppendingPathComponent:@"/var/tmp"] error:nil]);
        ASSERT([fm moveItemAtPath:jbroot(@"/tmp") toPath:[jbroot_secondary stringByAppendingPathComponent:@"/var/tmp"] error:nil]);
        ASSERT([fm createSymbolicLinkAtPath:jbroot(@"/tmp") withDestinationPath:@"var/tmp" error:nil]);
        
        
        for(NSString* item in [fm contentsOfDirectoryAtPath:jbroot_path error:nil])
        {
            if([item isEqualToString:@"var"])
                continue;
            
            if([fm fileExistsAtPath:[jbroot_secondary stringByAppendingPathComponent:item]]) {
                ASSERT([fm removeItemAtPath:[jbroot_secondary stringByAppendingPathComponent:item] error:nil]);
            }
            ASSERT([fm createSymbolicLinkAtPath:[jbroot_secondary stringByAppendingPathComponent:item] withDestinationPath:[jbroot_path stringByAppendingPathComponent:item] error:nil]);
        }
        
        /////////////////////

        if(![fm fileExistsAtPath:jbroot(@"/var/mobile/Library/Preferences")])
        {
            NSDictionary* attr = @{NSFilePosixPermissions:@(0755), NSFileOwnerAccountID:@(501), NSFileGroupOwnerAccountID:@(501)};
            ASSERT([fm createDirectoryAtPath:jbroot(@"/var/mobile/Library/Preferences") withIntermediateDirectories:YES attributes:attr error:nil]);
        }
        
        STRAPLOG(Localized("Status: Building Base Binaries"));
        ASSERT(rebuildBasebin() == 0);
        
        ASSERT(buildPackageSources() == 0);
        
        if([fm fileExistsAtPath:jbroot(@"/prep_bootstrap.sh")])
        {
            STRAPLOG(Localized("Status: Finalizing Bootstrap"));
            ASSERT(spawnBootstrap((char*[]){"/bin/sh", "/prep_bootstrap.sh", NULL}, nil, nil) == 0);
            
            STRAPLOG(Localized("Status: Installing Packages"));
            NSString* fakekrw = [NSString stringWithFormat:@"/rootfs/%@/fakekrw.deb", NSBundle.mainBundle.bundlePath];
            ASSERT(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", fakekrw.fileSystemRepresentation, NULL}, nil, nil) == 0);
            
            NSString* sileoDeb = [NSString stringWithFormat:@"/rootfs/%@/sileo.deb", NSBundle.mainBundle.bundlePath];
            ASSERT(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", sileoDeb.fileSystemRepresentation, NULL}, nil, nil) == 0);
            
            NSString* zebraDeb = [NSString stringWithFormat:@"/rootfs/%@/zebra.deb", NSBundle.mainBundle.bundlePath];
            ASSERT(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", zebraDeb.fileSystemRepresentation, NULL}, nil, nil) == 0);
            
            ASSERT([fm createFileAtPath:jbroot(@"/.bootstrapped") contents:nil attributes:nil]);
            
            STRAPLOG(Localized("Status: Bootstrap Installed"));
        }
        else
        {
            STRAPLOG(Localized("Status: Updating Symlinks"));
            ASSERT(spawnBootstrap((char*[]){"/bin/sh", "/usr/libexec/updatelinks.sh", NULL}, nil, nil) == 0);
            
            STRAPLOG(Localized("Status: Rebuilding Apps"));
            ASSERT(spawnBootstrap((char*[]){"/bin/sh", "/basebin/app-rebuild", NULL}, nil, nil) == 0);
        }
        
        STRAPLOG(Localized("Status: Bootstrap Successful"));
    }
    
    return 0;
}


int unbootstrap()
{
    SYSLOG("unbootstrap...");
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* dirpath = @"/var/containers/Bundle/Application/";
    for(NSString* item in [fm directoryContentsAtPath:dirpath])
    {
        if([fm fileExistsAtPath:
             [dirpath stringByAppendingPathComponent:@".installed_dopamine"]])
            continue;
        
        if(is_jbroot_name(item.UTF8String)) {
            SYSLOG("remove %@ @ %@", item, dirpath);
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
            SYSLOG("remove %@ @ %@", item, dirpath);
            ASSERT([fm removeItemAtPath:[dirpath stringByAppendingPathComponent:item] error:nil]);
        }
    }

    SYSLOG("bootstrap uninstalled!");
    
    return 0;
}


bool isDeviceBootstrapped()
{
    if(!find_jbroot())
        return NO;
    
    if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.bootstrapped")])
        return NO;
    
    return YES;
}
