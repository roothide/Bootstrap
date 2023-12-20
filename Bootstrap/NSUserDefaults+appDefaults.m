#import "NSUserDefaults+appDefaults.h"
#include "common.h"

@interface MCMContainer : NSObject
- (NSURL *)url;
+ (instancetype)containerWithIdentifier:(NSString *)identifier
                      createIfNecessary:(BOOL)createIfNecessary
                                existed:(BOOL *)existed
                                  error:(NSError **)error;
@end

@interface MCMAppDataContainer : MCMContainer
@end

@implementation NSUserDefaults (appDefaults)

static NSUserDefaults* _appDefaults=nil;

//+(NSUserDefaults*)appDefaults {
//    static dispatch_once_t once;
//    dispatch_once (&once, ^{
//        /* initWithSuiteName does not accept AppBundleIdentifier as SuiteName, and preferences cannot be shared between processes with different uid. */
//        _appDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.roothide.Bootstrap.shared"];
//        [_appDefaults registerDefaults:@{}];
//    });
//    return _appDefaults;
//}

+(NSUserDefaults*)appDefaults {
    static dispatch_once_t once;
    dispatch_once (&once, ^{
        MCMAppDataContainer* container = [MCMAppDataContainer containerWithIdentifier:NSBundle.mainBundle.bundleIdentifier createIfNecessary:YES existed:nil error:nil];
        NSString* path = [NSString stringWithFormat:@"%@/Library/Preferences/%@.plist", container.url.path, NSBundle.mainBundle.bundleIdentifier];
        SYSLOG("appDefaults=%@", path);
        _appDefaults = [[NSUserDefaults alloc] initWithSuiteName:path];
        [_appDefaults registerDefaults:@{}];
    });
    return _appDefaults;
}


@end
