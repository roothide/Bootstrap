#include <spawn.h>
#include <sys/sysctl.h>
#include <mach-o/fat.h>
#include <mach-o/loader.h>
#include "envbuf.h"
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


NSString* find_jbroot()
{
    //jbroot path may change when re-randomize it
    NSString * jbroot = nil;
    NSArray *subItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application/" error:nil];
    for (NSString *subItem in subItems) {
        if (is_jbroot_name(subItem.UTF8String))
        {
            NSString* path = [@"/var/containers/Bundle/Application/" stringByAppendingPathComponent:subItem];
            
//            if([NSFileManager.defaultManager fileExistsAtPath:
//                 [path stringByAppendingPathComponent:@".installed_dopamine"]])
//                continue;
                
            jbroot = path;
            break;
        }
    }
    return jbroot;
}

NSString *jbroot(NSString *path)
{
    NSString* jbroot = find_jbroot();
    ASSERT(jbroot != NULL); //to avoid [nil stringByAppendingString:
    return [jbroot stringByAppendingPathComponent:path];
}

uint64_t jbrand()
{
    NSString* jbroot = find_jbroot();
    ASSERT(jbroot != NULL);
    return resolve_jbrand_value([jbroot lastPathComponent].UTF8String);
}

NSString* rootfsPrefix(NSString* path)
{
    return [@"/rootfs/" stringByAppendingPathComponent:path];
}

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

