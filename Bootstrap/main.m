#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#include "NSUserDefaults+appDefaults.h"
#include "common.h"

void CommLog(const char* format, ...)
{
    va_list ap;
    va_start(ap, format);
    char* logbuf = NULL;
    vasprintf(&logbuf, format, ap);
    SYSLOG("%s", logbuf);
    free(logbuf);
    va_end(ap);
}

int main(int argc, char * argv[]) {
    
    CommLogFunction = CommLog;

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
            } else if(strcmp(argv[1], "exploit")==0) {
                int exploitStart();
                exit(exploitStart());
            } else if(strcmp(argv[1], "enableapp")==0) {
                int enableForApp(NSString* bundlePath);
                exit(enableForApp(@(argv[2])));
            } else if(strcmp(argv[1], "disableapp")==0) {
                int disableForApp(NSString* bundlePath);
                exit(disableForApp(@(argv[2])));
            } else if(strcmp(argv[1], "rebuildiconcache")==0) {
                int rebuildIconCache();
                exit(rebuildIconCache());
            } else if(strcmp(argv[1], "hidebootstrapapp")==0) {
                int hideBootstrapApp(BOOL usreboot);
                exit(hideBootstrapApp(argc==3 && strcmp(argv[2],"usreboot")==0));
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
