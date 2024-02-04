#include "common.h"
#include "credits.h"
#include "bootstrap.h"
#include "AppList.h"
#include "AppDelegate.h"
#import "ViewController.h"
#include "AppViewController.h"
#include "NSUserDefaults+appDefaults.h"
#import "Bootstrap-Swift.h"
#import <sys/sysctl.h>
#include <sys/utsname.h>

#include <Security/SecKey.h>
#include <Security/Security.h>
typedef struct CF_BRIDGED_TYPE(id) __SecCode const* SecStaticCodeRef; /* code on disk */
typedef enum { kSecCSDefaultFlags=0, kSecCSSigningInformation = 1 << 1 } SecCSFlags;
OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef* CF_RETURNS_RETAINED staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef* __nonnull CF_RETURNS_RETAINED information);


@interface ViewController ()
@end

BOOL gTweakEnabled=YES;

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
}

BOOL updateOpensshStatus(BOOL notify)
{
    BOOL status;
    
    if(isSystemBootstrapped()) {
        status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",@"check"], nil, nil)==0;
    } else {
        status = [NSUserDefaults.appDefaults boolForKey:@"openssh"];
    }
    
    if(notify) [NSNotificationCenter.defaultCenter postNotificationName:@"opensshStatusNotification" object:@(status)];
    
    return status;
}

BOOL checkServer()
{
    static bool alerted = false;
    if(alerted) return NO;

    BOOL ret=NO;

    if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"check"], nil, nil) != 0)
    {
        ret = NO;
        alerted = true;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Server Not Running") message:Localized(@"for unknown reasons the bootstrap server is not running, the only thing we can do is to restart it now.") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Restart Server") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){

            alerted = false;

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
        ret = YES;
    }
    
    updateOpensshStatus(YES);
    return ret;
}

void initFromSwiftUI()
{
    BOOL IconCacheRebuilding=NO;

    if(isSystemBootstrapped())
    {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.rebuildiconcache")]) {
            [NSFileManager.defaultManager removeItemAtPath:jbroot(@"/basebin/.rebuildiconcache") error:nil];
            [AppDelegate showHudMsg:Localized(@"Rebuilding") detail:Localized(@"Don't exit Bootstrap app until show the lock screen")];
            IconCacheRebuilding = YES;
        }
    }

    [AppDelegate addLogText:[NSString stringWithFormat:Localized(@"ios-version: %@"),UIDevice.currentDevice.systemVersion]];

    struct utsname systemInfo;
    uname(&systemInfo);
    [AppDelegate addLogText:[NSString stringWithFormat:Localized(@"device-model: %s"),systemInfo.machine]];

    [AppDelegate addLogText:[NSString stringWithFormat:Localized(@"app-version: %@"),NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]]];

    [AppDelegate addLogText:[NSString stringWithFormat:Localized(@"boot-session: %@"),getBootSession()]];

    [AppDelegate addLogText: isBootstrapInstalled()? Localized(@"bootstrap installed"):Localized(@"bootstrap not installed")];
    [AppDelegate addLogText: isSystemBootstrapped()? Localized(@"system bootstrapped"):Localized(@"system not bootstrapped")];

    SYSLOG("locale=%@", NSLocale.currentLocale.countryCode);
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);
    [NSUserDefaults.appDefaults setValue:NSLocale.currentLocale.countryCode forKey:@"locale"];
    [NSUserDefaults.appDefaults synchronize];
    SYSLOG("locale=%@", [NSUserDefaults.appDefaults valueForKey:@"locale"]);

    if(isSystemBootstrapped())
    {
        if(checkServer()) {
            [AppDelegate addLogText:Localized(@"bootstrap server check successful")];
        }

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            checkServer();
        }];
    }

    if(!IconCacheRebuilding && isBootstrapInstalled() && !isSystemBootstrapped()) {
        if([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"filza://"]]
           || [LSPlugInKitProxy pluginKitProxyForIdentifier:@"com.tigisoftware.Filza.Sharing"])
        {
            [AppDelegate showMesage:Localized(@"It seems that you have the Filza app installed, which may be detected as jailbroken. You can enable Tweak for it to hide it.") title:Localized(@"Warning")];
        }
    }
}

@end

