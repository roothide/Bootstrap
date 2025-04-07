#ifndef utils_h
#define utils_h

#import <Foundation/Foundation.h>

extern const char** environ;

uint64_t jbrand();

uint64_t jbrand_new();

NSString* find_jbroot(BOOL force);

NSString* jbroot(NSString *path);

int is_jbroot_name(const char* name);

NSString* rootfsPrefix(NSString* path);

NSString* getBootSession();

int spawn(const char* path, const char** argv, const char** envp, void(^std_out)(char*,int), void(^std_err)(char*,int));

int spawnBootstrap(const char** argv, NSString** stdOut, NSString** stdErr);

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);

void machoGetInfo(FILE* candidateFile, bool *isMachoOut, bool *isLibraryOut);

BOOL isDefaultInstallationPath(NSString* _path);

void killAllForBundle(const char* bundlePath);
void killAllForExecutable(const char* path);

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
- (BOOL)openApplicationWithBundleID:(id)arg1;
- (NSArray<LSApplicationProxy*>*)allApplications;
- (NSArray<LSApplicationProxy*>*)allInstalledApplications;
- (BOOL)_LSPrivateRebuildApplicationDatabasesForSystemApps:(BOOL)arg1
                                                  internal:(BOOL)arg2
                                                      user:(BOOL)arg3;
@end

#endif /* utils_h */
