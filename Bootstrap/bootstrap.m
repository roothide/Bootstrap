#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include <zstd.h>

#include "common.h"
#include "sources.h"
#include "bootstrap.h"
#include "NSUserDefaults+appDefaults.h"
#include "AppInfo.h"

extern int decompress_tar_zstd(const char* src_file_path, const char* dst_file_path);


int getCFMajorVersion()
{
    if(@available(iOS 16.0, *)) {
        return 1900;
    }
    
    return ((int)kCFCoreFoundationVersionNumber / 100) * 100;
}

void rebuildSignature(NSString *directoryPath)
{
    int machoCount=0, libCount=0;
    
    NSString *resolvedPath = [[directoryPath stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath isDirectory:YES] includingPropertiesForKeys:@[NSURLIsSymbolicLinkKey] options:0 errorHandler:nil];
    
    NSString* ldidPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/ldid"];
    NSString* fastSignPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/fastPathSign"];
    NSString* entitlementsPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/entitlements/nickchan.entitlements"];
    NSString* ldidEntitlements = [NSString stringWithFormat:@"-S%@", entitlementsPath];
    
    for (NSURL *enumURL in directoryEnumerator) {
        @autoreleasepool {
            NSNumber* isFile=nil;
            [enumURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];
            if (isFile && [isFile boolValue]) {

                bool ismacho=false, islib=false;
                ASSERT(machoGetInfo(enumURL.fileSystemRepresentation, &ismacho, &islib));
                
                if(ismacho) {
                    
                    SYSLOG("rebuild %@", enumURL.path);
                    
                    machoCount++;
                    
                    if(!islib) {
                        libCount++;
                        //note: only basebin/ldid -M supports deep merge
                        ASSERT(spawn_root(ldidPath, @[@"-M", ldidEntitlements, enumURL.path], nil, nil) == 0);
                    }
                    
                    ASSERT(spawn_root(fastSignPath, @[enumURL.path], nil, nil) == 0);
                }
            }
        }
    }
    
    STRAPLOG("rebuild finished! machoCount=%d, libCount=%d", machoCount, libCount);

}

