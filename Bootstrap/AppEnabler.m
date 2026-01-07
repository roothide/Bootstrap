#import <Foundation/Foundation.h>
#include <sys/clonefile.h>
#include <sys/stat.h>
#include "AppInfo.h"
#include "common.h"

NSString * relativize(NSURL * to, NSURL * from, BOOL fromIsDir) {
    NSString * toString = [[to path] stringByStandardizingPath];
    NSMutableArray * toPieces = [NSMutableArray arrayWithArray:[toString pathComponents]];

    NSString * fromString = [[from path] stringByStandardizingPath];
    NSMutableArray * fromPieces = [NSMutableArray arrayWithArray:[fromString pathComponents]];

    NSMutableString * relPath = [NSMutableString string];

    NSString * toTrimmed = toString;
    NSString * toPiece = NULL;
    NSString * fromTrimmed = fromString;
    NSString * fromPiece = NULL;

    NSMutableArray * parents = [NSMutableArray array];
    NSMutableArray * pieces = [NSMutableArray array];

    if(toPieces.count >= fromPieces.count) {
        NSUInteger toCount = toPieces.count;
        while(toCount > fromPieces.count) {
            toPiece = [toTrimmed lastPathComponent];
            toTrimmed = [toTrimmed stringByDeletingLastPathComponent];
            [pieces insertObject:toPiece atIndex:0];
            toCount--;
        }

        while(![fromTrimmed isEqualToString:toTrimmed]) {
            toPiece = [toTrimmed lastPathComponent];
            toTrimmed = [toTrimmed stringByDeletingLastPathComponent];
            fromPiece = [fromTrimmed lastPathComponent];
            fromTrimmed = [fromTrimmed stringByDeletingLastPathComponent];
            if(![toPiece isEqualToString:fromPiece]) {
                if(![fromPiece isEqualToString:[fromPiece lastPathComponent]] || fromIsDir) {
                    [parents addObject:@".."];
                }
                [pieces insertObject:toPiece atIndex:0];
            }
        }

    } else {
        NSUInteger fromCount = fromPieces.count;

        while(fromCount > toPieces.count) {
            fromPiece = [fromTrimmed lastPathComponent];
            fromTrimmed = [fromTrimmed stringByDeletingLastPathComponent];
            if(![fromPiece isEqualToString:[fromString lastPathComponent]] || fromIsDir) {
                [parents addObject:@".."];
            }
            fromCount--;
        }

        while(![toTrimmed isEqualToString:fromTrimmed]) {
            toPiece = [toTrimmed lastPathComponent];
            toTrimmed = [toTrimmed stringByDeletingLastPathComponent];
            fromPiece = [fromTrimmed lastPathComponent];
            fromTrimmed = [fromTrimmed stringByDeletingLastPathComponent];
            [parents addObject:@".."];
            [pieces insertObject:toPiece atIndex:0];
        }

    }

    [relPath appendString:[parents componentsJoinedByString:@"/"]];
    if(parents.count > 0) [relPath appendString:@"/"];
    else [relPath appendString:@"./"];
    [relPath appendString:[pieces componentsJoinedByString:@"/"]];

    return relPath;
}

