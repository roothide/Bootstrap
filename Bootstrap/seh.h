#ifndef seh_h
#define seh_h

#undef abort
#define abort   #error#

#define ABORT()  do {\
@throw [NSException\
        exceptionWithName:@"ABORT"\
        reason:[NSString stringWithFormat:@"%s (%d)", __FILE_NAME__, __LINE__]\
        userInfo:nil];\
} while(0)

#undef assert
#define assert   #error#

#define ASSERT(...)  do{if(!(__VA_ARGS__)) {\
@throw [NSException\
        exceptionWithName:@"ASSERT"\
        reason:[NSString stringWithFormat:@"%s (%d): %s", __FILE_NAME__, __LINE__, #__VA_ARGS__]\
        userInfo:nil];\
}} while(0)

#endif /* seh_h */