BOOL checkTSVersion()
{    
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

void respringAction()
{
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
    if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
}

void rebuildappsAction()
{
    [AppDelegate addLogText:Localized(@"Status: Rebuilding Apps")];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Applying")];

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

void reinstallPackageManager()
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Applying")];

        NSString* log=nil;
        NSString* err=nil;

        BOOL success=YES;

        [AppDelegate addLogText:Localized(@"Status: Reinstalling Sileo")];
        NSString* sileoDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"sileo.deb"];
        if(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(sileoDeb).fileSystemRepresentation, NULL}, &log, &err) != 0) {
            [AppDelegate addLogText:[NSString stringWithFormat:@"failed:%@\nERR:%@", log, err]];
            success = NO;
        }

        if(spawnBootstrap((char*[]){"/usr/bin/uicache", "-p", "/Applications/Sileo.app", NULL}, &log, &err) != 0) {
            [AppDelegate addLogText:[NSString stringWithFormat:@"failed:%@\nERR:%@", log, err]];
            success = NO;
        }

        [AppDelegate addLogText:Localized(@"Status: Reinstalling Zebra")];
        NSString* zebraDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"zebra.deb"];
        if(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(zebraDeb).fileSystemRepresentation, NULL}, nil, nil) != 0) {
            [AppDelegate addLogText:[NSString stringWithFormat:@"failed:%@\nERR:%@", log, err]];
            success = NO;
        }

        if(spawnBootstrap((char*[]){"/usr/bin/uicache", "-p", "/Applications/Zebra.app", NULL}, &log, &err) != 0) {
            [AppDelegate addLogText:[NSString stringWithFormat:@"failed:%@\nERR:%@", log, err]];
            success = NO;
        }

        if(success) {
            [AppDelegate showMesage:Localized(@"Sileo and Zebra reinstalled!") title:@""];
        }
        [AppDelegate dismissHud];
    });
}

int rebuildIconCache()
{
    AppList* tsapp = [AppList appWithBundleIdentifier:@"com.opa334.TrollStore"];
    if(!tsapp) {
        STRAPLOG("trollstore not found!");
        return -1;
    }

    STRAPLOG("rebuild icon cache...");
    ASSERT([LSApplicationWorkspace.defaultWorkspace _LSPrivateRebuildApplicationDatabasesForSystemApps:YES internal:YES user:YES]);

    NSString* log=nil;
    NSString* err=nil;

    if(spawnRoot([tsapp.bundleURL.path stringByAppendingPathComponent:@"trollstorehelper"], @[@"refresh"], &log, &err) != 0) {
        STRAPLOG("refresh tsapps failed:%@\nERR:%@", log, err);
        return -1;
    }

    [[NSString new] writeToFile:jbroot(@"/basebin/.rebuildiconcache") atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [LSApplicationWorkspace.defaultWorkspace openApplicationWithBundleID:NSBundle.mainBundle.bundleIdentifier];

    int status = spawnBootstrap((char*[]){"/bin/sh", "/basebin/rebuildapps.sh", NULL}, &log, &err);
    if(status==0) {
        killAllForApp("/usr/libexec/backboardd");
    } else {
        STRAPLOG("rebuildapps failed:%@\nERR:\n%@",log,err);
    }

    if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.rebuildiconcache")]) {
        [NSFileManager.defaultManager removeItemAtPath:jbroot(@"/basebin/.rebuildiconcache") error:nil];
    }

    return status;
}

void rebuildIconCacheAction()
{
    [AppDelegate addLogText:Localized(@"Status: Rebuilding Icon Cache")];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Rebuilding") detail:Localized(@"Don't exit Bootstrap app until show the lock screen")];

        NSString* log=nil;
        NSString* err=nil;
        int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"rebuildiconcache"], &log, &err);
        if(status != 0) {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        }

        [AppDelegate dismissHud];
    });
}

void tweaEnableAction(BOOL enable)
{
    gTweakEnabled = enable;
    
    if(!isBootstrapInstalled()) return;

    if(enable) {
        ASSERT([[NSString new] writeToFile:jbroot(@"/var/mobile/.tweakenabled") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    } else if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/mobile/.tweakenabled")]) {
        ASSERT([NSFileManager.defaultManager removeItemAtPath:jbroot(@"/var/mobile/.tweakenabled") error:nil]);
    }
}

BOOL opensshAction(BOOL enable)
{
    if(!isSystemBootstrapped()) {
        [NSUserDefaults.appDefaults setValue:@(enable) forKey:@"openssh"];
        [NSUserDefaults.appDefaults synchronize];
        return enable;
    }
    
    if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.launchctl_support")]) {
        return NO;
    }

    if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/usr/libexec/sshd-keygen-wrapper")]) {
        [AppDelegate showMesage:Localized(@"openssh package is not installed") title:Localized(@"Developer")];
        return NO;
    }

    NSString* log=nil;
    NSString* err=nil;
    int status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",enable?@"start":@"stop"], &log, &err);

    //try
    if(!enable) spawnBootstrap((char*[]){"/usr/bin/killall","-9","sshd",NULL}, nil, nil);

    if(status==0)
    {
        [NSUserDefaults.appDefaults setValue:@(enable) forKey:@"openssh"];
        [NSUserDefaults.appDefaults synchronize];
    }
    else
    {
        [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        return NO;
    }
    
    return enable;
}