int spawn(const char* path, const char** argv, const char** envp, void(^std_out)(char*,int), void(^std_err)(char*,int))
{
    SYSLOG("spawn %s", path);
    
    __block pid_t pid=0;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);

    int outPipe[2];
    pipe(outPipe);
    posix_spawn_file_actions_addclose(&action, outPipe[0]);
    posix_spawn_file_actions_adddup2(&action, outPipe[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&action, outPipe[1]);
    
    int errPipe[2];
    pipe(errPipe);
    posix_spawn_file_actions_addclose(&action, errPipe[0]);
    posix_spawn_file_actions_adddup2(&action, errPipe[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&action, errPipe[1]);

    
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    
    dispatch_queue_t queue = dispatch_queue_create("spawnPipeQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_source_t stdOutSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, outPipe[0], 0, queue);
    dispatch_source_t stdErrSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, errPipe[0], 0, queue);
    
    int outFD = outPipe[0];
    int errFD = errPipe[0];
    
    dispatch_source_set_cancel_handler(stdOutSource, ^{
        close(outFD);
        dispatch_semaphore_signal(lock);
        SYSLOG("stdout canceled [%d]", pid);
    });
    dispatch_source_set_cancel_handler(stdErrSource, ^{
        close(errFD);
        dispatch_semaphore_signal(lock);
        SYSLOG("stderr canceled [%d]", pid);
    });
    
    dispatch_source_set_event_handler(stdOutSource, ^{
        char buffer[BUFSIZ]={0};
        ssize_t bytes = read(outFD, buffer, sizeof(buffer)-1);
        if (bytes <= 0) {
            dispatch_source_cancel(stdOutSource);
            return;
        }
        SYSLOG("spawn[%d] stdout: %s", pid, buffer);
        if(std_out) std_out(buffer,bytes);
    });
    dispatch_source_set_event_handler(stdErrSource, ^{
        char buffer[BUFSIZ]={0};
        ssize_t bytes = read(errFD, buffer, sizeof(buffer)-1);
        if (bytes <= 0) {
            dispatch_source_cancel(stdErrSource);
            return;
        }
        SYSLOG("spawn[%d] stderr: %s", pid, buffer);
        if(std_err) std_err(buffer,bytes);
    });
    
    dispatch_resume(stdOutSource);
    dispatch_resume(stdErrSource);
    
    int spawnError = posix_spawn(&pid, path, &action, &attr, argv, envp);
    SYSLOG("spawn ret=%d, pid=%d", spawnError, pid);
    
    posix_spawnattr_destroy(&attr);
    posix_spawn_file_actions_destroy(&action);
    
    close(outPipe[1]);
    close(errPipe[1]);
    
    if(spawnError != 0)
    {
        SYSLOG("posix_spawn error %d:%s\n", spawnError, strerror(spawnError));
        dispatch_source_cancel(stdOutSource);
        dispatch_source_cancel(stdErrSource);
        return spawnError;
    }
    
    //wait stdout
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    //wait stderr
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    
    int status=0;
    while(waitpid(pid, &status, 0) != -1)
    {
        if (WIFSIGNALED(status)) {
            return 128 + WTERMSIG(status);
        } else if (WIFEXITED(status)) {
            return WEXITSTATUS(status);
        }
        //keep waiting?return status;
    };
    return -1;
}

int spawnBootstrap(const char** argv, NSString** stdOut, NSString** stdErr)
{
    NSMutableArray* argArr = [[NSMutableArray alloc] init];
    for(int i=1; argv[i]; i++) [argArr addObject:[NSString stringWithUTF8String:argv[i]]];
    SYSLOG("spawnBootstrap %s with %@", argv[0], argArr);
    
    char **envc = envbuf_mutcopy(environ);
    
    envbuf_setenv(&envc, "DYLD_INSERT_LIBRARIES", jbroot(@"/basebin/bootstrap.dylib").fileSystemRepresentation, 1);
    
    
    __block NSMutableString* outString=nil;
    __block NSMutableString* errString=nil;
    
    if(stdOut) outString = [NSMutableString new];
    if(stdErr) errString = [NSMutableString new];
    
    
    int retval = spawn(jbroot(@(argv[0])).fileSystemRepresentation, argv, envc, ^(char* outstr, int length){
        NSString *str = [[NSString alloc] initWithBytes:outstr length:length encoding:NSASCIIStringEncoding];
        if(stdOut) [outString appendString:str];
    }, ^(char* errstr, int length){
        NSString *str = [[NSString alloc] initWithBytes:errstr length:length encoding:NSASCIIStringEncoding];
        if(stdErr) [errString appendString:str];
    });
    
    if(stdOut) *stdOut = outString.copy;
    if(stdErr) *stdErr = errString.copy;
    
    envbuf_free(envc);
    
    return retval;
}

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr)
{
    SYSLOG("spawnRoot %@ with %@", path, args);
    
    NSMutableArray* argsM = args.mutableCopy ?: [NSMutableArray new];
    [argsM insertObject:path atIndex:0];
    
    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;

    
    __block NSMutableString* outString=nil;
    __block NSMutableString* errString=nil;
    
    if(stdOut) outString = [NSMutableString new];
    if(stdErr) errString = [NSMutableString new];
    
    int retval = spawn(path.fileSystemRepresentation, argsC, environ, ^(char* outstr, int length){
        NSString *str = [[NSString alloc] initWithBytes:outstr length:length encoding:NSASCIIStringEncoding];
        if(stdOut) [outString appendString:str];
    }, ^(char* errstr, int length){
        NSString *str = [[NSString alloc] initWithBytes:errstr length:length encoding:NSASCIIStringEncoding];
        if(stdErr) [errString appendString:str];
    });
    
    if(stdOut) *stdOut = outString.copy;
    if(stdErr) *stdErr = errString.copy;
    
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);
    
    return retval;
}

