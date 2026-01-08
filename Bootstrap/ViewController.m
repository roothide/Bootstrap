#include "common.h"
#include "credits.h"
#include "bootstrap.h"
#include "AppInfo.h"
#include "AppDelegate.h"
#include "ViewController.h"
#include "AppViewController.h"
#include "NSUserDefaults+appDefaults.h"
#include "Bootstrap-Swift.h"
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/sysctl.h>
#include <sys/utsname.h>

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
    
    if(isSystemBootstrapped() && spawnRoot(jbroot(@"/basebin/bsctl"), @[@"check"], nil, nil)==0) {
        status = spawnRoot(jbroot(@"/basebin/bsctl"), @[@"openssh",@"check"], nil, nil)==0;
    } else {
        status = [NSUserDefaults.appDefaults boolForKey:@"openssh"];
    }
    
    if(notify) [NSNotificationCenter.defaultCenter postNotificationName:@"opensshStatusNotification" object:@(status)];
    
    return status;
}

void checkAppsHidden()
{
    if(isAllCTBugAppsHidden()) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Jailbroken Apps are Hidden") message:Localized(@"Do you want to restore them now?") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"NO") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"YES") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            unhideAllCTBugApps();
        }]];
        [AppDelegate showAlert:alert];
    }
}

void tryLoadOpenSSH()
{
    if([NSUserDefaults.appDefaults boolForKey:@"openssh"] && [NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/usr/libexec/sshd-keygen-wrapper")])
    {
        NSString* log=nil;
        NSString* err=nil;
        int status = spawnRoot(jbroot(@"/basebin/bsctl"), @[@"openssh",@"start"], &log, &err);
        if(status==0)
            [AppDelegate addLogText:Localized(@"openssh launch successful")];
        else
            [AppDelegate addLogText:[NSString stringWithFormat:@"openssh launch faild(%d):\n%@\n%@", status, log, err]];
    }
}

BOOL checkServer()
{
    static bool alerted = false;
    if(alerted) return NO;

    BOOL ret=NO;

    if(spawnRoot(jbroot(@"/basebin/bsctl"), @[@"check"], nil, nil) != 0)
    {
        ret = NO;
        alerted = true;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Server Not Running") message:Localized(@"for unknown reasons the bootstrap server is not running, the only thing we can do is to restart it now.") preferredStyle:UIAlertControllerStyleAlert];
        
        if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.launchctl_support")])
          [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Restart Server") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            
            alerted = false;

            NSString* log=nil;
            NSString* err=nil;
            if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"daemon",@"-f"], &log, &err)==0) {
                [AppDelegate addLogText:Localized(@"bootstrap server restart successful")];
                checkAppsHidden();
                tryLoadOpenSSH();
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


#define PROC_PIDPATHINFO_MAXSIZE  (1024)
int proc_pidpath(pid_t pid, void *buffer, uint32_t buffersize);
NSString* getLaunchdPath()
{
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE] = {0};
    int ret = proc_pidpath(1, pathbuf, sizeof(pathbuf));
    if(ret <= 0) {
        SYSLOG("proc_pidpath failed: %d:%d,%s", ret, errno, strerror(errno));
        return nil;
    }
    return @(pathbuf);
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

    struct utsname systemInfo={0}; uname(&systemInfo);
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
        if(!checkBootstrapVersion()) {
            return;
        }
        
        if(checkServer()) {
            [AppDelegate addLogText:Localized(@"bootstrap server check successful")];
            checkAppsHidden();
        }

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if(isSystemBootstrapped()) checkServer();
        }];
    }

    if(!IconCacheRebuilding && isSystemBootstrapped() && ![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.launchctl_support")]) {
        if([UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:@"filza://"]]
           || [LSPlugInKitProxy pluginKitProxyForIdentifier:@"com.tigisoftware.Filza.Sharing"])
        {
            [AppDelegate showMesage:Localized(@"It seems that you have the Filza installed in trollstore, which may be detected as jailbroken. You can remove it from trollstore then install Filza from roothide repo in Sileo.") title:Localized(@"Warning")];
        }
    }
}

