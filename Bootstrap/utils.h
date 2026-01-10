#ifndef utils_h
#define utils_h

#import <Foundation/Foundation.h>
#include "commlib.h"

uint64_t jbrand();

uint64_t jbrand_new();

NSString* find_jbroot(BOOL force);

int is_jbroot_name(const char* name);

const char* jbroot(const char* path);

NSString* __attribute__((overloadable)) jbroot(NSString *path);

NSString* rootfsPrefix(NSString* path);

NSString* getBootSession();

NSString* getTeamIDFromBinaryAtPath(NSString *binaryPath);

@interface _LSApplicationState : NSObject
- (BOOL)isValid;
@end

@interface LSBundleProxy : NSObject
-(BOOL)isContainerized;
- (NSURL *)bundleURL;
- (NSURL *)containerURL;
- (NSURL *)dataContainerURL;
- (NSString *)bundleExecutable;
- (NSString *)bundleIdentifier;
@end

@interface LSPlugInKitProxy : LSBundleProxy
+(id)pluginKitProxyForIdentifier:(id)arg1 ;
- (NSString *)bundleIdentifier;
@property (nonatomic,readonly) NSURL *dataContainerURL;
@end

@interface LSApplicationProxy : LSBundleProxy
+ (id)applicationProxyForIdentifier:(id)arg1;
- (id)localizedNameForContext:(id)arg1;
- (_LSApplicationState *)appState;
- (NSString *)vendorName;
- (NSString *)teamID;
- (NSString *)applicationType;
- (NSSet *)claimedURLSchemes;
- (BOOL)isDeletable;
- (NSDictionary*)environmentVariables;
@property (nonatomic,readonly) NSDictionary *groupContainerURLs;
@property (nonatomic,readonly) NSArray<LSPlugInKitProxy *> *plugInKitPlugins;
@end

@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (BOOL)unregisterApplication:(NSURL *)url;
- (BOOL)openApplicationWithBundleID:(id)arg1;
- (NSArray<LSApplicationProxy*>*)allApplications;
- (NSArray<LSApplicationProxy*>*)allInstalledApplications;
- (BOOL)_LSPrivateRebuildApplicationDatabasesForSystemApps:(BOOL)arg1
                                                  internal:(BOOL)arg2
                                                      user:(BOOL)arg3;
@end

#endif /* utils_h */