//if the app package is changed/upgraded, the directory structure may change and some paths may become invalid.
int restoreApp(NSString* bundlePath)
{
    SYSLOG("restoreApp=%@", bundlePath);
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* backup = [bundlePath stringByAppendingPathExtension:@"appbackup"];
    NSString* backupFlag = [bundlePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"];
    
    ASSERT([fm fileExistsAtPath:backup]);
    ASSERT([fm fileExistsAtPath:backupFlag]);
    NSString* backupver = [NSString stringWithContentsOfFile:backupFlag encoding:NSASCIIStringEncoding error:nil];
    if(backupver.intValue >= 1) {
        ASSERT([fm removeItemAtPath:bundlePath error:nil]);
        ASSERT([fm moveItemAtPath:backup toPath:bundlePath error:nil]);
        ASSERT([fm removeItemAtPath:[backup.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"] error:nil]);
        return 0;
    }
    
    struct stat st;
    if(lstat([bundlePath stringByAppendingString:@"/.jbroot"].fileSystemRepresentation, &st)==0)
        ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] error:nil]);
    if(lstat([bundlePath stringByAppendingString:@"/.prelib"].fileSystemRepresentation, &st)==0)
        ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.prelib"] error:nil]);
    if(lstat([bundlePath stringByAppendingString:@"/.preload"].fileSystemRepresentation, &st)==0)
        ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.preload"] error:nil]);
    if(lstat([bundlePath stringByAppendingString:@"/.rebuild"].fileSystemRepresentation, &st)==0)
        ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.rebuild"] error:nil]);
    
    NSString *resolvedPath = [[backup stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath isDirectory:YES] includingPropertiesForKeys:@[NSURLIsRegularFileKey] options:0 errorHandler:nil];

    int restoreFileCount=0;
    for (NSURL *enumURL in directoryEnumerator) { @autoreleasepool {
        NSNumber *isFile=nil;
        ASSERT([enumURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil] && isFile!=nil);
        if (![isFile boolValue]) continue;
        
        //bundlePath should be a real-path
        NSString* subPath = relativize(enumURL, [NSURL fileURLWithPath:backup], YES);
        NSString* restorePath = [bundlePath stringByAppendingPathComponent:subPath];
        
        SYSLOG("restore %@ => %@", enumURL.path, restorePath);
        
        if([fm fileExistsAtPath:restorePath])
            ASSERT([fm removeItemAtPath:restorePath error:nil]);
        
        NSError* err=nil;
        if(![fm moveItemAtPath:enumURL.path toPath:restorePath error:&err]) {
            SYSLOG("move failed %@", err);
            ABORT();
        }
        
        restoreFileCount++;
        
    } }
    
    ASSERT(restoreFileCount > 0);

    ASSERT([fm removeItemAtPath:backup error:nil]);
    ASSERT([fm removeItemAtPath:[backup.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"] error:nil]);
    
    return 0;
}

int backupApp(NSString* bundlePath)
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* backup = [bundlePath stringByAppendingPathExtension:@"appbackup"];
    
    if([fm fileExistsAtPath:backup]) {
        ASSERT(![fm fileExistsAtPath:[backup.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"]]);
        ASSERT([fm removeItemAtPath:backup error:nil]);
    }
    
    ASSERT(clonefile(bundlePath.fileSystemRepresentation, backup.fileSystemRepresentation, CLONE_ACL) == 0);

    ASSERT([@"1" writeToFile:[backup.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"] atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
    return 0;
}

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
        
        ASSERT([fm createSymbolicLinkAtPath:[jbroot(bundlePath) stringByAppendingString:@"/.jbroot"] withDestinationPath:jbroot(@"/") error:nil]);
        
        NSString* log=nil;
        NSString* err=nil;
        if(spawnBootstrap((char*[]){"/usr/bin/uicache","-p", bundlePath.UTF8String, NULL}, &log, &err) != 0) {
            STRAPLOG("%@\nERR:%@", log, err);
            AppInfo* app = [AppInfo appWithBundleIdentifier:appInfo[@"CFBundleIdentifier"]];
            if(app && [app.bundleURL.path hasPrefix:@"/Applications/"]) {
                ASSERT([fm removeItemAtPath:bundlePath error:nil]);
            }
            ABORT();
        }
    }
    else if([appInfo[@"CFBundleIdentifier"] hasPrefix:@"com.apple."] || hasTrollstoreMarker(bundlePath.fileSystemRepresentation))
    {
        ASSERT(backupApp(bundlePath) == 0);

        ASSERT([fm createSymbolicLinkAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] withDestinationPath:jbroot(@"/") error:nil]);
        
        NSString* log=nil;
        NSString* err=nil;
        if(spawnBootstrap((char*[]){"/usr/bin/uicache","-s","-p", rootfsPrefix(bundlePath).UTF8String, NULL}, &log, &err) != 0) {
            STRAPLOG("%@\nERR:%@", log, err);
            ABORT();
        }
    }
    else
    {
        ASSERT(backupApp(bundlePath) == 0);
        
        ASSERT([fm createSymbolicLinkAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] withDestinationPath:jbroot(@"/") error:nil]);
        
        NSString* log=nil;
        NSString* err=nil;
        if(spawnBootstrap((char*[]){"/usr/bin/uicache","-s","-p", rootfsPrefix(bundlePath).UTF8String, NULL}, &log, &err) != 0) {
            STRAPLOG("%@\nERR:%@", log, err);
            ABORT();
        }
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
        
        NSString* sysPath = [@"/Applications/" stringByAppendingString:bundlePath.lastPathComponent];
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-p", rootfsPrefix(sysPath).UTF8String, NULL}, nil, nil) == 0);
    }
    else if([appInfo[@"CFBundleIdentifier"] hasPrefix:@"com.apple."] || hasTrollstoreMarker(bundlePath.fileSystemRepresentation))
    {
        
        ASSERT(restoreApp(bundlePath) == 0);
        
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-s","-p", rootfsPrefix(bundlePath).UTF8String, NULL}, nil, nil) == 0);
    }
    else
    {
        //should be an appstored app
        
        BOOL encryptedApp = [NSFileManager.defaultManager fileExistsAtPath:[bundlePath stringByAppendingPathComponent:@"SC_Info"]];
        NSString* backupVersion = [NSString stringWithContentsOfFile:[bundlePath stringByAppendingString:@"/../.appbackup"] encoding:NSASCIIStringEncoding error:nil];
        
        ASSERT(restoreApp(bundlePath) == 0);
        
        if(encryptedApp && backupVersion.intValue>=1) return 0;
        
        //unregister or respring to keep app's icon on home screen
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-u", rootfsPrefix(bundlePath).UTF8String, NULL}, nil, nil) == 0);
        //come back
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-p", rootfsPrefix(bundlePath).UTF8String, NULL}, nil, nil) == 0);
    }
    
    return 0;
}
