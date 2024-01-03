
//oh shit why NSLog also output to stderr
//luckly syslog also accept NSObject

#include <sys/syslog.h>

#define NSLog #error#

#define SYSLOG(fmt, ...) do { fmt[0];\
openlog("bootstrap",LOG_PID,LOG_AUTH);\
syslog(LOG_DEBUG, fmt, ## __VA_ARGS__);\
closelog();\
} while(0)

#define STRAPLOG(fmt, ...) do { fmt[0];\
SYSLOG(fmt, ## __VA_ARGS__);\
fprintf(stdout, [NSString stringWithFormat:@fmt, ## __VA_ARGS__].UTF8String);\
fprintf(stdout, "\n");\
fflush(stdout);\
} while(0)
