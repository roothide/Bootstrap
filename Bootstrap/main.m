#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include "NSUserDefaults+appDefaults.h"
#include "common.h"

int main(int argc, char * argv[]) {

    if(argc >= 2)
    {
        @try {
            SYSLOG("Bootstrap cmd %s", argv[1]);
            ASSERT(getuid() == 0);
            
            if(strcmp(argv[1], "bootstrap")==0) {
                int bootstrap();
                exit(bootstrap());
            } else if(strcmp(argv[1], "unbootstrap")==0) {
                int unbootstrap();
                exit(unbootstrap());
            } else if(strcmp(argv[1], "enableapp")==0) {
                int enableForApp(NSString* bundlePath);
                exit(enableForApp(@(argv[2])));
            } else if(strcmp(argv[1], "disableapp")==0) {
                int disableForApp(NSString* bundlePath);
                exit(disableForApp(@(argv[2])));
            } else if(strcmp(argv[1], "rebuildiconcache")==0) {
                int rebuildIconCache();
                exit(rebuildIconCache());
            } else if(strcmp(argv[1], "reboot")==0) {
                sync();
                sleep(1);
                reboot(0);
                sleep(5);
                exit(-1);
            } else if(strcmp(argv[1], "testprefs")==0) {
                SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
                [NSUserDefaults.appDefaults setValue:@"CA" forKey:@"locale"];
                [NSUserDefaults.appDefaults synchronize];
                SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
                exit(0);
            }
            
            SYSLOG("unknown cmd: %s", argv[1]);
            ABORT();
        }
        @catch (NSException *exception)
        {
            STRAPLOG("***exception: %@", exception);
            exit(-1);
        }
    }

    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
