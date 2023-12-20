#import <Foundation/Foundation.h>
#include "AppList.h"
#include "common.h"

extern void rebuildSignature(NSString *directoryPath);

int rebuildApp(NSString *bundlePath)
{
    int machoCount=0, libCount=0;
    
    NSString *resolvedPath = [[bundlePath stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath isDirectory:YES] includingPropertiesForKeys:@[NSURLIsSymbolicLinkKey] options:0 errorHandler:nil];
    
    NSString* decryptor = jbroot(@"/basebin/bootstrapd");
    NSString* fastSignPath = jbroot(@"/basebin/fastPathSign");
    
    for (NSURL *enumURL in directoryEnumerator) {
        @autoreleasepool {
            NSNumber *isSymlink;
            [enumURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];
            if (isSymlink && ![isSymlink boolValue])
            {
                if([enumURL.path.lastPathComponent.pathExtension isEqualToString:@"machobackup"]) {
                    continue;
                }

                FILE *fp = fopen(enumURL.fileSystemRepresentation, "rb");
                ASSERT(fp != NULL);
                
                bool ismacho=false, islib=false;
                machoGetInfo(fp, &ismacho, &islib);
                
                fclose(fp);
                
                if(ismacho) {
                    
                    SYSLOG("rebuild %@", enumURL.path);
                    
                    machoCount++;
                    
                    if(!islib) {
                        libCount++;
                    }
                    
                    ASSERT(spawnRoot(decryptor, @[@"unrestrict", enumURL.path], nil, nil) == 0);
                    ASSERT(spawnRoot(fastSignPath, @[enumURL.path], nil, nil) == 0);
                }
                

            }
        }
    }
    
    SYSLOG("rebuild finished! machoCount=%d, libCount=%d", machoCount, libCount);
    
    return 0;
}

int backupApp(NSString* bundlePath)
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    if([fm fileExistsAtPath:[bundlePath stringByAppendingPathComponent:@"Info.plist.infobackup"]]) {
        ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingPathComponent:@"Info.plist.infobackup"] error:nil]);
    }
    ASSERT([fm copyItemAtPath:[bundlePath stringByAppendingPathComponent:@"Info.plist"]
                       toPath:[bundlePath stringByAppendingPathComponent:@"Info.plist.infobackup"] error:nil]);
    
    NSString *resolvedPath = [[bundlePath stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath isDirectory:YES] includingPropertiesForKeys:@[NSURLIsSymbolicLinkKey] options:0 errorHandler:nil];

    for (NSURL *enumURL in directoryEnumerator) {
        @autoreleasepool {
            NSNumber *isSymlink;
            [enumURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];
            if (isSymlink && ![isSymlink boolValue])
            {
                if([enumURL.path.lastPathComponent.pathExtension isEqualToString:@"machobackup"]) {
                    continue;
                }
                
                FILE *fp = fopen(enumURL.fileSystemRepresentation, "rb");
                ASSERT(fp != NULL);
                
                bool ismacho=false, islib=false;
                machoGetInfo(fp, &ismacho, &islib);
                
                fclose(fp);
                
                if(ismacho) {

                    NSString* backupfile = [enumURL.path stringByAppendingString:@".machobackup"];
                    if([fm fileExistsAtPath:backupfile]) {
                        ASSERT([fm removeItemAtPath:backupfile error:nil]);
                    }
                    
                    NSError* err=nil;
                    ASSERT([fm copyItemAtPath:enumURL.path toPath:backupfile error:&err]);
                }
            }
        }
    }
    
    return 0;
}

int restoreApp(NSString* bundlePath)
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingPathComponent:@"Info.plist"] error:nil]);
    ASSERT([fm moveItemAtPath:[bundlePath stringByAppendingPathComponent:@"Info.plist.infobackup"]
                       toPath:[bundlePath stringByAppendingPathComponent:@"Info.plist"] error:nil]);
    
    NSString *resolvedPath = [[bundlePath stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath isDirectory:YES] includingPropertiesForKeys:@[NSURLIsSymbolicLinkKey] options:0 errorHandler:nil];

    for (NSURL *enumURL in directoryEnumerator) {
        @autoreleasepool {
            NSNumber *isSymlink;
            [enumURL getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];
            if (isSymlink && ![isSymlink boolValue]) {
                
                if([fm fileExistsAtPath:[enumURL.path stringByAppendingString:@".machobackup"]]) {
                    ASSERT([fm removeItemAtPath:enumURL.path error:nil]);
                    ASSERT([fm moveItemAtPath:[enumURL.path stringByAppendingString:@".machobackup"] toPath:enumURL.path error:nil]);
                }
            }
        }
    }
    
    return 0;
}


@interface MCMContainer : NSObject
- (NSURL *)url;
+ (instancetype)containerWithIdentifier:(NSString *)identifier
                      createIfNecessary:(BOOL)createIfNecessary
                                existed:(BOOL *)existed
                                  error:(NSError **)error;
@end

@interface MCMAppDataContainer : MCMContainer
@end

/*
/Library/Caches/com.apple.dyld
/Library/Saved Application State
/Library/Preferences/*
/Library/HTTPStorages
/Library/Cookies
 */