void bootstrapAction()
{
    if(isSystemBootstrapped())
    {
        ASSERT(checkBootstrapVersion()==false);

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Update") message:Localized(@"The current bootstrapped version is inconsistent with the Bootstrap app version, and you need to reboot the device to update it.") preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Reboot Device") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            ASSERT(spawnRoot(NSBundle.mainBundle.executablePath, @[@"reboot"], nil, nil)==0);
        }]];

        [AppDelegate showAlert:alert];
        return;
    }

    if(!checkTSVersion()) {
        [AppDelegate showMesage:Localized(@"Your trollstore version is too old, Bootstrap only supports trollstore>=2.0, you have to update your trollstore then reinstall Bootstrap app.") title:Localized(@"Error")];
        return;
    }

    if(spawnRoot([NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/devtest"], nil, nil, nil) != 0) {
        [AppDelegate showMesage:Localized(@"Your device does not seem to have developer mode enabled.\n\nPlease enable developer mode and reboot your device.") title:Localized(@"Error")];
        return;
    }

    UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
    [generator impactOccurred];

    if(find_jbroot()) //make sure jbroot() function available
    {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.installed_dopamine")]) {
            [AppDelegate showMesage:Localized(@"roothide dopamine has been installed on this device, now install this bootstrap may break it!") title:Localized(@"Error")];
            return;
        }

        //check beta version
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.bootstrapped")]) {
            NSString* strappedVersion = [NSString stringWithContentsOfFile:jbroot(@"/.bootstrapped") encoding:NSUTF8StringEncoding error:nil];
            if(strappedVersion.intValue != BOOTSTRAP_VERSION) {
                [AppDelegate showMesage:Localized(@"You have installed an old beta version, please disable all app tweaks and reboot the device to uninstall it so that you can install the new version bootstrap.") title:Localized(@"Error")];
                return;
            }
        }
    }

    [AppDelegate showHudMsg:Localized(@"Bootstrapping")];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{

        const char* argv[] = {NSBundle.mainBundle.executablePath.fileSystemRepresentation, "bootstrap", NULL};
        int status = spawn(argv[0], argv, environ, ^(char* outstr, int length){
            NSString *str = [[NSString alloc] initWithBytes:outstr length:length encoding:NSASCIIStringEncoding];
            [AppDelegate addLogText:str];
        }, ^(char* errstr, int length){
            NSString *str = [[NSString alloc] initWithBytes:errstr length:length encoding:NSASCIIStringEncoding];
            [AppDelegate addLogText:[NSString stringWithFormat:@"ERR: %@\n",str]];
        });

        [AppDelegate dismissHud];

        if(status != 0)
        {
            [AppDelegate showMesage:@"" title:[NSString stringWithFormat:@"code(%d)",status]];
            return;
        }

        NSString* log=nil;
        NSString* err=nil;

        if([NSUserDefaults.appDefaults boolForKey:@"openssh"] && [NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/usr/libexec/sshd-keygen-wrapper")])
        {
            NSString* log=nil;
            NSString* err=nil;
             status = spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"openssh",@"start"], &log, &err);
            if(status==0)
                [AppDelegate addLogText:Localized(@"openssh launch successful")];
            else
                [AppDelegate addLogText:[NSString stringWithFormat:@"openssh launch faild(%d):\n%@\n%@", status, log, err]];
        }

        if(gTweakEnabled && ![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/mobile/.tweakenabled")]) {
            ASSERT([[NSString new] writeToFile:jbroot(@"/var/mobile/.tweakenabled") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
        }

        [generator impactOccurred];
        [AppDelegate addLogText:Localized(@"respring now...")]; sleep(1);

         status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
        if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];

    });
}


void unbootstrapAction()
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Warning") message:Localized(@"Are you sure to uninstall bootstrap?\n\nPlease make sure you have disabled tweak for all apps before uninstalling.") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Uninstall") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [AppDelegate showHudMsg:Localized(@"Uninstalling")];

            NSString* log=nil;
            NSString* err=nil;
            int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);

            [AppDelegate dismissHud];

            NSString* msg = (status==0) ? Localized(@"bootstrap uninstalled") : [NSString stringWithFormat:@"code(%d)\n%@\n\nstderr:\n%@",status,log,err];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                exit(0);
            }]];

            [AppDelegate showAlert:alert];

        });

    }]];
    [AppDelegate showAlert:alert];
}

void resetMobilePassword()
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Reset Mobile Password") message:Localized(@"Set the mobile password of your device, this can also be used for root access using sudo. If you want to set the root password, you can do so from a mobile shell using \"sudo passwd root\"") preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        
        NSString* log=nil;
        NSString* err=nil;
        NSString* pwcmd = [NSString stringWithFormat:@"printf \"%%s\\n\" \"%@\" | /usr/sbin/pw usermod 501 -h 0", alert.textFields.lastObject.text];
        const char* args[] = {"/usr/bin/dash", "-c", pwcmd.UTF8String, NULL};
        int status = spawnBootstrap(args, &log, &err);
        if(status == 0 || status == 67) {
            [AppDelegate showMesage:Localized(@"done") title:@""];
        } else {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        }

    }]];
    [AppDelegate showAlert:alert];
}
