//
//  bootstrapFr.m
//  Bootstrap
//
//  Created by haxi0 on 31.12.2023.
//

#include "NSUserDefaults+appDefaults.h"
#include "common.h"
#include "AppDelegate.h"
#include "AppViewController.h"
#include "bootstrap.h"
#import <sys/sysctl.h>
#include <sys/utsname.h>
#import "Bootstrap-Swift.h"
#include "AppList.h"

#include <Security/SecKey.h>
#include <Security/Security.h>
typedef struct CF_BRIDGED_TYPE(id) __SecCode const* SecStaticCodeRef; /* code on disk */
typedef enum { kSecCSDefaultFlags=0, kSecCSSigningInformation = 1 << 1 } SecCSFlags;
OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef* CF_RETURNS_RETAINED staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef* __nonnull CF_RETURNS_RETAINED information);

bool checkTSVersionFr(void) {
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

void bootstrapFr(void) {
    if(!checkTSVersionFr()) {
        [AppDelegate showMesage:NSLocalizedString(@"Your trollstore version is too old, Bootstrap only supports trollstore>=2.0", nil) title:NSLocalizedString(@"Error", nil)];
        return;
    }
    
    if(spawnRoot([NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/devtest"], nil, nil, nil) != 0) {
        [AppDelegate showMesage:NSLocalizedString(@"Your device does not seem to have developer mode enabled.\n\nPlease enable developer mode in Settings > Privacy & Security and reboot your device.", nil) title:NSLocalizedString(@"Error", nil)];
        return;
    }
    
    UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
    generator.impactOccurred;
    
    if(find_jbroot()) //make sure jbroot() function available
    {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.installed_dopamine")]) {
            [AppDelegate showMesage:NSLocalizedString(@"RootHide Dopamine has been installed on this device, now install this bootstrap may break it!", nil) title:NSLocalizedString(@"Error", nil)];
            return;
        }
        
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.bootstrapped")]) {
            NSString* strappedVersion = [NSString stringWithContentsOfFile:jbroot(@"/.bootstrapped") encoding:NSUTF8StringEncoding error:nil];
            if(strappedVersion.intValue != BOOTSTRAP_VERSION) {
                [AppDelegate showMesage:NSLocalizedString(@"You have installed an old beta version, please disable all app tweaks and reboot the device to uninstall it so that you can install the new version bootstrap.", nil) title:NSLocalizedString(@"Error", nil)];
                return;
            }
        }
    }
    
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
                [AppDelegate addLogText:NSLocalizedString(@"openssh launch successful", nil)];
            else
                [AppDelegate addLogText:[NSString stringWithFormat:NSLocalizedString(@"openssh launch faild(%d):\n%@\n%@", nil), status, log, err]];
        }
        
        [AppDelegate addLogText:NSLocalizedString(@"respring now...", nil)]; sleep(1);
        
        status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
        if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        
    });
}

void unbootstrapFr(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warnning", nil) message:NSLocalizedString(@"Are you sure to uninstall bootstrap?\n\nPlease make sure you have disabled tweak for all apps before uninstalling.", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Uninstall", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [AppDelegate showHudMsg:NSLocalizedString(@"Uninstalling", nil)];
            
            NSString* log=nil;
            NSString* err=nil;
            int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);
                
            [AppDelegate dismissHud];
            
            NSString* msg = (status==0) ? @"bootstrap uninstalled" : [NSString stringWithFormat:@"code(%d)\n%@\n\nstderr:\n%@",status,log,err];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                exit(0);
            }]];
            
            [AppDelegate showAlert:alert];
            
        });
        
    }]];
    [AppDelegate showAlert:alert];
}

void respringFr(void) {
    NSString* log=nil;
    NSString* err=nil;
    int status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
    if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
}

void rebootFr(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warnning", nil) message:NSLocalizedString(@"Are you sure to reboot device?", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *log = nil;
            NSString *err = nil;
            int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"reboot"], &log, &err);
            if (status != 0) {
                [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@", log, err] title:[NSString stringWithFormat:@"code(%d)", status]];
            }
        });
    }]];
    [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
}

void rebuildappsFr(void) {
    [AppDelegate addLogText:@"状态：正在重建应用程序"];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:NSLocalizedString(@"Applying", nil)];
        
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

void rebuildIconCacheFr(void) {
    [AppDelegate addLogText:NSLocalizedString(@"Status: Rebuilding Icon Cache", nil)];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:NSLocalizedString(@"Rebuilding", nil) detail:NSLocalizedString(@"Don't exit Bootstrap app until show the lock screen.", nil)];
        
        NSString* log=nil;
        NSString* err=nil;
        int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"rebuildiconcache"], &log, &err);
        if(status != 0) {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        }
        
        [AppDelegate dismissHud];
    });
}

void checkServerFr(void) {
    static bool alerted = false;
    if(alerted) return;
    
    if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"check"], nil, nil) != 0)
    {
        alerted = true;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Server Not Running", nil) message:NSLocalizedString(@"For unknown reasons the bootstrap server is not running, the only thing we can do is to restart it now.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Restart Server", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            
            alerted = false;
            
            NSString* log=nil;
            NSString* err=nil;
            if(spawnRoot(jbroot(@"/basebin/bootstrapd"), @[@"daemon",@"-f"], &log, &err)==0) {
                [AppDelegate addLogText:NSLocalizedString(@"bootstrap server restart successful", nil)];
                //[self updateOpensshStatus];
            } else {
                [AppDelegate showMesage:[NSString stringWithFormat:@"%@\nERR:%@"] title:NSLocalizedString(@"Error", nil)];
            }
            
        }]];
        
        [AppDelegate showAlert:alert];
    } else {
        [AppDelegate addLogText:NSLocalizedString(@"bootstrap server check successful", nil)];
        //[self updateOpensshStatus];
    }
}

void reinstallPackageManagerFr(void) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:NSLocalizedString(@"Applying", nil)];
        
        NSString* log=nil;
        NSString* err=nil;
        
        BOOL success=YES;
        
        [AppDelegate addLogText:NSLocalizedString(@"Status: Reinstalling Sileo", nil)];
        NSString* sileoDeb = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"sileo.deb"];
        if(spawnBootstrap((char*[]){"/usr/bin/dpkg", "-i", rootfsPrefix(sileoDeb).fileSystemRepresentation, NULL}, &log, &err) != 0) {
            [AppDelegate addLogText:[NSString stringWithFormat:@"failed:%@\nERR:%@", log, err]];
            success = NO;
        }
        
        if(spawnBootstrap((char*[]){"/usr/bin/uicache", "-p", "/Applications/Sileo.app", NULL}, &log, &err) != 0) {
            [AppDelegate addLogText:[NSString stringWithFormat:@"failed:%@\nERR:%@", log, err]];
            success = NO;
        }
        
        if(success) {
            [AppDelegate showMesage:NSLocalizedString(@"Sileo reinstalled!", nil) title:@""];
        }
        [AppDelegate dismissHud];
    });
}
