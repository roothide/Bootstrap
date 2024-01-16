#ifndef APPDELEGATE_H
#define APPDELEGATE_H

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

+(void)showHudMsg:(NSString*)msg;
+(void)showHudMsg:(NSString*)msg detail:(NSString*)info;
+(void)dismissHud;

+ (void)showAlert:(UIAlertController*)alert;
+ (void)showMesage:(NSString*)msg title:(NSString*)title;

+ (void)addLogText:(NSString*)text;

@end

#endif //APPDELEGATE_H
