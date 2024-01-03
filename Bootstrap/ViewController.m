#import "ViewController.h"
#include "NSUserDefaults+appDefaults.h"
#include "common.h"
#include "AppDelegate.h"
#include "AppViewController.h"
#include "bootstrap.h"
#include "credits.h"
#import <sys/sysctl.h>
#include <sys/utsname.h>

#include <Security/SecKey.h>
#include <Security/Security.h>
typedef struct CF_BRIDGED_TYPE(id) __SecCode const* SecStaticCodeRef; /* code on disk */
typedef enum { kSecCSDefaultFlags=0, kSecCSSigningInformation = 1 << 1 } SecCSFlags;
OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef* CF_RETURNS_RETAINED staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef* __nonnull CF_RETURNS_RETAINED information);


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UIButton *bootstraBtn;
@property (weak, nonatomic) IBOutlet UISwitch *opensshState;
@property (weak, nonatomic) IBOutlet UIButton *appEnablerBtn;
@property (weak, nonatomic) IBOutlet UIButton *respringBtn;
@property (weak, nonatomic) IBOutlet UIButton *uninstallBtn;
@property (weak, nonatomic) IBOutlet UIButton *rebuildappsBtn;

@end

@implementation ViewController

- (BOOL)checkTSVersion {
    
    CFURLRef binaryURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)NSBundle.mainBundle.executablePath, kCFURLPOSIXPathStyle, false);
    if(binaryURL == NULL) return NO;
    
    SecStaticCodeRef codeRef = NULL;
    OSStatus result = SecStaticCodeCreateWithPathAndAttributes(binaryURL, kSecCSDefaultFlags, NULL, &codeRef);
    if(result != errSecSuccess) return NO;
        
    CFDictionaryRef signingInfo = NULL;
     result = SecCodeCopySigningInformation(codeRef, kSecCSSigningInformation, &signingInfo);
    if(result != errSecSuccess) return NO;
        
    NSString* teamID = (NSString*)CFDictionaryGetValue(signingInfo, CFSTR("teamid"));
    SYSLOG("teamID in trollstore: %@", teamID);
    
    return [teamID isEqualToString:@"T8ALTGMVXN"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.logView.text = nil;
    self.logView.textContainerInset = UIEdgeInsetsMake(12, 8, 8, 8);

    [AppDelegate registerLogView:self.logView];
    
    if (isSystemBootstrapped())
    {
        self.bootstraBtn.enabled = NO;
        [self.bootstraBtn setTitle:NSLocalizedString(@"Bootstrapped", nil) forState:UIControlStateDisabled];

        self.respringBtn.enabled = YES;
        self.appEnablerBtn.enabled = YES;
        self.rebuildappsBtn.enabled = YES;
        self.uninstallBtn.enabled = YES;

        self.bootstraBtn.hidden = YES;
        self.appEnablerBtn.hidden = NO;
        self.uninstallBtn.hidden = YES;
    }
    else if (isBootstrapInstalled())
    {
        self.bootstraBtn.enabled = YES;
        [self.bootstraBtn setTitle:NSLocalizedString(@"Bootstrap", nil) forState:UIControlStateNormal];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.rebuildappsBtn.enabled = NO;
        self.uninstallBtn.enabled = YES;

        self.bootstraBtn.hidden = NO;
        self.appEnablerBtn.hidden = YES;
        self.uninstallBtn.hidden = NO;
    }
    else if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 15)
    {
        self.bootstraBtn.enabled = YES;
        [self.bootstraBtn setTitle:NSLocalizedString(@"Install", nil) forState:UIControlStateNormal];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.rebuildappsBtn.enabled = NO;
        self.uninstallBtn.enabled = NO;

        self.bootstraBtn.hidden = NO;
        self.appEnablerBtn.hidden = YES;
        self.uninstallBtn.hidden = YES;
    } else {
        self.bootstraBtn.enabled = NO;
        [self.bootstraBtn setTitle:NSLocalizedString(@"Unsupported", nil) forState:UIControlStateDisabled];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.rebuildappsBtn.enabled = NO;
        self.uninstallBtn.enabled = NO;

        self.bootstraBtn.hidden = NO;
        self.appEnablerBtn.hidden = YES;
        self.uninstallBtn.hidden = YES;
        
        [AppDelegate showMesage:NSLocalizedString(@"The current iOS version is not supported yet, we may add support in a future version.", nil) title:NSLocalizedString(@"Unsupported", nil)];
    }
    

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
        [AppDelegate addLogText:NSLocalizedString(@"\nThanks to these guys, we couldn't have completed this project without their help!", nil)];

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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Server Not Running", nil) message:NSLocalizedString(@"For unknown reasons the bootstrap server is not running, the only thing we can do is to restart it now.", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Restart Server", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){

                NSString* log=nil;
                NSString* err=nil;
                if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"daemon",@"-f"], &log, &err)==0) {
                    [AppDelegate addLogText:@"bootstrap server restart successful"];
                    [self updateOpensshStatus];
                } else {
                    [AppDelegate showMesage:[NSString stringWithFormat:@"%@\nERR:%@", log, err] title:NSLocalizedString(@"Error", nil)];
                }
                
            }]];
            
            [AppDelegate showAlert:alert];
        } else {
            [AppDelegate addLogText:@"bootstrap server check successful"];
            [self updateOpensshStatus];
        }
    }
}

-(void) updateOpensshStatus {
    dispatch_async(dispatch_get_main_queue(), ^{
        if(isSystemBootstrapped()) {
            self.opensshState.on = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",@"check"], nil, nil)==0;
        } else {
            self.opensshState.on = [NSUserDefaults.appDefaults boolForKey:@"openssh"];
        }
    });
}