void machoEnumerateArchs(FILE* machoFile, bool (^archEnumBlock)(struct mach_header_64* header, uint32_t offset))
{
    struct mach_header_64 mh={0};
    if(fseek(machoFile,0,SEEK_SET)!=0)return;
    if(fread(&mh,sizeof(mh),1,machoFile)!=1)return;
    
    if(mh.magic==FAT_MAGIC || mh.magic==FAT_CIGAM)//and || mh.magic==FAT_MAGIC_64 || mh.magic==FAT_CIGAM_64? with fat_arch_64
    {
        struct fat_header fh={0};
        if(fseek(machoFile,0,SEEK_SET)!=0)return;
        if(fread(&fh,sizeof(fh),1,machoFile)!=1)return;
        
        for(int i = 0; i < OSSwapBigToHostInt32(fh.nfat_arch); i++)
        {
            uint32_t archMetadataOffset = sizeof(fh) + sizeof(struct fat_arch) * i;

            struct fat_arch fatArch={0};
            if(fseek(machoFile, archMetadataOffset, SEEK_SET)!=0)break;
            if(fread(&fatArch, sizeof(fatArch), 1, machoFile)!=1)break;

            if(fseek(machoFile, OSSwapBigToHostInt32(fatArch.offset), SEEK_SET)!=0)break;
            if(fread(&mh, sizeof(mh), 1, machoFile)!=1)break;

            if(mh.magic != MH_MAGIC_64 && mh.magic != MH_CIGAM_64) continue; //require Macho64
            
            if(!archEnumBlock(&mh, OSSwapBigToHostInt32(fatArch.offset)))
                break;
        }
    }
    else if(mh.magic == MH_MAGIC_64 || mh.magic == MH_CIGAM_64) //require Macho64
    {
        archEnumBlock(&mh, 0);
    }
}

void machoGetInfo(FILE* candidateFile, bool *isMachoOut, bool *isLibraryOut)
{
    if (!candidateFile) return;

    __block bool isMacho=false;
    __block bool isLibrary = false;
    
    machoEnumerateArchs(candidateFile, ^bool(struct mach_header_64* header, uint32_t offset) {
        switch(OSSwapLittleToHostInt32(header->filetype)) {
            case MH_DYLIB:
            case MH_BUNDLE:
                isLibrary = true;
            case MH_EXECUTE:
                isMacho = true;
                return false;

            default:
                return true;
        }
    });

    if (isMachoOut) *isMachoOut = isMacho;
    if (isLibraryOut) *isLibraryOut = isLibrary;
}

#define APP_PATH_PREFIX "/private/var/containers/Bundle/Application/"

BOOL isDefaultInstallationPath(NSString* _path)
{
    if(!_path) return NO;

    const char* path = _path.UTF8String;
    
    char rp[PATH_MAX];
    if(!realpath(path, rp)) return NO;

    if(strncmp(rp, APP_PATH_PREFIX, sizeof(APP_PATH_PREFIX)-1) != 0)
        return NO;

    char* p1 = rp + sizeof(APP_PATH_PREFIX)-1;
    char* p2 = strchr(p1, '/');
    if(!p2) return NO;

    //is normal app or jailbroken app/daemon?
    if((p2 - p1) != (sizeof("xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx")-1))
        return NO;

    return YES;
}

void killAllForApp(const char* bundlePath)
{
    SYSLOG("killBundleForPath: %s", bundlePath);
    
    char realBundlePath[PATH_MAX];
    if(!realpath(bundlePath, realBundlePath))
        return;
    
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            perror("sysctl argument size");
            maxArgumentSize = 4096; // Default
        }
    }
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    size_t count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return;
    if (!(info = malloc(length)))
        return;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return;
    }
    count = length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char* buffer = (char *)malloc(length);
        if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
            char *executablePath = buffer + sizeof(int);
            //SYSLOG("executablePath [%d] %s", pid, executablePath);
            char realExecutablePath[PATH_MAX];
            if (realpath(executablePath, realExecutablePath)
                && strncmp(realExecutablePath, realBundlePath, strlen(realBundlePath)) == 0) {
                kill(pid, SIGKILL);
            }
        }
        free(buffer);
    }
    free(info);
}


NSString* getBootSession()
{
    const size_t maxUUIDLength = 37;
    char uuid[maxUUIDLength]={0};
    size_t uuidLength = maxUUIDLength;
    sysctlbyname("kern.bootsessionuuid", uuid, &uuidLength, NULL, 0);
    
    return @(uuid);
}
