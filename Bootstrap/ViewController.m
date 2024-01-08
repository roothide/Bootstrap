#import "ViewController.h"
#include "NSUserDefaults+appDefaults.h"
#include "common.h"
#include "AppDelegate.h"
#include "AppViewController.h"
#include "bootstrap.h"
#include "credits.h"
#import <sys/sysctl.h>
#include <sys/utsname.h>
#import "Bootstrap-Swift.h"

#include <Security/SecKey.h>
#include <Security/Security.h>
typedef struct CF_BRIDGED_TYPE(id) __SecCode const* SecStaticCodeRef; /* code on disk */
typedef enum { kSecCSDefaultFlags=0, kSecCSSigningInformation = 1 << 1 } SecCSFlags;
OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef* CF_RETURNS_RETAINED staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef* __nonnull CF_RETURNS_RETAINED information);


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UIButton *bootstraBtn;
@property (weak, nonatomic) IBOutlet UIButton *unbootstrapBtn;
@property (weak, nonatomic) IBOutlet UISwitch *opensshState;
@property (weak, nonatomic) IBOutlet UIButton *appEnablerBtn;
@property (weak, nonatomic) IBOutlet UIButton *respringBtn;
@property (weak, nonatomic) IBOutlet UIButton *uninstallBtn;
@property (weak, nonatomic) IBOutlet UIButton *rebuildappsBtn;
@property (weak, nonatomic) IBOutlet UIButton *rebuildIconCacheBtn;
@property (weak, nonatomic) IBOutlet UIButton *reinstallPackageManagerBtn;
@property (weak, nonatomic) IBOutlet UILabel *opensshLabel;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UIViewController *vc = [SwiftUIViewWrapper createSwiftUIView];
    
    UIView *swiftuiView = vc.view;
    swiftuiView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addChildViewController:vc];
    [self.view addSubview:swiftuiView];
    
    [NSLayoutConstraint activateConstraints:@[
        [swiftuiView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [swiftuiView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [swiftuiView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [swiftuiView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    
    [vc didMoveToParentViewController:self];
    
    [AppDelegate addLogText:[NSString stringWithFormat:@"ios-version: %@",UIDevice.currentDevice.systemVersion]];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    [AppDelegate addLogText:[NSString stringWithFormat:@"device-model: %s",systemInfo.machine]];
    
    [AppDelegate addLogText:[NSString stringWithFormat:@"app-version: %@/%@",NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"],NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]]];
    
    [AppDelegate addLogText:[NSString stringWithFormat:@"boot-session: %@",getBootSession()]];
    
    [AppDelegate addLogText: isBootstrapInstalled()? @"bootstrap installed":@"bootstrap not installed"];
    [AppDelegate addLogText: isSystemBootstrapped()? @"system bootstrapped":@"system not bootstrapped"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        usleep(1000*500);
        [AppDelegate addLogText:@"\n:::Credits:::\n"];
        usleep(1000*500);
        for(NSString* name in CREDITS) {
            usleep(1000*50);
            [AppDelegate addLogText:[NSString stringWithFormat:@"%@ - %@\n",name,CREDITS[name]]];
        }
        sleep(1);
        [AppDelegate addLogText:Localized(@"\nthanks to these guys, we couldn't have completed this project without their help!")];
        
    });
    
    SYSLOG("locale=%@", NSLocale.currentLocale.countryCode);
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
    [NSUserDefaults.appDefaults setValue:NSLocale.currentLocale.countryCode forKey:@"locale"];
    [NSUserDefaults.appDefaults synchronize];
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
    
    if(isSystemBootstrapped())
    {
        if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"check"], nil, nil) != 0)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Server Not Running") message:Localized(@"for unknown reasons the bootstrap server is not running, the only thing we can do is to restart it now.") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Restart Server") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                
                NSString* log=nil;
                NSString* err=nil;
                if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"daemon",@"-f"], &log, &err)==0) {
                    [AppDelegate addLogText:Localized(@"bootstrap server restart successful")];
                } else {
                    [AppDelegate showMesage:[NSString stringWithFormat:@"%@\nERR:%@"] title:Localized(@"Error")];
                }
                
            }]];
            
            [AppDelegate showAlert:alert];
        } else {
            [AppDelegate addLogText:Localized(@"bootstrap server check successful")];
        }
    }
}

@end
