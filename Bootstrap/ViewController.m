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
@property (weak, nonatomic) IBOutlet UIButton *unbootstrapBtn;
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
    self.logView.layer.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.01].CGColor;
    self.logView.layer.borderColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.01].CGColor;
    self.logView.layer.borderWidth = 1.0;
    self.logView.layer.cornerRadius = 5.0;
    
    [AppDelegate registerLogView:self.logView];
    
    if(isSystemBootstrapped())
    {
        self.bootstraBtn.enabled = NO;
        [self.bootstraBtn setTitle:Localized(@"已安装") forState:UIControlStateDisabled];
        
        self.respringBtn.enabled = YES;
        self.appEnablerBtn.enabled = YES;
        self.rebuildappsBtn.enabled = YES;
        self.uninstallBtn.enabled = NO;
        self.uninstallBtn.hidden = NO;
        
    }
    else if(isBootstrapInstalled())
    {
        
        self.bootstraBtn.enabled = YES;
        [self.bootstraBtn setTitle:Localized(@"Bootstrap") forState:UIControlStateNormal];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.rebuildappsBtn.enabled = NO;
        self.uninstallBtn.hidden = NO;
    }
    else if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion>=15)
    {
        BOOL WaitForFix=NO;
        if(NSProcessInfo.processInfo.operatingSystemVersion.majorVersion==17)
        {
           cpu_subtype_t cpuFamily = 0;
           size_t cpuFamilySize = sizeof(cpuFamily);
           sysctlbyname("hw.cpufamily", &cpuFamily, &cpuFamilySize, NULL, 0);
           if (cpuFamily==CPUFAMILY_ARM_BLIZZARD_AVALANCHE || cpuFamily==CPUFAMILY_ARM_EVEREST_SAWTOOTH) {
               WaitForFix=YES;
           }
        }
        
        if(WaitForFix) {
            self.bootstraBtn.enabled = NO;
            [self.bootstraBtn setTitle:Localized(@"等待修复") forState:UIControlStateDisabled];
            [AppDelegate showMesage:@"A15+上的ios17.0仍在等待修复" title:Localized(@"等待修复")];
        } else {
            self.bootstraBtn.enabled = YES;
            [self.bootstraBtn setTitle:Localized(@"安装") forState:UIControlStateNormal];
        }

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.rebuildappsBtn.enabled = NO;
        self.uninstallBtn.hidden = YES;
    } else {
        self.bootstraBtn.enabled = NO;
        [self.bootstraBtn setTitle:Localized(@"不支持") forState:UIControlStateDisabled];

        self.respringBtn.enabled = NO;
        self.appEnablerBtn.enabled = NO;
        self.rebuildappsBtn.enabled = NO;
        self.uninstallBtn.hidden = YES;
        
        [AppDelegate showMesage:Localized(@"目前的ios版本还不支持，我们可能会在未来的版本中添加支持。") title:Localized(@"不支持")];
    }
    

    [AppDelegate addLogText:[NSString stringWithFormat:@"ios版本: %@",UIDevice.currentDevice.systemVersion]];
    
    struct utsname systemInfo;
    uname(&systemInfo);
    [AppDelegate addLogText:[NSString stringWithFormat:@"设备型号: %s",systemInfo.machine]];
    
    [AppDelegate addLogText:[NSString stringWithFormat:@"应用版本: %@/%@",NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"],NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]]];
    
    [AppDelegate addLogText:[NSString stringWithFormat:@"启动会话: %@",getBootSession()]];
    
    [AppDelegate addLogText: isBootstrapInstalled()? @"引导已安装":@"引导未安装"];
    [AppDelegate addLogText: isSystemBootstrapped()? @"系统已引导":@"系统未引导"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        usleep(1000*500);
        [AppDelegate addLogText:@"\n:::感谢:::\n"];
        usleep(1000*500);
        for(NSString* name in CREDITS) {
            usleep(1000*50);
            [AppDelegate addLogText:[NSString stringWithFormat:@"%@ - %@\n",name,CREDITS[name]]];
        }
        sleep(1);
        [AppDelegate addLogText:Localized(@"\n感谢以上所有朋友，没有他们的帮助，我们不可能完成这个项目!")];
        
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"引导程序未运行") message:Localized(@"由于未知的原因，引导程序没有运行，我们现在唯一能做的就是重新启动它。") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"重启引导程序") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                
                NSString* log=nil;
                NSString* err=nil;
                if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"daemon",@"-f"], &log, &err)==0) {
                    [AppDelegate addLogText:Localized(@"引导程序重启成功")];
                    [self updateOpensshStatus];
                } else {
                    [AppDelegate showMesage:[NSString stringWithFormat:@"%@\nERR:%@"] title:Localized(@"错误")];
                }
                
            }]];
            
            [AppDelegate showAlert:alert];
        } else {
            [AppDelegate addLogText:Localized(@"引导程序检查成功")];
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
    if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
}

