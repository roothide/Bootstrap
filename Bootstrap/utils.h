#ifndef utils_h
#define utils_h

#import <Foundation/Foundation.h>

extern const char** environ;

uint64_t jbrand();

uint64_t jbrand_new();

NSString* find_jbroot();

NSString* jbroot(NSString *path);

int is_jbroot_name(const char* name);

NSString* rootfsPrefix(NSString* path);

NSString* getBootSession();

int spawn(const char* path, const char** argv, const char** envp, void(^std_out)(char*,int), void(^std_err)(char*,int));

int spawnBootstrap(const char** argv, NSString** stdOut, NSString** stdErr);

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);

void machoGetInfo(FILE* candidateFile, bool *isMachoOut, bool *isLibraryOut);

BOOL isDefaultInstallationPath(NSString* _path);

void killAllForApp(const char* bundlePath);


@interface LSApplicationWorkspace : NSObject
+ (id)defaultWorkspace;
- (BOOL)openApplicationWithBundleID:(id)arg1;
- (BOOL)_LSPrivateRebuildApplicationDatabasesForSystemApps:(BOOL)arg1
                                                  internal:(BOOL)arg2
                                                      user:(BOOL)arg3;
@end

@interface LSPlugInKitProxy : NSObject
+(id)pluginKitProxyForIdentifier:(id)arg1 ;
- (NSString *)bundleIdentifier;
@property (nonatomic,readonly) NSURL *dataContainerURL;
@end

#endif /* utils_h */