@end

void setIdleTimerDisabled(BOOL disabled) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] setIdleTimerDisabled:disabled];
    });
}

BOOL checkTSVersion()
{
    NSString* teamID = getTeamIDFromBinaryAtPath(NSBundle.mainBundle.executablePath);
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
        setIdleTimerDisabled(YES);

        NSString* log=nil;
        NSString* err=nil;
        int status = spawnBootstrap((char*[]){"/bin/sh", "/basebin/rebuildApps.sh", NULL}, nil, nil);
        if(status==0) {
            killAllForExecutable("/usr/libexec/backboardd");
        } else {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        }
        [AppDelegate dismissHud];
        setIdleTimerDisabled(NO);
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
    AppInfo* tsapp = [AppInfo appWithBundleIdentifier:@"com.opa334.TrollStore"];
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

    int status = spawnBootstrap((char*[]){"/bin/sh", "/basebin/rebuildApps.sh", NULL}, &log, &err);
    if(status==0) {
        killAllForExecutable("/usr/libexec/backboardd");
    } else {
        STRAPLOG("rebuildApps failed:%@\nERR:\n%@",log,err);
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
        setIdleTimerDisabled(YES);
        [AppDelegate showHudMsg:Localized(@"Rebuilding") detail:Localized(@"Don't exit Bootstrap app until show the lock screen")];

        NSString* log=nil;
        NSString* err=nil;
        int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"rebuildiconcache"], &log, &err);
        if(status != 0) {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        }

        [AppDelegate dismissHud];
        setIdleTimerDisabled(NO);
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
    
    if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.launchctl_support")]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Userspace Reboot Required") message:Localized(@"A userspace reboot is neccessary to apply the changes. Do you want to do it now?") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Reboot Later") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Reboot Now") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            spawnBootstrap((char*[]){"/usr/bin/launchctl","reboot","userspace",NULL}, nil, nil);
        }]];
        [AppDelegate showAlert:alert];
    }
}

void URLSchemesToggle(BOOL enable)
{
    if(enable) {
        ASSERT([[NSString new] writeToFile:jbroot(@"/var/mobile/.allow_url_schemes") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
    } else if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/mobile/.allow_url_schemes")]) {
        ASSERT([NSFileManager.defaultManager removeItemAtPath:jbroot(@"/var/mobile/.allow_url_schemes") error:nil]);
    }
    
    rebuildappsAction();
}

void URLSchemesAction(BOOL enable)
{
    if(!isSystemBootstrapped()) return;
    
    if(!enable)
    {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.launchctl_support")]) {
            [NSNotificationCenter.defaultCenter postNotificationName:@"URLSchemesStatusNotification" object:@(YES)];
            [AppDelegate showMesage:Localized(@"URL Schemes are now undetectable on your device, you don't need to disable them anymore.") title:@""];
            return;
        }
        
        URLSchemesToggle(enable);
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Warning") message:Localized(@"Enabling URL Schemes may result in jailbreak detection. Are you sure you want to continue?") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"NO") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [NSNotificationCenter.defaultCenter postNotificationName:@"URLSchemesStatusNotification" object:@(NO)];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"YES") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        URLSchemesToggle(enable);
    }]];
    [AppDelegate showAlert:alert];
}

BOOL opensshAction(BOOL enable)
{
    if(!isSystemBootstrapped()) {
        [NSUserDefaults.appDefaults setValue:@(enable) forKey:@"openssh"];
        [NSUserDefaults.appDefaults synchronize];
        return enable;
    }

    if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/usr/libexec/sshd-keygen-wrapper")]) {
        [AppDelegate showMesage:Localized(@"openssh package is not installed") title:Localized(@"Developer")];
        return NO;
    }
    
    if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/basebin/.launchctl_support")]) {
        [AppDelegate showMesage:Localized(@"The SSH Service on your device is hosted by launchd.") title:@""];
        return NO;
    }

    NSString* log=nil;
    NSString* err=nil;
    int status = spawnRoot(jbroot(@"/basebin/bsctl"), @[@"openssh",enable?@"start":@"stop"], &log, &err);

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

