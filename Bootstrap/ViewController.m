#import "ViewController.h"
#include "NSUserDefaults+appDefaults.h"
#include "common.h"
#include "AppDelegate.h"
#include "AppViewController.h"
#include "bootstrap.h"
#include "credits.h"
#include <sys/utsname.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UIButton *bootstraBtn;
@property (weak, nonatomic) IBOutlet UIButton *unbootstrapBtn;
@property (weak, nonatomic) IBOutlet UISwitch *opensshState;
@property (weak, nonatomic) IBOutlet UIButton *appEnablerBtn;
@property (weak, nonatomic) IBOutlet UIButton *respringBtn;
@property (weak, nonatomic) IBOutlet UIButton *uninstallBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.logView.text = nil;
    self.logView.layer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.01].CGColor;
    self.logView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.01].CGColor;
    self.logView.layer.borderWidth = 1.0;
    self.logView.layer.cornerRadius = 5.0;
    
    [AppDelegate registerLogView:self.logView];
    
    if(isSystemBootstrapped())
    {
        self.bootstraBtn.enabled = NO;
        [self.bootstraBtn setTitle:Localized(@"Bootstrapped") forState:UIControlStateDisabled];
        
        self.respringBtn.enabled = YES;
        self.appEnablerBtn.enabled = YES;
        self.uninstallBtn.hidden = YES;
        
    }
    else if(isBootstrapInstalled())
    {
        
        self.bootstraBtn.enabled = YES;
        [self.bootstraBtn setTitle:Localized(@"Bootstrap") forState:UIControlStateNormal];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.uninstallBtn.hidden = NO;
    }
    else if(@available(iOS 16.0, *))
    {
        self.bootstraBtn.enabled = YES;
        [self.bootstraBtn setTitle:Localized(@"Install") forState:UIControlStateNormal];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.uninstallBtn.hidden = YES;
    } else {
        self.bootstraBtn.enabled = NO;
        [self.bootstraBtn setTitle:Localized(@"Unsupported") forState:UIControlStateDisabled];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.uninstallBtn.hidden = YES;
        
        [AppDelegate showMesage:Localized(@"the current ios version is not supported yet, we may add support in a future version.") title:Localized(@"Unsupported")];
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
        [AppDelegate addLogText:@"\nthanks to these guys, we couldn't have completed this project without their help!"];
        
    });
    
    SYSLOG("locale=%@", NSLocale.currentLocale.countryCode);
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
    [NSUserDefaults.appDefaults setValue:NSLocale.currentLocale.countryCode forKey:@"locale"];
    [NSUserDefaults.appDefaults synchronize];
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
    
    if(isSystemBootstrapped()) {
        self.opensshState.on = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",@"check"], nil, nil)==0;
    } else {
        self.opensshState.on = [NSUserDefaults.appDefaults boolForKey:@"openssh"];
    }
}

- (IBAction)respring:(id)sender {
    
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnBootstrap((char*[]){"/usr/bin/uicache", "-ar", NULL}, &log, &err);
    if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
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
        [AppDelegate showMesage:Localized(@"openssh package is not installed") title:Localized(@"Developer")];
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
        [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        [enabled setOn:!enabled.on];
    }
}

- (IBAction)bootstrap:(id)sender {
    
    [(UIButton*)sender setEnabled:NO];
    
    [AppDelegate showHudMsg:Localized(@"Bootstrapping")];
    
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
            [AppDelegate showMesage:@"" title:[NSString stringWithFormat:@"code(%d)",status]];
            return;
        }
        NSString* log=nil;
        NSString* err=nil;
         status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"server"], &log, &err);
        if(status != 0) {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\nERR:%@", log, err] title:[NSString stringWithFormat:@"bootstrap server load faild(%d)",status]];
            return;
        }
        
        [AppDelegate addLogText:@"bootstrap server load successful"];
            
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
        if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        
    });
}

- (IBAction)unbootstrap:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Uninstalling")];
        
        NSString* log=nil;
        NSString* err=nil;
        int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);
        
        [AppDelegate dismissHud];
        if(status!=0)
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        else
            [AppDelegate showMesage:@"" title:@"bootstrap uninstalled"];

    });
}


@end
