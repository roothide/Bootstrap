#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include "AppList.h"
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

NSArray* appBackupFileNames = @[
    @"Info.plist",
    @"_CodeSignature",
    @"SC_Info",
];

//will skip empty dir
int backupApp(NSString* bundlePath)
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* backup = [bundlePath stringByAppendingPathExtension:@"appbackup"];
    
    if([fm fileExistsAtPath:backup]) {
        ASSERT(![fm fileExistsAtPath:[backup.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"]]);
        ASSERT([fm removeItemAtPath:backup error:nil]);
    }
    
    NSString *resolvedPath = [[bundlePath stringByResolvingSymlinksInPath] stringByStandardizingPath];
    NSDirectoryEnumerator<NSURL *> *directoryEnumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:resolvedPath isDirectory:YES] includingPropertiesForKeys:@[NSURLIsRegularFileKey] options:0 errorHandler:nil];

    int backupFileCount=0;
    for (NSURL *enumURL in directoryEnumerator) { @autoreleasepool {
        NSNumber *isFile=nil;
        ASSERT([enumURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil] && isFile!=nil);
        if (![isFile boolValue]) continue;
        
        FILE *fp = fopen(enumURL.fileSystemRepresentation, "rb");
        ASSERT(fp != NULL);
        
        bool ismacho=false, islib=false;
        machoGetInfo(fp, &ismacho, &islib);
        
        fclose(fp);
        
        //bundlePath should be a real-path
        NSString* subPath = relativize(enumURL, [NSURL fileURLWithPath:bundlePath], YES);
        NSString* backupPath = [backup stringByAppendingPathComponent:subPath];
        
        if(![fm fileExistsAtPath:backupPath.stringByDeletingLastPathComponent])
            ASSERT([fm createDirectoryAtPath:backupPath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:nil]);
        
        if(ismacho || [appBackupFileNames containsObject:enumURL.path.lastPathComponent])
        {
            NSError* err=nil;
            ASSERT([fm copyItemAtPath:enumURL.path toPath:backupPath error:&err]);
            SYSLOG("copied %@ => %@", enumURL.path, backupPath);
            
            backupFileCount++;
        }
        else {
            ASSERT(link(enumURL.path.UTF8String, backupPath.UTF8String)==0);
        }
        
    } }
    
    ASSERT(backupFileCount > 0);

    ASSERT([[NSString new] writeToFile:[backup.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"] atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    
    return 0;
}

//if the app package is changed/upgraded, the directory structure may change and some paths may become invalid.
int restoreApp(NSString* bundlePath)
{
    SYSLOG("restoreApp=%@", bundlePath);
    NSFileManager* fm = NSFileManager.defaultManager;
    
    NSString* backup = [bundlePath stringByAppendingPathExtension:@"appbackup"];
    
    ASSERT([fm fileExistsAtPath:backup]);
    ASSERT([fm fileExistsAtPath:[backup.stringByDeletingLastPathComponent stringByAppendingPathComponent:@".appbackup"]]);
    
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
            ABORT();
        }
    }
    else if([appInfo[@"CFBundleIdentifier"] hasPrefix:@"com.apple."]
            || [NSFileManager.defaultManager fileExistsAtPath:[bundlePath stringByAppendingString:@"/../_TrollStore"]])
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
    else if([appInfo[@"CFBundleIdentifier"] hasPrefix:@"com.apple."]
            || [NSFileManager.defaultManager fileExistsAtPath:[bundlePath stringByAppendingString:@"/../_TrollStore"]])
    {
        
        struct stat st;
        if(lstat([bundlePath stringByAppendingString:@"/.jbroot"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] error:nil]);
        if(lstat([bundlePath stringByAppendingString:@"/.prelib"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.prelib"] error:nil]);
        if(lstat([bundlePath stringByAppendingString:@"/.preload"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.preload"] error:nil]);
        if(lstat([bundlePath stringByAppendingString:@"/.rebuild"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.rebuild"] error:nil]);
        
        ASSERT(restoreApp(bundlePath) == 0);
        
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-s","-p", rootfsPrefix(bundlePath).UTF8String, NULL}, nil, nil) == 0);
    }
    else
    {
        //should be an appstored app
        
        struct stat st;
        if(lstat([bundlePath stringByAppendingString:@"/.jbroot"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.jbroot"] error:nil]);
        if(lstat([bundlePath stringByAppendingString:@"/.prelib"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.prelib"] error:nil]);
        if(lstat([bundlePath stringByAppendingString:@"/.preload"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.preload"] error:nil]);
        if(lstat([bundlePath stringByAppendingString:@"/.rebuild"].fileSystemRepresentation, &st)==0)
            ASSERT([fm removeItemAtPath:[bundlePath stringByAppendingString:@"/.rebuild"] error:nil]);
        
        ASSERT(restoreApp(bundlePath) == 0);
        
        //unregister or respring to keep app's icon on home screen
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-u", rootfsPrefix(bundlePath).UTF8String, NULL}, nil, nil) == 0);
        //come back
        ASSERT(spawnBootstrap((char*[]){"/usr/bin/uicache","-p", rootfsPrefix(bundlePath).UTF8String, NULL}, nil, nil) == 0);
    }
    
    return 0;
}