void rebootUserspaceAction()
{
    spawnBootstrap((char*[]){"/usr/bin/launchctl","reboot","userspace",NULL}, nil, nil);
}

NSArray* ResignExecutables = @[
    @"/sbin/launchd",
    @"/usr/libexec/xpcproxy",
    @"/System/Library/CoreServices/SpringBoard.app/SpringBoard",
    @"/usr/bin/powerlogHelperd",
    @"/usr/sbin/spindump",
    @"/usr/libexec/replayd",
    @"/usr/libexec/sharingd",
    @"/usr/libexec/locationd",
    @"/usr/libexec/runningboardd",
    @"/usr/libexec/backboardd",
    @"/usr/libexec/thermalmoniord",
    @"/usr/sbin/installd",
    @"/usr/sbin/cfprefsd",
    @"/usr/libexec/nfcd",
];

#define RESIGNED_SYSROOT_PATH jbroot(@"/.sysroot")

int exploitStart(NSString* execDir)
{
    NSFileManager* fm = NSFileManager.defaultManager;
    
    // Patch basebin plists
    NSURL *basebinDaemonsURL = [NSURL fileURLWithPath:jbroot(@"/basebin/LaunchDaemons")];
    for (NSURL *fileURL in [fm contentsOfDirectoryAtURL:basebinDaemonsURL includingPropertiesForKeys:nil options:0 error:nil]) {
        NSString* plistContent = [NSString stringWithContentsOfFile:fileURL.path encoding:NSUTF8StringEncoding error:nil];
        if(plistContent) {
            plistContent = [plistContent stringByReplacingOccurrencesOfString:@"@JBROOT@" withString:jbroot(@"/")];
            plistContent = [plistContent stringByReplacingOccurrencesOfString:@"@JBRAND@" withString:[NSString stringWithFormat:@"%016llX",jbrand()]];
            ASSERT([plistContent writeToFile:fileURL.path atomically:YES encoding:NSUTF8StringEncoding error:nil]);
        }
    }

    if([fm fileExistsAtPath:RESIGNED_SYSROOT_PATH]) {
        ASSERT([fm removeItemAtPath:RESIGNED_SYSROOT_PATH error:nil]);
    }
    
    NSString* ldidPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/ldid"];
    NSString* fastSignPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/fastPathSign"];
    
    for(NSString* sourcePath in ResignExecutables)
    {
        NSString* destPath = [RESIGNED_SYSROOT_PATH stringByAppendingPathComponent:sourcePath];
        NSString* destDirPath = [destPath stringByDeletingLastPathComponent];
        
        NSString* destSubPathTemp = RESIGNED_SYSROOT_PATH;
        NSArray<NSString *>* sourcePathComponents = sourcePath.pathComponents;
        for(NSString* item in sourcePathComponents)
        {
            destSubPathTemp = [destSubPathTemp stringByAppendingPathComponent:item];
            
            struct stat st={0};
            if(lstat(destSubPathTemp.fileSystemRepresentation, &st) != 0) {
                break;
            }
            
            if(S_ISLNK(st.st_mode)) {
                ASSERT(unlink(destSubPathTemp.fileSystemRepresentation)==0);
                break;
            }
        }
        
        if(![fm fileExistsAtPath:destDirPath]) {
            NSDictionary* attr = @{NSFilePosixPermissions:@(0755), NSFileOwnerAccountID:@(0), NSFileGroupOwnerAccountID:@(0)};
            ASSERT([fm createDirectoryAtPath:destDirPath withIntermediateDirectories:YES attributes:attr error:nil]);
        }
        
        ASSERT([fm copyItemAtPath:sourcePath toPath:destPath error:nil]);
        
        NSURL* sourceDirURL = [NSURL fileURLWithPath:sourcePath.stringByDeletingLastPathComponent];
        for (NSURL* fileURL in [fm contentsOfDirectoryAtURL:sourceDirURL includingPropertiesForKeys:nil options:0 error:nil]) {
            NSString* destfile = [destDirPath stringByAppendingPathComponent:fileURL.lastPathComponent];
            if(![fm fileExistsAtPath:destfile]) {
                ASSERT([fm createSymbolicLinkAtPath:destfile withDestinationPath:fileURL.path error:nil]);
            }
        }

        NSString* entitlementsFileInBundlePath = [NSString stringWithFormat:@"basebin/entitlements/executables/%@.extra", sourcePath.lastPathComponent];
        NSString* entitlementsFilePath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:entitlementsFileInBundlePath];
        if([fm fileExistsAtPath:entitlementsFilePath]) {
            ASSERT(spawnRoot(ldidPath, @[@"-M", [NSString stringWithFormat:@"-S%@", entitlementsFilePath], destPath], nil, nil) == 0);
        } else {
            STRAPLOG("Entitlements File %@ Not Found!!!", entitlementsFileInBundlePath);
            return -1;
        }
        
        ASSERT(spawnRoot(fastSignPath, @[destPath], nil, nil) == 0);
    }
    
    ASSERT(spawnRoot(jbroot(@"/basebin/TaskPortHaxx"), @[execDir], nil, nil) == 0);
    
    ASSERT(spawnRoot(jbroot(@"/basebin/bsctl"), @[@"usreboot"], nil, nil) == 0);
    
    return 0;
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
    
    NSString* launchdpath = getLaunchdPath();
    if(![launchdpath isEqualToString:@"/sbin/launchd"] && ![launchdpath hasSuffix:@"/.sysroot/sbin/launchd"])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Error") message:Localized(@"Please reboot device first.") preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Reboot Device") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            ASSERT(spawnRoot(NSBundle.mainBundle.executablePath, @[@"reboot"], nil, nil)==0);
        }]];

        [AppDelegate showAlert:alert];
        return;
    }

    UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
    [generator impactOccurred];

    int installedCount=0;
    NSString* dirpath = @"/var/containers/Bundle/Application/";
    NSArray *subItems = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dirpath error:nil];
    for (NSString *subItem in subItems)
    {
        if (!is_jbroot_name(subItem.UTF8String)) continue;
        
        NSString* jbroot_path = [dirpath stringByAppendingPathComponent:subItem];
        
        if([NSFileManager.defaultManager fileExistsAtPath:[jbroot_path stringByAppendingPathComponent:@"/.installed_dopamine"]]) {
            [AppDelegate showMesage:Localized(@"roothide dopamine has been installed on this device, now install this bootstrap may break it!") title:Localized(@"Error")];
            return;
        }
        
        if([NSFileManager.defaultManager fileExistsAtPath:[jbroot_path stringByAppendingPathComponent:@"/.bootstrapped"]]
           || [NSFileManager.defaultManager fileExistsAtPath:[jbroot_path stringByAppendingPathComponent:@"/.thebootstrapped"]]) {
            installedCount++;
            continue;
        }
    }

    if(installedCount > 1) {
        [AppDelegate showMesage:Localized(@"There are multi jbroot in /var/containers/Bundle/Applicaton/") title:Localized(@"Error")];
        return;
    }

    if(find_jbroot(YES)) //make sure jbroot() function available
    {
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
        setIdleTimerDisabled(YES);

        const char* argv[] = {NSBundle.mainBundle.executablePath.fileSystemRepresentation, "bootstrap", NULL};
        int status = spawn(argv[0], argv, environ, nil, ^(char* outstr, int length) {
            NSString *str = [[NSString alloc] initWithBytes:outstr length:length encoding:NSASCIIStringEncoding];
            [AppDelegate addLogText:str];
        }, ^(char* errstr, int length){
            NSString *str = [[NSString alloc] initWithBytes:errstr length:length encoding:NSASCIIStringEncoding];
            [AppDelegate addLogText:[NSString stringWithFormat:@"ERR: %@\n",str]];
        });

        if(status != 0)
        {
            [AppDelegate showMesage:@"" title:[NSString stringWithFormat:@"code(%d)",status]];
            return;
        }

        NSString* log=nil;
        NSString* err=nil;

        tryLoadOpenSSH();

        if(gTweakEnabled && ![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/mobile/.tweakenabled")]) {
            ASSERT([[NSString new] writeToFile:jbroot(@"/var/mobile/.tweakenabled") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
        }
        
        if(![NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/var/mobile/.preferences_tweak_inited")])
        {
            [AppDelegate addLogText:Localized(@"Enable Tweak Injection for com.apple.Preferences")];
            
            NSString* log=nil;
            NSString* err=nil;
            status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"enableapp",@"/Applications/Preferences.app"], &log, &err);
            
            if(status == 0) {
                ASSERT([[NSString new] writeToFile:jbroot(@"/var/mobile/.preferences_tweak_inited") atomically:YES encoding:NSUTF8StringEncoding error:nil]);
            } else {
                [AppDelegate showMesage:[NSString stringWithFormat:@"%@\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"error(%d)",status]];
                return;
            }
        }

        if(@available(iOS 16.0, *))
        {
            [AppDelegate addLogText:Localized(@"exploit...")];
            
            NSString* execDir = [@"/var/db/com.apple.xpc.roleaccountd.staging/exec-" stringByAppendingString:[[NSUUID UUID] UUIDString]];
                
            @try {
                ASSERT(spawnRoot(jbroot(@"/basebin/TaskPortHaxx"), @[@"prepare", execDir], nil, nil) == 0);
                
                int load_trust_cache(NSString *tcPath);
                ASSERT(load_trust_cache(jbroot(@"/tmp/TaskPortHaxx/UpdateBrainService/AssetData/.TrustCache")) == 0);
            }
            @catch (NSException *exception)
            {
                [AppDelegate showMesage:[NSString stringWithFormat:@"***exception: %@", exception] title:@"ERROR"];
                return;
            }
            
            const char* argv2[] = {NSBundle.mainBundle.executablePath.fileSystemRepresentation, "exploit", execDir.fileSystemRepresentation, NULL};
            status = spawn(argv2[0], argv2, environ, nil, ^(char* outstr, int length) {
                NSString *str = [[NSString alloc] initWithBytes:outstr length:length encoding:NSASCIIStringEncoding];
                [AppDelegate addLogText:str];
            }, ^(char* errstr, int length){
                NSString *str = [[NSString alloc] initWithBytes:errstr length:length encoding:NSASCIIStringEncoding];
                [AppDelegate addLogText:[NSString stringWithFormat:@"ERR: %@\n",str]];
            });
            if(status!=0) {
                [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
                return;
            }
            
            return;
        }
        
        setIdleTimerDisabled(NO);
        [AppDelegate dismissHud];
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
            setIdleTimerDisabled(YES);

            NSString* log=nil;
            NSString* err=nil;
            int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);

            [AppDelegate dismissHud];
            setIdleTimerDisabled(NO);

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

int hideBootstrapApp(BOOL usreboot)
{
    if(![LSApplicationWorkspace.defaultWorkspace unregisterApplication:NSBundle.mainBundle.bundleURL]) {
        return -1;
    }
    
    if(usreboot)
    {
        sleep(2);
        
        int status = spawnRoot(jbroot(@"/basebin/bsctl"), @[@"usreboot"], nil, nil);
        if(status != 0) {
            return -2;
        }
    }
    
    return 0;
}

void hideAllCTBugAppsAction(BOOL usreboot)
{
    [AppDelegate showHudMsg:Localized(@"Hiding All Jailbreak/TrollStore Apps...")];
    
    NSArray* allInstalledApplications = [LSApplicationWorkspace.defaultWorkspace allInstalledApplications];
    
    BOOL TSHelperFound = NO;
    for(LSApplicationProxy* proxy in allInstalledApplications) {
        NSString* TSHelperMarker = [proxy.bundleURL.path stringByAppendingPathComponent:@".TrollStorePersistenceHelper"];
        if([NSFileManager.defaultManager fileExistsAtPath:TSHelperMarker]) {
            TSHelperFound = YES;
            break;
        }
    }
    
    if(!TSHelperFound) {
        [AppDelegate dismissHud];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Error") message:Localized(@"You haven't installed TrollStore Helper yet, please install it in TrollStore->Settings first.") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:nil]];
        [AppDelegate showAlert:alert];
        
        return;
    }
    
    for(LSApplicationProxy* proxy in allInstalledApplications)
    {
        NSString* appPath = proxy.bundleURL.path;
        
        if([proxy.bundleIdentifier isEqualToString:NSBundle.mainBundle.bundleIdentifier]) {
            continue;
        }
        
        struct statfs fsb={0};
        statfs(appPath.fileSystemRepresentation, &fsb);
        if(strcmp(fsb.f_mntonname, "/") == 0) {
            continue;
        }
        
        if(isRemovableBundlePath(appPath.fileSystemRepresentation) && !hasTrollstoreMarker(appPath.fileSystemRepresentation)) {
            continue;
        }
        
        if([proxy.bundleIdentifier hasPrefix:@"com.apple."] && [NSFileManager.defaultManager fileExistsAtPath:[@"/Applications" stringByAppendingPathComponent:appPath.lastPathComponent]]) {
            continue;
        }
            

        if(![LSApplicationWorkspace.defaultWorkspace unregisterApplication:proxy.bundleURL]) {
            [AppDelegate dismissHud];

            NSString* msg = [NSString stringWithFormat:Localized(@"Failed to Hide %@ : %@"),proxy.bundleIdentifier,proxy.bundleURL.path];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:nil]];
            [AppDelegate showAlert:alert];

            return;
        }
    }
    
    [[NSString stringWithFormat:@"%llX",jbrand()] writeToFile:jbroot(@"/var/mobile/.allctbugappshidden") atomically:YES encoding:NSUTF8StringEncoding error:nil];

    sleep(1);

    NSString* log=nil;
    NSString* err=nil;
    int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"hidebootstrapapp",usreboot?@"usreboot":@""], &log, &err);
    if(status != 0) {
        NSString* msg = [NSString stringWithFormat:@"code(%d)\n%@\n\nstderr:\n%@",status,log,err];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:nil]];
        [AppDelegate showAlert:alert];

        return;
    }

}

