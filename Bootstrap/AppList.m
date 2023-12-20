// https://github.com/wujianguo/iOSAppsInfo
// modified by Shadow-

#import "AppList.h"
#import <dlfcn.h>

@interface UIImage ()
+ (id)_iconForResourceProxy:(id)arg1 variant:(int)arg2 variantsScale:(float)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(double)arg3;
@end

#pragma mark -

@interface PrivateApi_LSApplicationProxy

+ (instancetype)applicationProxyForIdentifier:(NSString*)identifier;
@property (nonatomic, readonly) NSString* localizedShortName;
@property (nonatomic, readonly) NSString* localizedName;
@property (nonatomic, readonly) NSString* bundleIdentifier;
@property (nonatomic, readonly) NSArray* appTags;

@property (nonatomic, readonly) NSString *applicationDSID;
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSString *applicationType;
@property (nonatomic, readonly) NSNumber *dynamicDiskUsage;
@property (nonatomic, readonly) NSURL *bundleURL;
@property (nonatomic, readonly) NSURL *containerURL;

@property (nonatomic, readonly) NSArray *groupIdentifiers;
@property (nonatomic, readonly) NSNumber *itemID;
@property (nonatomic, readonly) NSString *itemName;
@property (nonatomic, readonly) NSString *minimumSystemVersion;
@property (nonatomic, readonly) NSArray *requiredDeviceCapabilities;
@property (nonatomic, readonly) NSString *roleIdentifier;
@property (nonatomic, readonly) NSString *sdkVersion;
@property (nonatomic, readonly) NSString *shortVersionString;
@property (nonatomic, readonly) NSString *sourceAppIdentifier;
@property (nonatomic, readonly) NSNumber *staticDiskUsage;
@property (nonatomic, readonly) NSString *teamID;
@property (nonatomic, readonly) NSString *vendorName;

@end


@implementation AppList
{
    PrivateApi_LSApplicationProxy* _applicationProxy;
    UIImage* _icon;
}

- (NSString*)name
{
    NSString *languageCode = [[NSLocale preferredLanguages] firstObject];
    NSRange range = [languageCode rangeOfString:@"-" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        languageCode = [languageCode substringToIndex:range.location];
    }
    
    NSString *infoPlistPath = [_applicationProxy.bundleURL.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.lproj/InfoPlist.strings", languageCode]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:infoPlistPath]) {
        NSDictionary *plistDict = [[NSDictionary alloc] initWithContentsOfFile:infoPlistPath];
        NSString* displayName = [plistDict objectForKey:@"CFBundleDisplayName"];
        if (displayName) {
            return displayName;
        }
    }
    
    return _applicationProxy.localizedName ?: _applicationProxy.localizedShortName;
}

- (NSString*)bundleIdentifier
{
    return [_applicationProxy bundleIdentifier];
}

- (UIImage*)icon
{
    if(nil == _icon)
    {
        _icon = [UIImage _applicationIconImageForBundleIdentifier:self.bundleIdentifier format:10 scale:UIScreen.mainScreen.scale];
    }
    
    return _icon;
}

- (NSString*)applicationDSID
{
    return _applicationProxy.applicationDSID;
}
- (NSURL*)bundleURL
{
    return _applicationProxy.bundleURL;
}
- (NSURL*)containerURL
{
    return _applicationProxy.containerURL;
}
- (NSString*)applicationIdentifier
{
    return _applicationProxy.applicationIdentifier;
}

- (NSString*)applicationType
{
    return _applicationProxy.applicationType;
}

- (NSArray*)groupIdentifiers
{
    return _applicationProxy.groupIdentifiers;
}

- (NSNumber*)itemID
{
    return _applicationProxy.itemID;
}

- (NSString*)itemName
{
    return _applicationProxy.itemName;
}

- (NSString*)minimumSystemVersion
{
    return _applicationProxy.minimumSystemVersion;
}

- (NSArray*)requiredDeviceCapabilities
{
    return _applicationProxy.requiredDeviceCapabilities;
}

- (NSString*)sdkVersion
{
    return _applicationProxy.sdkVersion;
}

- (NSString*)shortVersionString
{
    return _applicationProxy.shortVersionString;
}

- (NSNumber*)staticDiskUsage
{
    return _applicationProxy.staticDiskUsage;
}

- (NSString*)teamID
{
    return _applicationProxy.teamID;
}

- (NSString*)vendorName
{
    return _applicationProxy.vendorName;
}

- (BOOL)isHiddenApp
{
    return [[_applicationProxy appTags] indexOfObject:@"hidden"] != NSNotFound;
}

- (id)initWithPrivateProxy:(id)privateProxy
{
    self = [super init];
    if(self != nil)
    {
        _applicationProxy = (PrivateApi_LSApplicationProxy*)privateProxy;
    }
    
    return self;
}

- (instancetype)initWithBundleIdentifier:(NSString*)bundleIdentifier
{
    self = [super init];
    if(self != nil)
    {
        _applicationProxy = [NSClassFromString(@"LSApplicationProxy") applicationProxyForIdentifier:bundleIdentifier];
    }
    
    return self;
}

+ (instancetype)appWithPrivateProxy:(id)privateProxy
{
    return [[self alloc] initWithPrivateProxy:privateProxy];
}

+ (instancetype)appWithBundleIdentifier:(NSString*)bundleIdentifier
{
    return [[self alloc] initWithBundleIdentifier:bundleIdentifier];
}

@end
