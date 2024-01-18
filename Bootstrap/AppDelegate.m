#import "AppDelegate.h"
#include "common.h"

#include <MBProgressHUD/MBProgressHUD.h>

@interface AppDelegate ()
@end

@implementation AppDelegate

+ (void)addLogText:(NSString*)text
{
    [NSNotificationCenter.defaultCenter postNotificationName:@"LogMsgNotification" object:text];
}

MBProgressHUD *switchHud=nil;

+(void)showHudMsg:(NSString*)msg
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switchHud = [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
        [switchHud showAnimated:YES];
        switchHud.label.text = msg;
    });
}

+(void)showHudMsg:(NSString*)msg detail:(NSString*)info
{
    dispatch_async(dispatch_get_main_queue(), ^{
        switchHud = [MBProgressHUD showHUDAddedTo:UIApplication.sharedApplication.keyWindow animated:YES];
        [switchHud showAnimated:YES];
        switchHud.label.text = msg;
        switchHud.detailsLabel.text = info;
    });
}

+(void)dismissHud {
    dispatch_async(dispatch_get_main_queue(), ^{
        [switchHud hideAnimated:YES];
    });
}

+ (void)showAlert:(UIAlertController*)alert {
    
    static dispatch_queue_t alertQueue = nil;
    
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken, ^{
        alertQueue = dispatch_queue_create("alertQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_async(alertQueue, ^{
        
        __block UIViewController* availableVC=nil;
        while(!availableVC) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController* vc = UIApplication.sharedApplication.keyWindow.rootViewController;
                while(vc.presentedViewController){
                    vc = vc.presentedViewController;
                    if(vc.isBeingDismissed) return;
                }
                availableVC = vc;
            });
            if(!availableVC) usleep(1000*100);
        }
        
        __block BOOL presented = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [availableVC presentViewController:alert animated:YES completion:^{ presented=YES; }];
        });
        
        while(!presented) usleep(100*1000);
    });
}

+ (void)showMesage:(NSString*)msg title:(NSString*)title {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:nil]];
    [self showAlert:alert];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
