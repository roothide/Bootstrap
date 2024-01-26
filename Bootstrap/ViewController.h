#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@end

void initFromSwiftUI();
void respringAction();
void rebuildappsAction();
void reinstallPackageManager();
void rebuildIconCacheAction();
void tweaEnableAction(BOOL enable);
BOOL opensshAction(BOOL enable);
void bootstrapAction();
void unbootstrapAction();
BOOL updateOpensshStatus(BOOL notify);
void fixNotification();