void hideAllCTBugApps()
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Warning") message:Localized(@"This operation will make all apps installed via TrollStore/Bootstrap disappear from the Home Screen. You can restore them later via TrollStore Helper->[Refresh App Registrations] and Bootstrap->Settings->[Unhide Jailbreak Apps]") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Hide") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            hideAllCTBugAppsAction(NO);
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Hide & Reboot Userspace") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            hideAllCTBugAppsAction(YES);
        });
    }]];
    [AppDelegate showAlert:alert];
}

void unhideAllCTBugApps()
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Restore Jailbreak Apps...")];
        
        NSString* log=nil;
        NSString* err=nil;
        int status = spawnBootstrap((char*[]){"/usr/bin/uicache","-a",NULL}, &log, &err);
        
        [AppDelegate dismissHud];
        
        NSString* msg = (status==0) ? Localized(@"Done") : [NSString stringWithFormat:@"code(%d)\n%@\n\nstderr:\n%@",status,log,err];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:nil]];
        [AppDelegate showAlert:alert];
        
        [NSFileManager.defaultManager removeItemAtPath:jbroot(@"/var/mobile/.allctbugappshidden") error:nil];
        
        [NSNotificationCenter.defaultCenter postNotificationName:@"unhideAllCTBugAppsNotification" object:nil];
    });
}

BOOL isAllCTBugAppsHidden()
{
    if(!isBootstrapInstalled() || !isSystemBootstrapped()) {
        return NO;
    }
    
    NSString* flag = [NSString stringWithContentsOfFile:jbroot(@"/var/mobile/.allctbugappshidden") encoding:NSUTF8StringEncoding error:nil];
    return flag && [flag isEqualToString:[NSString stringWithFormat:@"%llX",jbrand()]];
}
