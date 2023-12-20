
//oh shit why NSLog also output to stderr
//luckly syslog also accept NSObject

#include <sys/syslog.h>

#define NSLog #error#

#define SYSLOG(...) do {openlog("bootstrap",LOG_PID,LOG_AUTH);syslog(LOG_DEBUG, __VA_ARGS__);closelog();} while(0)

#define STRAPLOG(...) do {SYSLOG(__VA_ARGS__); fprintf(stdout, __VA_ARGS__); fprintf(stdout, "\n");} while(0)
