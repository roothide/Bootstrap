#ifndef APPDELEGATE_H
#define APPDELEGATE_H

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

+(void)showHudMsg:(NSString*)msg;
+(void)dismissHud;

+ (void)showAlert:(UIAlertController*)alert;
+ (void)showMesage:(NSString*)msg title:(NSString*)title;

+ (void)addLogText:(NSString*)text;
+ (void)registerLogView:(UITextView*)view;

@end

#endif //APPDELEGATE_H