int fixPackageSources()
{
    NSArray* sileoSources = [NSFileManager.defaultManager directoryContentsAtPath:jbroot(@"/etc/apt/sources.list.d")];
    ASSERT(sileoSources != NULL);
    for(NSString* item in sileoSources)
    {
        NSString* source = [jbroot(@"/etc/apt/sources.list.d") stringByAppendingPathComponent:item];
        NSString* sileoList = [NSString stringWithContentsOfFile:source encoding:NSUTF8StringEncoding error:nil];
        ASSERT(sileoList != NULL);
        
        if([sileoList containsString:@"iphoneos-arm64e/2000"]) {
            if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/lib/apt/lists")])
                ASSERT([NSFileManager.defaultManager removeItemAtPath:jbroot(@"/var/lib/apt/lists") error:nil]);
            if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/lib/apt/sileolists")])
                ASSERT([NSFileManager.defaultManager removeItemAtPath:jbroot(@"/var/lib/apt/sileolists") error:nil]);
        }
        
        sileoList = [sileoList stringByReplacingOccurrencesOfString:@"iphoneos-arm64e/2000" withString:@"iphoneos-arm64e/1900"];
        
        ASSERT([sileoList writeToFile:source atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    }
    
    
    NSString* zebraList = [NSString stringWithContentsOfFile:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list") encoding:NSUTF8StringEncoding error:nil];
    ASSERT(zebraList != NULL);
    if([zebraList containsString:@"iphoneos-arm64e/2000"]) {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/lists")])
            ASSERT([NSFileManager.defaultManager removeItemAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/lists") error:nil]);
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/zebra.db")])
            ASSERT([NSFileManager.defaultManager removeItemAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/zebra.db") error:nil]);
    }
    zebraList = [zebraList stringByReplacingOccurrencesOfString:@"iphoneos-arm64e/2000" withString:@"iphoneos-arm64e/1900"];
    ASSERT([zebraList writeToFile:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
    return 0;
}

int buildPackageSources()
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    if(![fm fileExistsAtPath:jbroot(@"/etc/apt/sources.list.d/default.sources")])
    {
        ASSERT([[NSString stringWithFormat:@(DEFAULT_SOURCES), getCFMajorVersion()] writeToFile:jbroot(@"/etc/apt/sources.list.d/default.sources") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
        
        //    //Users in some regions seem to be unable to access github.io
        //    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
        //    if([[NSUserDefaults.appDefaults valueForKey:@"locale"] isEqualToString:@"CN"]) {
        //        ASSERT([[NSString stringWithFormat:@(ALT_SOURCES), getCFMajorVersion()] writeToFile:jbroot(@"/etc/apt/sources.list.d/sileo.sources") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
        //    }
    }
    
    if(![fm fileExistsAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra")])
    {
        NSDictionary* attr = @{NSFilePosixPermissions:@(0755), NSFileOwnerAccountID:@(501), NSFileGroupOwnerAccountID:@(501)};
        ASSERT([fm createDirectoryAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra") withIntermediateDirectories:YES attributes:attr error:nil]);
    }
    
    if(![fm fileExistsAtPath:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list")])
    {
        ASSERT([[NSString stringWithFormat:@(ZEBRA_SOURCES), getCFMajorVersion()] writeToFile:jbroot(@"/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    }
    
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
    ASSERT([fm createSymbolicLinkAtPath:jbroot(@"/basebin/.jbroot") withDestinationPath:@"../.jbroot" error:nil]); //use a relative path so libvroot won't remove it
    
    return 0;
}

int startBootstrapServer()
{
    NSString* log=nil;
    NSString* err=nil;
    int status = spawn_root(jbroot(@"/basebin/bootstrapd"), @[@"daemon",@"-f"], &log, &err);
    if(status != 0) {
        STRAPLOG("bootstrap server load faild(%d):\n%@\nERR:%@", status, log, err);
        ABORT();
    }

    STRAPLOG("bootstrap server load successful");
    
    sleep(1);
    
     status = spawn_root(jbroot(@"/basebin/bsctl"), @[@"check"], &log, &err);
    if(status != 0) {
        STRAPLOG("bootstrap server check faild(%d):\n%@\nERR:%@", status, log, err);
        ABORT();
    }
    STRAPLOG("bootstrap server check successful");
    
    return 0;
}

int InstallBootstrap(NSString* jbroot_path)
{
    STRAPLOG("install bootstrap...");
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    ASSERT(mkdir(jbroot_path.fileSystemRepresentation, 0755) == 0);
    ASSERT(chown(jbroot_path.fileSystemRepresentation, 0, 0) == 0);

    find_jbroot(YES); //refresh
    
    //jbroot() and jbrand() available now
    
    NSString* bootstrapZstFile = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"strapfiles/bootstrap-%d.tar.zst", getCFMajorVersion()]];
    if(![fm fileExistsAtPath:bootstrapZstFile]) {
        STRAPLOG("can not find bootstrap file, maybe this version of the app is not for iOS%d", NSProcessInfo.processInfo.operatingSystemVersion.majorVersion);
        return -1;
    }
    
    NSString* bootstrapTarFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"bootstrap.tar"];
    if([fm fileExistsAtPath:bootstrapTarFile])
        ASSERT([fm removeItemAtPath:bootstrapTarFile error:nil]);
    
    ASSERT(decompress_tar_zstd(bootstrapZstFile.fileSystemRepresentation, bootstrapTarFile.fileSystemRepresentation) == 0);
    
    NSString* tarPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"tar"];
    ASSERT(spawn_root(tarPath, @[@"-xpkf", bootstrapTarFile, @"-C", jbroot_path], nil, nil) == 0);
    
    STRAPLOG("rebuild boostrap binaries");
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
    
    ASSERT([fm createSymbolicLinkAtPath:[jbroot_secondary stringByAppendingPathComponent:@".jbroot"]
                    withDestinationPath:jbroot_path error:nil]);
    
    
    STRAPLOG("Status: Building Base Binaries");
    ASSERT(rebuildBasebin() == 0);
    
    STRAPLOG("Status: Starting Bootstrapd");
    ASSERT(startBootstrapServer() == 0);
    
    STRAPLOG("Status: Finalizing Bootstrap");
    NSString* log=nil;
    NSString* err=nil;
    int status = spawn_bootstrap_binary((char*[]){"/bin/sh", "/prep_bootstrap.sh", NULL}, &log, &err);
    if(status != 0) {
        STRAPLOG("faild(%d):%@\nERR:%@", status, log, err);
        ABORT();
    }

    if(![fm fileExistsAtPath:jbroot(@"/var/mobile/Library/Preferences")])
    {
        NSDictionary* attr = @{NSFilePosixPermissions:@(0755), NSFileOwnerAccountID:@(501), NSFileGroupOwnerAccountID:@(501)};
        ASSERT([fm createDirectoryAtPath:jbroot(@"/var/mobile/Library/Preferences") withIntermediateDirectories:YES attributes:attr error:nil]);
    }
    
    ASSERT(buildPackageSources() == 0);
    
    
    STRAPLOG("Status: Installing Packages");
    NSString* libkrw0_dummy = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"libkrw0-dummy.deb"];
    ASSERT(spawn_bootstrap_binary((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(libkrw0_dummy).fileSystemRepresentation, NULL}, nil, nil) == 0);
    
    NSString* sileoDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"sileo.deb"];
    ASSERT(spawn_bootstrap_binary((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(sileoDeb).fileSystemRepresentation, NULL}, nil, nil) == 0);
    ASSERT(spawn_bootstrap_binary((char*[]){"/usr/bin/uicache", "-p", "/Applications/Sileo.app", NULL}, nil, nil) == 0);
    
    NSString* zebraDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"zebra.deb"];
    ASSERT(spawn_bootstrap_binary((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(zebraDeb).fileSystemRepresentation, NULL}, nil, nil) == 0);
    ASSERT(spawn_bootstrap_binary((char*[]){"/usr/bin/uicache", "-p", "/Applications/Zebra.app", NULL}, nil, nil) == 0);
    
    NSString* roothideappDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"roothideapp.deb"];
    ASSERT(spawn_bootstrap_binary((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(roothideappDeb).fileSystemRepresentation, NULL}, nil, nil) == 0);
    ASSERT(spawn_bootstrap_binary((char*[]){"/usr/bin/uicache", "-p", "/Applications/RootHide.app", NULL}, nil, nil) == 0);
    
    ASSERT([[NSString stringWithFormat:@"%d",BOOTSTRAP_VERSION] writeToFile:jbroot(@"/.thebootstrapped") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    ASSERT([fm copyItemAtPath:jbroot(@"/.thebootstrapped") toPath:[jbroot_secondary stringByAppendingPathComponent:@".thebootstrapped"] error:nil]);
    
    STRAPLOG("Status: Bootstrap Installed");
    
    if(@available(iOS 16.0, *)) {
        ASSERT([[NSString new] writeToFile:jbroot(@"/var/mobile/.allow_url_schemes") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    }
    
    return 0;
}

int fixBootstrapSymlink(NSString* path)
{
    const char* jbpath = jbroot(path).fileSystemRepresentation;
    
    struct stat st={0};
    ASSERT(lstat(jbpath, &st) == 0);
    if (!S_ISLNK(st.st_mode)) {
        return 0;
    }
    
    char link[PATH_MAX+1] = {0};
    ASSERT(readlink(jbpath, link, sizeof(link)-1) > 0);
    if(link[0] != '/') {
        return 0;
    }

    //stringByStandardizingPath won't remove /private/ prefix if the path does not exist on disk
    NSString* _link = @(link).stringByStandardizingPath.stringByResolvingSymlinksInPath;
    
    NSString *pattern = @"^(?:/private)?/var/containers/Bundle/Application/\\.jbroot-[0-9A-Z]{16}(/.+)$";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:_link options:0 range:NSMakeRange(0, [_link length])];
    ASSERT(match != nil);
    
    NSString* target = [_link substringWithRange:[match rangeAtIndex:1]];
    NSString* newlink = [@".jbroot" stringByAppendingPathComponent:target];
    
    ASSERT(unlink(jbpath) == 0);
    ASSERT(symlink(newlink.fileSystemRepresentation, jbpath) == 0);
    ASSERT(access(jbpath, F_OK) == 0);
    
    return 0;
}

int ReRandomizeBootstrap()
{
    uint64_t prev_jbrand = jbrand();
    uint64_t new_jbrand = jbrand_new();
    
    //jbroot() and jbrand() unavailable now
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    ASSERT( [fm moveItemAtPath:[NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", prev_jbrand]
                        toPath:[NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", new_jbrand] error:nil] );
    
    ASSERT([fm moveItemAtPath:[NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", prev_jbrand]
                       toPath:[NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", new_jbrand] error:nil]);
    
    
    NSString* jbroot_path = [NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", new_jbrand];
    NSString* jbroot_secondary = [NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/.jbroot-%016llX", new_jbrand];
    
    ASSERT([fm removeItemAtPath:[jbroot_path stringByAppendingPathComponent:@"/private/var"] error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:[jbroot_path stringByAppendingPathComponent:@"/private/var"]
                    withDestinationPath:[jbroot_secondary stringByAppendingPathComponent:@"/var"] error:nil]);
    
    ASSERT([fm removeItemAtPath:[jbroot_secondary stringByAppendingPathComponent:@".jbroot"] error:nil]);
    ASSERT([fm createSymbolicLinkAtPath:[jbroot_secondary stringByAppendingPathComponent:@".jbroot"]
                    withDestinationPath:jbroot_path error:nil]);
    
    find_jbroot(YES); //refresh
    
    //jbroot() and jbrand() available now

    STRAPLOG("Status: Building Base Binaries");
    ASSERT(rebuildBasebin() == 0);
    
    STRAPLOG("Status: Starting Bootstrapd");
    ASSERT(startBootstrapServer() == 0);
    
    STRAPLOG("Status: Updating Symlinks");
    ASSERT(fixBootstrapSymlink(@"/bin/sh") == 0);
    ASSERT(fixBootstrapSymlink(@"/usr/bin/sh") == 0);
    ASSERT(spawn_bootstrap_binary((char*[]){"/bin/sh", "/usr/libexec/updatelinks.sh", NULL}, nil, nil) == 0);
    
    ASSERT(buildPackageSources() == 0);
    ASSERT(fixPackageSources() == 0);
    
    return 0;
}

void fixMobileDirectories()
{
    NSFileManager* fm = NSFileManager.defaultManager;
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:jbroot(@"/var/mobile/") isDirectory:YES] includingPropertiesForKeys:@[NSURLIsDirectoryKey] options:0 errorHandler:nil];
    
    for (NSURL *enumURL in directoryEnumerator) {
        @autoreleasepool {
            
            if([enumURL.path containsString:@"/var/mobile/Library/pkgmirror/"]
               || [enumURL.path hasSuffix:@"/var/mobile/Library/pkgmirror"])
                continue;
            
            struct stat st={0};
            if(lstat(enumURL.path.fileSystemRepresentation, &st)==0)
            {
                if((st.st_mode&S_IFDIR)==0) continue;
                
//                SYSLOG("fixMobileDirectory %d:%d %@", st.st_uid, st.st_gid, enumURL); usleep(1000*10);
                if(st.st_uid == 0) {
                    chown(enumURL.path.fileSystemRepresentation, 501, st.st_gid==0 ? 501 : st.st_gid);
                }
            }
        }
    }
}

#include <mach-o/loader.h>
NSString* getMachoInstallName(NSString* path)
{
    int fd = open(path.fileSystemRepresentation, O_RDONLY);
    if(fd < 0) return nil;

    NSString* installname = nil;
    
    do {
        if(lseek(fd, 0, SEEK_SET) != 0) break;
        
        struct mach_header_64 header={0};
        if(read(fd, &header, sizeof(header)) != sizeof(header))break;
        
        //there is no universal macho on Bootstrap
        if(header.magic!=MH_MAGIC_64 || header.cputype!= CPU_TYPE_ARM64) break;
        
        struct load_command* lc = malloc(header.sizeofcmds);
        if(!lc) break;
        
        if(read(fd, lc, header.sizeofcmds) != header.sizeofcmds)break;
        
        for (uint32_t i = 0; i < header.ncmds; i++) {
            if (lc->cmd == LC_ID_DYLIB)
            {
                struct dylib_command* id_dylib = (struct dylib_command*)lc;
                const char* name = (char*)((uint64_t)id_dylib + id_dylib->dylib.name.offset);
                installname = @(name);
            }
            lc = (struct load_command *) ((char *)lc + lc->cmdsize);
        }
        
    } while(0);
    
    close(fd);
    
    return installname;
}

void fixBadPatchFiles()
{
    NSString* dirpath = jbroot(@"/");
    for(NSString* path in [[NSFileManager defaultManager] enumeratorAtPath:dirpath]) {

        if(![path.pathExtension isEqualToString:@"roothidepatch"]) {
            continue;
        }
        
        NSString* fullpath = [dirpath stringByAppendingPathComponent:path];
        
        struct stat symst;
        if(lstat(fullpath.fileSystemRepresentation, &symst) !=0)
        {
            SYSLOG("scanBadPatchFiles: lstat: %@: %s", fullpath, strerror(errno));
            continue;
        }

        if(S_ISLNK(symst.st_mode))
        {
            SYSLOG("scanBadPatchFiles: symlink: %@", fullpath);
            continue;
        }
        
        STRAPLOG("fixBadPatchFiles: %@", path);
        
        NSString* installname = getMachoInstallName(fullpath);
        
        if([installname.stringByDeletingLastPathComponent isEqualToString:@"@loader_path/.jbroot/usr/lib/DynamicPatches"])
        {
            ASSERT(unlink(fullpath.fileSystemRepresentation) == 0);
            
            NSString* sympath = jbroot([@"/usr/lib/DynamicPatches" stringByAppendingPathComponent:installname.lastPathComponent]);
            ASSERT(symlink(sympath.fileSystemRepresentation, fullpath.fileSystemRepresentation) == 0);
        }
    }
}

void removeUnexpectedPreferences()
{
    BOOL reload = NO;
    NSArray* files = @[@".GlobalPreferences.plist", @"kCFPreferencesAnyApplication.plist"];
    for(NSString* item in files) {
        NSString* path = [jbroot(@"/var/mobile/Library/Preferences") stringByAppendingPathComponent:item];
        if([NSFileManager.defaultManager fileExistsAtPath:path]) {
            [NSFileManager.defaultManager removeItemAtPath:path error:nil];
            reload = YES;
        }
    }
    if(reload) {
        killAllForExecutable("/usr/sbin/cfprefsd");
    }
}

int bootstrap()
{
    ASSERT(getuid()==0);
    
    STRAPLOG("bootstrap...");
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    struct stat st;
    if(lstat("/var/jb", &st)==0) {
        //remove /var/jb to avoid incorrect library loading via @rpath
        ASSERT([fm removeItemAtPath:@"/var/jb" error:nil]);
    }
    
    NSString* dirpath = @"/var/containers/Bundle/Application/";
    NSArray *subItems = [fm contentsOfDirectoryAtPath:dirpath error:nil];
    for (NSString *subItem in subItems)
    {
        if (!is_jbroot_name(subItem.UTF8String)) continue;
        
        NSString* jbroot_path = [dirpath stringByAppendingPathComponent:subItem];
        
        if([fm fileExistsAtPath:[jbroot_path stringByAppendingPathComponent:@"/.bootstrapped"]]
           || [fm fileExistsAtPath:[jbroot_path stringByAppendingPathComponent:@"/.thebootstrapped"]]) {
            continue;
        }
        
        STRAPLOG("remove unknown/unfinished jbroot %@", subItem);

        NSString* jbroot_secondary = [NSString stringWithFormat:@"/var/mobile/Containers/Shared/AppGroup/%@", subItem];
        if([fm fileExistsAtPath:jbroot_secondary]) {
            ASSERT([fm removeItemAtPath:jbroot_secondary error:nil]);
        }
        
        ASSERT([fm removeItemAtPath:jbroot_path error:nil]);
    }
    
    NSString* jbroot_path = find_jbroot(YES);
    
    if(!jbroot_path) {
        STRAPLOG("device is not strapped...");
        
        jbroot_path = [NSString stringWithFormat:@"/var/containers/Bundle/Application/.jbroot-%016llX", jbrand_new()];
        
        STRAPLOG("bootstrap @ %@", jbroot_path);
        
        ASSERT(InstallBootstrap(jbroot_path) == 0);
        
    } else {
        STRAPLOG("device is strapped: %@", jbroot_path);
        
        ASSERT([fm fileExistsAtPath:jbroot(@"/.bootstrapped")] || [fm fileExistsAtPath:jbroot(@"/.thebootstrapped")]);
        
        if([fm fileExistsAtPath:jbroot(@"/.bootstrapped")]) //beta version to public version
            ASSERT([fm moveItemAtPath:jbroot(@"/.bootstrapped") toPath:jbroot(@"/.thebootstrapped") error:nil]);
        
        STRAPLOG("Status: Rerandomize jbroot");
        
        ASSERT(ReRandomizeBootstrap() == 0);
        
        removeUnexpectedPreferences();
        fixMobileDirectories();
        fixBadPatchFiles();
    }
    
    ASSERT(roothide_config_set_blacklist_enable(false)==0);
    
    STRAPLOG("Status: Rebuilding Apps");
    
    NSString* log=nil;
    NSString* err=nil;
    if(spawn_bootstrap_binary((char*[]){"/bin/sh", "/basebin/rebuildApps.sh", NULL}, &log, &err) != 0) {
        STRAPLOG("%@\nERR:%@", log, err);
        ABORT();
    }
    
    //Remove the shits triggered by uicache
    [NSFileManager.defaultManager removeItemAtPath:@"/var/mobile/Library/SplashBoard/Snapshots/xyz.willy.Zebra" error:nil];
    [NSFileManager.defaultManager removeItemAtPath:@"/var/mobile/Library/SplashBoard/Snapshots/com.roothide.manager" error:nil];
    [NSFileManager.defaultManager removeItemAtPath:@"/var/mobile/Library/SplashBoard/Snapshots/org.coolstar.SileoStore" error:nil];

    NSDictionary* bootinfo = @{@"bootsession":getBootSession(), @"bootversion":NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]};
    ASSERT([bootinfo writeToFile:jbroot(@"/basebin/.bootinfo.plist") atomically:YES]);
    
    STRAPLOG("Status: Bootstrap Successful");
    
    return 0;
}

int unbootstrap()
{
    STRAPLOG("unbootstrap...");
    
    //try
    spawn_root(jbroot(@"/basebin/bsctl"), @[@"stop"], nil, nil);
    
    //jbroot unavailable now
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* dirpath = @"/var/containers/Bundle/Application/";
    for(NSString* item in [fm directoryContentsAtPath:dirpath])
    {
        if([fm fileExistsAtPath:
             [dirpath stringByAppendingPathComponent:@".installed_dopamine"]])
            continue;
        
        if(is_jbroot_name(item.UTF8String)) {
            STRAPLOG("remove %@ @ %@", item, dirpath);
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
            STRAPLOG("remove %@ @ %@", item, dirpath);
            ASSERT([fm removeItemAtPath:[dirpath stringByAppendingPathComponent:item] error:nil]);
        }
    }

    SYSLOG("bootstrap uninstalled!");
    
    [LSApplicationWorkspace.defaultWorkspace _LSPrivateRebuildApplicationDatabasesForSystemApps:YES internal:YES user:YES];
    
    AppInfo* tsapp = [AppInfo appWithBundleIdentifier:@"com.opa334.TrollStore"];
    if(tsapp) {
        NSString* log=nil;
        NSString* err=nil;
        if(spawn_root([tsapp.bundleURL.path stringByAppendingPathComponent:@"trollstorehelper"], @[@"refresh"], &log, &err) != 0) {
            STRAPLOG("refresh tsapps failed:%@\nERR:%@", log, err);
        }
    } else {
        STRAPLOG("trollstore not found!");
    }
    
    killAllForExecutable("/usr/libexec/backboardd");
    
    return 0;
}


bool isBootstrapInstalled()
{
    if(!find_jbroot(YES))
        return NO;

    if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.bootstrapped")]
       && ![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.thebootstrapped")])
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

bool checkBootstrapVersion()
{
    if(!isBootstrapInstalled()) return false;
    
    NSDictionary* bootinfo = [NSDictionary dictionaryWithContentsOfFile:jbroot(@"/basebin/.bootinfo.plist")];
    if(!bootinfo) return false;
    
    NSString* bootversion = bootinfo[@"bootversion"];
    if(!bootversion) return false;
    
    return [bootversion isEqualToString:NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]];
}
