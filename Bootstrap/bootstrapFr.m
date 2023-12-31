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
        [AppDelegate showMesage:Localized(@"Your trollstore version is too old, Bootstrap only supports trollstore>=2.0") title:Localized(@"Error")];
        return;
    }
    
    if(spawnRoot([NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"basebin/devtest"], nil, nil, nil) != 0) {
        [AppDelegate showMesage:Localized(@"Your device does not seem to have developer mode enabled.\n\nPlease enable developer mode in Settings->[Privacy&Security] and reboot your device.") title:Localized(@"Error")];
        return;
    }
    
    UIImpactFeedbackGenerator* generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleSoft];
    generator.impactOccurred;
    
    if(find_jbroot()) //make sure jbroot() function available
    {
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot(@"/.installed_dopamine")]) {
            [AppDelegate showMesage:Localized(@"roothide dopamine has been installed on this device, now install this bootstrap may break it!") title:Localized(@"Error")];
            return;
        }
        
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
                [AppDelegate addLogText:@"openssh launch successful"];
            else
                [AppDelegate addLogText:[NSString stringWithFormat:@"openssh launch faild(%d):\n%@\n%@", status, log, err]];
        }
        
        [AppDelegate addLogText:@"respring now..."]; sleep(1);
        
        status = spawnBootstrap((char*[]){"/usr/bin/sbreload", NULL}, &log, &err);
        if(status!=0) [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        
    });
}

void unbootstrapFr(void) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Warnning") message:Localized(@"Are you sure to uninstall bootstrap?\n\nPlease make sure you have disabled tweak for all apps before uninstalling.") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Uninstall") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [AppDelegate showHudMsg:Localized(@"Uninstalling")];
            
            NSString* log=nil;
            NSString* err=nil;
            int status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"unbootstrap"], &log, &err);
            
            [AppDelegate dismissHud];
            
            if(status == 0) {
                [AppDelegate showMesage:@"" title:@"bootstrap uninstalled"];
            } else {
                [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
            }
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

void rebuildappsFr(void) {
    STRAPLOG("Status: Rebuilding Apps");
    
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
