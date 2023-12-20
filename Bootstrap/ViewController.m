#import "ViewController.h"
#include "NSUserDefaults+appDefaults.h"
#include "common.h"
#include "AppDelegate.h"
#include "AppViewController.h"
#include "bootstrap.h"
#include "credits.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *bootstraBtn;
@property (weak, nonatomic) IBOutlet UIButton *unbootstrapBtn;
@property (weak, nonatomic) IBOutlet UITextView *logView;

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
    
//    for(int i=0;i<100;i++)
    [AppDelegate addLogText: isDeviceBootstrapped()? @"device is strapped":@"bootstrap not installed"];
    
    [AppDelegate addLogText:[NSString stringWithFormat:@"app-version: %@",NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"]]];
    [AppDelegate addLogText:[NSString stringWithFormat:@"short-version: %@",NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]]];
    
    [AppDelegate addLogText:[NSString stringWithFormat:@"boot-session: %@",getBootSession()]];
    
    [AppDelegate addLogText:@"Credits:"];
    for(NSString* name in CREDITS) {
        [AppDelegate addLogText:[NSString stringWithFormat:@"%@@%@",name,CREDITS[name]]];
    }
    
    SYSLOG("locale=%@", NSLocale.currentLocale.countryCode);
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
    [NSUserDefaults.appDefaults setValue:NSLocale.currentLocale.countryCode forKey:@"locale"];
    [NSUserDefaults.appDefaults synchronize];
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        (spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"server"], nil, nil)==0);
    });
}

- (IBAction)respring:(id)sender {
    
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnBootstrap((char*[]){"/usr/bin/uicache", "-ar", NULL}, &log, &err);
    if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"stats(%d)",status]];
}


- (IBAction)appenabler:(id)sender {
    
    AppViewController *vc = [[AppViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navigationController animated:YES completion:^{}];
}

- (IBAction)openssh:(id)sender {
    UISwitch* enabled = (UISwitch*)sender;
    
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",enabled.on?@"start":@"stop"], &log, &err);
    if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"stats(%d)",status]];
}

- (IBAction)bootstrap:(id)sender {
    
    [AppDelegate showHudMsg:Localized(@"Bootstrapping")];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        const char* argv[] = {NSBundle.mainBundle.executablePath.fileSystemRepresentation, "bootstrap", NULL};
        int status = spawn(argv[0], argv, environ, ^(char* outstr){
            [AppDelegate addLogText:@(outstr)];
        }, ^(char* errstr){
            [AppDelegate addLogText:[NSString stringWithFormat:@"ERR: %s\n",errstr]];
        });
        
        [AppDelegate dismissHud];
        
        if(status!=0) [AppDelegate showMesage:@"" title:[NSString stringWithFormat:@"stats(%d)",status]];
    });
}

- (IBAction)unbootstrap:(id)sender {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Uninstalling")];
        
        NSString* log=nil;
        NSString* err=nil;
        int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);
        
        [AppDelegate dismissHud];
        if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"stats(%d)",status]];
    });
}


@end