- (IBAction)respring:(id)sender {
    
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
    if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code (%d)",status]];
}

- (IBAction)rebuildapps:(id)sender {
    STRAPLOG("Status: Rebuilding Apps");
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:NSLocalizedString(@"Applying", nil)];

        NSString* log=nil;
        NSString* err=nil;
        int status = spawnBootstrap((char*[]){"/bin/sh", "/basebin/rebuildapps.sh", NULL}, nil, nil);
        if(status==0) {
            killAllForApp("/usr/libexec/backboardd");
        } else {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code (%d)",status]];
        }
        [AppDelegate dismissHud];
    });
}

- (IBAction)appenabler:(id)sender {
    
    AppViewController *vc = [[AppViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:^{}];
}

- (IBAction)openssh:(id)sender {
    UISwitch* enabled = (UISwitch*)sender;
    
    if(!isSystemBootstrapped()) {
        [NSUserDefaults.appDefaults setValue:@(enabled.on) forKey:@"openssh"];
        [NSUserDefaults.appDefaults synchronize];
        return;
    }
    
    if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/usr/libexec/sshd-keygen-wrapper")]) {
        [AppDelegate showMesage:NSLocalizedString(@"OpenSSH package is not installed.", nil) title:NSLocalizedString(@"Developer", nil)];
        enabled.on = NO;
        return;
    }
    
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",enabled.on?@"start":@"stop"], &log, &err);
    
    //try
    if(!enabled.on) spawnBootstrap((char*[]){"/usr/bin/killall","-9","sshd",NULL}, nil, nil);
    
    if(status==0)
    {
        [NSUserDefaults.appDefaults setValue:@(enabled.on) forKey:@"openssh"];
        [NSUserDefaults.appDefaults synchronize];
    }
    else
    {
        [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code (%d)",status]];
        if(enabled.on) [enabled setOn:NO];
    }
}

- (IBAction)bootstrap:(id)sender {
    if(![self checkTSVersion]) {
        [AppDelegate showMesage:NSLocalizedString(@"Your TrollStore version is out of date. Bootstrap only supports TrollStore 2.", nil) title:NSLocalizedString(@"Error", nil)];
        return;
    }
    
    if(spawnRoot([NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/devtest"], nil, nil, nil) != 0) {
        [AppDelegate showMesage:NSLocalizedString(@"Your device does not seem to have developer mode enabled.\n\nPlease enable developer mode in Settings > Privacy & Security and reboot your device.", nil) title:NSLocalizedString(@"Error", nil)];
        return;
    }
    
    UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
    [generator impactOccurred];

    if(find_jbroot()) //make sure jbroot() function available
    {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.installed_dopamine")]) {
            [AppDelegate showMesage:NSLocalizedString(@"RootHide Dopamine has been installed on this device, now install this bootstrap may break it!", nil) title:NSLocalizedString(@"Error", nil)];
            return;
        }
        
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.bootstrapped")]) {
            NSString* strappedVersion = [NSString stringWithContentsOfFile:jbroot(@"/.bootstrapped") encoding:NSUTF8StringEncoding error:nil];
            if(strappedVersion.intValue != BOOTSTRAP_VERSION) {
                [AppDelegate showMesage:NSLocalizedString(@"You've installed an old beta version, please disable all app tweaks and reboot the device to uninstall it so that you can install the latest version.", nil) title:NSLocalizedString(@"Error", nil)];
                return;
            }
        }
    }
    
    [self.bootstraBtn setEnabled:NO];
    [self.uninstallBtn setEnabled:NO];

    [AppDelegate showHudMsg:NSLocalizedString(@"Bootstrapping", nil)];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        const char* argv[] = {NSBundle.mainBundle.executablePath.fileSystemRepresentation, "bootstrap", NULL};
        int status = spawn(argv[0], argv, environ, ^(char* outstr){
            [AppDelegate addLogText:@(outstr)];
        }, ^(char* errstr){
            [AppDelegate addLogText:[NSString stringWithFormat:@"ERR: %s\n",errstr]];
        });
        
        [AppDelegate dismissHud];
        
        if(status != 0)
        {
            [AppDelegate showMesage:@"" title:[NSString stringWithFormat:@"code (%d)",status]];
            return;
        }
        
        NSString* log=nil;
        NSString* err=nil;
            
        if([NSUserDefaults.appDefaults boolForKey:@"openssh"] && [NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/usr/libexec/sshd-keygen-wrapper")]) {
            NSString* log=nil;
            NSString* err=nil;
             status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",@"start"], &log, &err);
            if(status==0)
                [AppDelegate addLogText:@"openssh launch successful"];
            else
                [AppDelegate addLogText:[NSString stringWithFormat:@"openssh launch faild(%d):\n%@\n%@", status, log, err]];
        }
        
        [AppDelegate addLogText:@"respring now..."]; sleep(1);
        
         status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
        if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code (%d)",status]];

    });
}

- (IBAction)unbootstrap:(id)sender {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warnning", nil) message:NSLocalizedString(@"Are you sure to uninstall bootstrap?\n\nPlease make sure you have disabled tweaks for all apps before uninstalling.", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Uninstall", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [AppDelegate showHudMsg:NSLocalizedString(@"Uninstalling", nil)];

            NSString* log=nil;
            NSString* err=nil;
            int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);
                
            [AppDelegate dismissHud];
            
            if(status == 0) {
                [AppDelegate showMesage:@"" title:NSLocalizedString(@"Bootstrap Uninstalled", nil)];
            } else {
                [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code (%d)",status]];
            }
        });
        
    }]];
    [AppDelegate showAlert:alert];
    
}


@end
