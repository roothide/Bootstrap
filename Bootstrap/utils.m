#include <spawn.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include <Security/SecKey.h>
#include <Security/Security.h>
#include "common.h"

uint64_t jbrand_new()
{
    uint64_t value = ((uint64_t)arc4random()) | ((uint64_t)arc4random())<<32;
    uint8_t check = value>>8 ^ value >> 16 ^ value>>24 ^ value>>32 ^ value>>40 ^ value>>48 ^ value>>56;
    return (value & ~0xFF) | check;
}

int is_jbrand_value(uint64_t value)
{
   uint8_t check = value>>8 ^ value >> 16 ^ value>>24 ^ value>>32 ^ value>>40 ^ value>>48 ^ value>>56;
   return check == (uint8_t)value;
}

#define JB_ROOT_PREFIX ".jbroot-"
#define JB_RAND_LENGTH  (sizeof(uint64_t)*sizeof(char)*2)

int is_jbroot_name(const char* name)
{
    if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
        return 0;
    
    if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
        return 0;
    
    char* endp=NULL;
    uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
    if(!endp || *endp!='\0')
        return 0;
    
    if(!is_jbrand_value(value))
        return 0;
    
    return 1;
}

uint64_t resolve_jbrand_value(const char* name)
{
    if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
        return 0;
    
    if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
        return 0;
    
    char* endp=NULL;
    uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
    if(!endp || *endp!='\0')
        return 0;
    
    if(!is_jbrand_value(value))
        return 0;
    
    return value;
}

NSString* find_jbroot(BOOL force)
{
    static NSString* cached_jbroot = nil;
    if(!force && cached_jbroot) {
        return cached_jbroot;
    }
    @synchronized(@"find_jbroot_lock")
    {
        //jbroot path may change when re-randomize it
        NSString * jbroot = nil;
        NSArray *subItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application/" error:nil];
        for (NSString *subItem in subItems) {
            if (is_jbroot_name(subItem.UTF8String))
            {
                NSString* path = [@"/var/containers/Bundle/Application/" stringByAppendingPathComponent:subItem];
                    
                jbroot = path;
                break;
            }
        }
        cached_jbroot = jbroot;
    }
    return cached_jbroot;
}

const char* jbroot(const char* path)
{
    NSString* jbroot = find_jbroot(NO);
    ASSERT(jbroot != NULL);
    NSString* newpath = [jbroot stringByAppendingPathComponent:@(path)];
    
    @synchronized(@"jbroot_cache_lock")
    {
        static NSMutableSet* cache = nil;
        if(!cache) cache = [NSMutableSet new];
        
        [cache addObject:newpath];
        newpath = [cache member:newpath];
    }
    return newpath.fileSystemRepresentation;
}

NSString* __attribute__((overloadable)) jbroot(NSString *path)
{
    NSString* jbroot = find_jbroot(NO);
    ASSERT(jbroot != NULL); //to avoid [nil stringByAppendingString:
    return [jbroot stringByAppendingPathComponent:path];
}

uint64_t jbrand()
{
    NSString* jbroot = find_jbroot(NO);
    ASSERT(jbroot != NULL);
    return resolve_jbrand_value([jbroot lastPathComponent].UTF8String);
}

NSString* rootfsPrefix(NSString* path)
{
    return [@"/rootfs/" stringByAppendingPathComponent:path];
}

NSString* getBootSession()
{
    const size_t maxUUIDLength = 37;
    char uuid[maxUUIDLength]={0};
    size_t uuidLength = maxUUIDLength;
    sysctlbyname("kern.bootsessionuuid", uuid, &uuidLength, NULL, 0);
    
    return @(uuid);
}

typedef struct CF_BRIDGED_TYPE(id) __SecCode const* SecStaticCodeRef; /* code on disk */
typedef enum { kSecCSDefaultFlags=0, kSecCSSigningInformation = 1 << 1 } SecCSFlags;
OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef* CF_RETURNS_RETAINED staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef* __nonnull CF_RETURNS_RETAINED information);

SecStaticCodeRef getStaticCodeRef(NSString *binaryPath) {
    if (binaryPath == nil) {
        return NULL;
    }
    
    CFURLRef binaryURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)binaryPath, kCFURLPOSIXPathStyle, false);
    if (binaryURL == NULL) {
        return NULL;
    }
    
    SecStaticCodeRef codeRef = NULL;
    OSStatus result;
    
    result = SecStaticCodeCreateWithPathAndAttributes(binaryURL, kSecCSDefaultFlags, NULL, &codeRef);
    
    CFRelease(binaryURL);
    
    if (result != errSecSuccess) {
        return NULL;
    }
        
    return codeRef;
}

NSString* getTeamIDFromBinaryAtPath(NSString *binaryPath)
{
    SecStaticCodeRef codeRef = getStaticCodeRef(binaryPath);
    if(codeRef == NULL) {
        return nil;
    }
    
    CFDictionaryRef signingInfo = NULL;
    OSStatus result = SecCodeCopySigningInformation(codeRef, kSecCSSigningInformation, &signingInfo);
    if(result != errSecSuccess) return nil;
        
    NSString* teamID = (NSString*)CFDictionaryGetValue(signingInfo, CFSTR("teamid"));
    
    CFRelease(signingInfo);
    CFRelease(codeRef);
    
    return teamID;
}