- (IBAction)rebuildapps:(id)sender {
    STRAPLOG("状态：正在重建应用程序");
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"正在应用...")];
        
        NSString* log=nil;
        NSString* err=nil;
        int status = spawnBootstrap((char*[]){"/bin/sh", "/basebin/rebuildapps.sh", NULL}, nil, nil);
        if(status==0) {
            killAllForApp("/usr/libexec/backboardd");
        } else {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
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
        [AppDelegate showMesage:Localized(@"openssh 安装包未安装") title:Localized(@"开发者")];
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
        if(enabled.on) [enabled setOn:NO];
    }
}

- (IBAction)bootstrap:(id)sender {
    if(![self checkTSVersion]) {
        [AppDelegate showMesage:Localized(@"你的trollstore版本太旧，Bootstrap只支持trollstore>=2.0版本") title:Localized(@"错误")];
        return;
    }
    
    if(spawnRoot([NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/devtest"], nil, nil, nil) != 0) {
        [AppDelegate showMesage:Localized(@"您的设备似乎未启用开发者模式.\n\n请在设置->[隐私与安全]中启用开发者模式,然后重启您的设备.") title:Localized(@"错误")];
        return;
    }
    
    UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
    generator.impactOccurred;

    if(find_jbroot()) //make sure jbroot() function available
    {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.installed_dopamine")]) {
            [AppDelegate showMesage:Localized(@"roothide dopamine 已经安装在这个设备上，现在安装这个引导程序可能会破坏它!") title:Localized(@"错误")];
            return;
        }
        
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.bootstrapped")]) {
            NSString* strappedVersion = [NSString stringWithContentsOfFile:jbroot(@"/.bootstrapped") encoding:NSUTF8StringEncoding error:nil];
            if(strappedVersion.intValue != BOOTSTRAP_VERSION) {
                [AppDelegate showMesage:Localized(@"您已经安装了旧的测试版，请禁用所有应用程序注入的插件并重启设备以卸载它，以便您可以安装新版本的引导程序。") title:Localized(@"错误")];
                return;
            }
        }
    }
    
    [(UIButton*)sender setEnabled:NO];
    
    [AppDelegate showHudMsg:Localized(@"正在引导...")];
    
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
            
        if([NSUserDefaults.appDefaults boolForKey:@"openssh"] && [NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/usr/libexec/sshd-keygen-wrapper")]) {
            NSString* log=nil;
            NSString* err=nil;
             status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",@"start"], &log, &err);
            if(status==0)
                [AppDelegate addLogText:@"openssh 启用成功"];
            else
                [AppDelegate addLogText:[NSString stringWithFormat:@"openssh 启用失败(%d):\n%@\n%@", status, log, err]];
        }
        
        [AppDelegate addLogText:@"正在注销..."]; sleep(1);
        
         status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
        if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        
    });
}

- (IBAction)unbootstrap:(id)sender {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"提示") message:Localized(@"你确定卸载引导程序吗?\n\n在卸载之前,请确保您已经禁用了所有应用程序已注入的插件。") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"取消") style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"卸载") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [AppDelegate showHudMsg:Localized(@"正在卸载...")];
            
            NSString* log=nil;
            NSString* err=nil;
            int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);
                
            [AppDelegate dismissHud];
            
            if(status == 0) {
                [AppDelegate showMesage:@"" title:@"引导程序未安装"];
            } else {
                [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
            }
        });
        
    }]];
    [AppDelegate showAlert:alert];
    
}


@end