BOOL checkAppAvailable(NSString* bundleIdentifier)
{
    MCMAppDataContainer* container = [MCMAppDataContainer containerWithIdentifier:bundleIdentifier
                                                                createIfNecessary:NO /* !!! */
                                                                          existed:nil
                                                                            error:nil];
    SYSLOG("container for %@: %@", bundleIdentifier, container);
    
    if(!container) return NO;
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    if([fm fileExistsAtPath:[container.url.path stringByAppendingString:@"/Library/Caches/com.apple.dyld"]])
        return YES;
    if([fm fileExistsAtPath:[container.url.path stringByAppendingString:@"/Library/Saved Application State"]])
        return YES;
    if([fm fileExistsAtPath:[container.url.path stringByAppendingString:@"/Library/HTTPStorages"]])
        return YES;
    if([fm fileExistsAtPath:[container.url.path stringByAppendingString:@"/Library/Cookies"]])
        return YES;
    
    if([fm directoryContentsAtPath:[container.url.path stringByAppendingString:@"/Library/Preferences"]].count > 0)
        return YES;
    
    return NO;
}

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openApplicationWithBundleID:(NSString *)arg1 ;
@end

int enableForApp(NSString* bundlePath)
{
    SYSLOG("enableForApp %@", bundlePath);
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSDictionary* appInfo = [NSDictionary dictionaryWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"Info.plist"]];
    if(!appInfo) return -1;
    
    if([bundlePath hasPrefix:@"/Applications/"])
    {
        if([fm fileExistsAtPath:jbroot(bundlePath)])
            ASSERT([fm removeItemAtPath:jbroot(bundlePath) error:nil]);
        
        ASSERT([fm copyItemAtPath:bundlePath toPath:jbroot(bundlePath) error:nil]);
        
        rebuildSignature(jbroot(bundlePath));
        
        ASSERT([fm createSymbolicLinkAtPath:[jbroot(bundlePath) stringByAppendingString:@"/.jbroot"] withDestinationPath:jbroot(@"/") error:nil]);
        
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-p", bundlePath.UTF8String, NULL}, nil, nil) == 0);
    }
    else if([appInfo[@"CFBundleIdentifier"] hasPrefix:@"com.apple."]
            || [NSFileManager.defaultManager fileExistsAtPath:[bundlePath stringByAppendingString:@"/../_TrollStore"]])
    {
        rebuildSignature(bundlePath);
        
        ASSERT([fm createSymbolicLinkAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] withDestinationPath:jbroot(@"/") error:nil]);

        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-s","-p", [@"/rootfs/" stringByAppendingString:bundlePath].UTF8String, NULL}, nil, nil) == 0);
    }
    else
    {
        //should be an appstored app
        BOOL launched=NO;
        while(!checkAppAvailable(appInfo[@"CFBundleIdentifier"])) {
            
            if(launched) {
                SYSLOG("%@ has never been actived!", appInfo[@"CFBundleIdentifier"]);
                return -1;
            }
            
            [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:appInfo[@"CFBundleIdentifier"]];
            launched = YES;
            sleep(2);
            [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:NSBundle.mainBundle.bundleIdentifier];
        }
        
        ASSERT(backupApp(bundlePath) == 0);
        
        ASSERT(rebuildApp(bundlePath) == 0);
        
        ASSERT([fm createSymbolicLinkAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] withDestinationPath:jbroot(@"/") error:nil]);
        
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-s","-p", [@"/rootfs/" stringByAppendingString:bundlePath].UTF8String, NULL}, nil, nil) == 0);
    }
    
    return 0;
}

int disableForApp(NSString* bundlePath)
{
    SYSLOG("disalbeForApp %@", bundlePath);
    
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSDictionary* appInfo = [NSDictionary dictionaryWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"Info.plist"]];
    if(!appInfo) return -1;
    
    if(![bundlePath hasPrefix:@"/Applications/"] && [bundlePath containsString:@"/Applications/"])
    {
        ASSERT([fm removeItemAtPath:bundlePath error:nil]);
        
        NSString* sysPath = [@"/rootfs/Applications/" stringByAppendingString:bundlePath.lastPathComponent];
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-p", sysPath.UTF8String, NULL}, nil, nil) == 0);
    }
    else if([appInfo[@"CFBundleIdentifier"] hasPrefix:@"com.apple."]
            || [NSFileManager.defaultManager fileExistsAtPath:[bundlePath stringByAppendingString:@"/../_TrollStore"]])
    {
        ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] error:nil]);
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-s","-p", [@"/rootfs/" stringByAppendingString:bundlePath].UTF8String, NULL}, nil, nil) == 0);
    }
    else
    {
        //should be an appstored app
        
        ASSERT(restoreApp(bundlePath) == 0);
        
        ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] error:nil]);
        
        //unregister or respring to keep app's icon on home screen
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-u", [@"/rootfs/" stringByAppendingString:bundlePath].UTF8String, NULL}, nil, nil) == 0);
        
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-p", [@"/rootfs/" stringByAppendingString:bundlePath].UTF8String, NULL}, nil, nil) == 0);
    }
    
    return 0;
}
