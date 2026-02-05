// ref https://github.com/XsF1re/FlyJB-App

#import "AppViewController.h"
#include "AppDelegate.h"
#import "AppInfo.h"
#include "common.h"
#include "AppDelegate.h"
#include <sys/stat.h>

@interface AppViewController () {
    UISearchController *searchController;
    NSArray *appsArray;
    
    NSMutableArray* filteredApps;
    BOOL isFiltered;
}

@end

@implementation AppViewController

+ (instancetype)sharedInstance {
    static AppViewController* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    isFiltered = false;
    [self.tableView reloadData];
}

-(void)reloadSearch {
    NSString* searchText = searchController.searchBar.text;
    if(searchText.length == 0) {
        isFiltered = false;
    } else {
        isFiltered = true;
        filteredApps = [[NSMutableArray alloc] init];
        searchText = searchText.lowercaseString;
        for (AppInfo* app in appsArray) {
            NSRange nameRange = [app.name.lowercaseString rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange bundleIdRange = [app.bundleIdentifier.lowercaseString rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound || bundleIdRange.location != NSNotFound) {
                [filteredApps addObject:app];
            }
        }
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearch];
    [self.tableView reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self setTitle:Localized(@"Enable Tweak for App")];
    
    isFiltered = false;
    
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchBar.delegate = self;
    searchController.searchBar.placeholder = Localized(@"name or identifier");
    searchController.searchBar.barTintColor = [UIColor whiteColor];
    searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(manualRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    [self updateData:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(autoRefresh)
                                          name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)startRefresh:(BOOL)resort {
    [self.tableView.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self updateData:resort];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView.refreshControl endRefreshing];
        });
    });
}

- (void)manualRefresh {
    [self startRefresh:YES];
}

- (void)autoRefresh {
    [self startRefresh:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView.refreshControl beginRefreshing];
    [self.tableView.refreshControl endRefreshing];
}

-(BOOL)tweakEnabled:(AppInfo*)app {
    struct stat st;
    if(lstat([app.bundleURL.path stringByAppendingPathComponent:@".jbroot"].fileSystemRepresentation, &st)==0) {
        return YES;
    }
    
    if(@available(iOS 16.0, *))
    {
        if([app.bundleURL.path hasPrefix:@"/Applications/"] && [NSFileManager.defaultManager fileExistsAtPath:jbroot(app.bundleURL.path)]) {
            return YES;
        }
        
        if([NSFileManager.defaultManager fileExistsAtPath:jbroot([@"/.sysroot/" stringByAppendingString:app.bundleURL.path])]) {
            return YES;
        }
    }
    
    if(!isRemovableBundlePath(app.bundleURL.path.fileSystemRepresentation)) {
        return NO;
    }
    
    NSString* uuidPath = [app.bundleURL.path stringByDeletingLastPathComponent];
    NSString* backupFlag = [uuidPath stringByAppendingPathComponent:@".appbackup"];
    NSString* backupPath = [[uuidPath stringByAppendingPathComponent:app.bundleURL.path.lastPathComponent] stringByAppendingPathExtension:@"appbackup"];
    SYSLOG("uuidPath=%@, backupFlag=%@, backupPath=%@", uuidPath, backupFlag, backupPath);
    if([NSFileManager.defaultManager fileExistsAtPath:backupFlag] && [NSFileManager.defaultManager fileExistsAtPath:backupPath]) {
        //if the app has been successfully backed up but failed to enable tweak injection for some reason, or the app bundle is overwritten, we will still show that tweak injection has been enabled so that the user will have the chance to restore the app in appenabler
        return YES;
    }
    
    return NO;
}

- (void)updateData:(BOOL)sort {
    NSMutableArray* applications = [NSMutableArray new];
    NSArray* allInstalledApplications = [LSApplicationWorkspace.defaultWorkspace allInstalledApplications];

    for(id proxy in allInstalledApplications)
    {
        AppInfo* app = [AppInfo appWithPrivateProxy:proxy];
    
//        if(app.isHiddenApp) continue;
                
        if(![app.bundleURL.path hasPrefix:@"/Applications/"] && !isRemovableBundlePath(app.bundleURL.path.fileSystemRepresentation)) {
            //sysapp installed as jailbreak apps
            NSString* sysPath = [@"/Applications/" stringByAppendingPathComponent:app.bundleURL.path.lastPathComponent];
            if(![NSFileManager.defaultManager fileExistsAtPath:sysPath])
                continue;
        }
        
        if([app.applicationType isEqualToString:@"User"]) {
            NSArray* allowedBundleIds = [NSArray arrayWithContentsOfFile:jbroot(@"/.showcase.plist")];
            if(allowedBundleIds && ![allowedBundleIds containsObject:app.bundleIdentifier])
                continue;
        }
        
        if([NSFileManager.defaultManager fileExistsAtPath:
            [app.bundleURL.path stringByAppendingString:@"/.TrollStorePresistenceHelper"]])
                continue;
        
        if([NSFileManager.defaultManager fileExistsAtPath:
            [app.bundleURL.path stringByAppendingString:@"/.Bootstrap"]])
                continue;
        
        if([app.bundleURL.path.lastPathComponent isEqualToString:@"TrollStore.app"])
            continue;
        
        if([app.bundleURL.path.lastPathComponent isEqualToString:@"Bootstrap.app"])
            continue;
        
        if([app.bundleIdentifier isEqualToString:NSBundle.mainBundle.bundleIdentifier]
           || [app.bundleIdentifier isEqualToString:@"com.roothide.Bootstrap"])
            continue;
            
        [applications addObject:app];
    }
    
    if(sort)
    {
        NSArray *appsSortedByName = [applications sortedArrayUsingComparator:^NSComparisonResult(AppInfo *app1, AppInfo *app2) {

            BOOL enabled1 = [self tweakEnabled:app1];
            BOOL enabled2 = [self tweakEnabled:app2];
            
            if((enabled1&&!enabled2) || (!enabled1&&enabled2)) {
                return [@(enabled2) compare:@(enabled1)];
            }
            
            if(app1.isHiddenApp || app2.isHiddenApp) {
                return (enabled1&&enabled2) ? [@(app2.isHiddenApp) compare:@(app1.isHiddenApp)] : [@(app1.isHiddenApp) compare:@(app2.isHiddenApp)];
            }
            
            return [app1.name localizedStandardCompare:app2.name];
        }];
        
        self->appsArray = appsSortedByName;
    }
    else
    {
        NSMutableArray *newapps = [NSMutableArray array];
        [applications enumerateObjectsUsingBlock:^(AppInfo *newobj, NSUInteger idx, BOOL * _Nonnull stop) {
            __block BOOL hasBeenContained = NO;
            [self->appsArray enumerateObjectsUsingBlock:^(AppInfo *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.bundleIdentifier isEqualToString:newobj.bundleIdentifier]) {
                    hasBeenContained = YES;
                    *stop = YES;
                }
            }];
            if (!hasBeenContained) {
                [newapps addObject:newobj];
            }
        }];
        
        NSMutableArray *tmpArray = [NSMutableArray array];
        [self->appsArray enumerateObjectsUsingBlock:^(AppInfo *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [applications enumerateObjectsUsingBlock:^(AppInfo *newobj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.bundleIdentifier isEqualToString:newobj.bundleIdentifier]) {
                    [tmpArray addObject:newobj];
                    *stop = YES;
                }
            }];
        }];

        [tmpArray addObjectsFromArray:newapps];
        self->appsArray = tmpArray.copy;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadSearch];
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return isFiltered? filteredApps.count : appsArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Applist";
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

NSArray* unsupportedBundleIDs = @[
//    @"com.apple.mobileslideshow",
//    @"com.apple.mobilesafari",
];

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    AppInfo* app = isFiltered? filteredApps[indexPath.row] : appsArray[indexPath.row];
    
    if(!app.isHiddenApp) {
        UIImage *image = app.icon;
        cell.imageView.image = [self imageWithImage:image scaledToSize:CGSizeMake(40, 40)];
        cell.textLabel.text = app.name;
    } else {
        cell.textLabel.text = app.bundleIdentifier;
    }
    
    cell.detailTextLabel.text = app.bundleIdentifier;
    
    UISwitch *theSwitch = [[UISwitch alloc] init];
    
    if([unsupportedBundleIDs containsObject:app.bundleIdentifier])
        theSwitch.enabled = NO;
    
    [theSwitch setOn:[self tweakEnabled:app]];
    [theSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    cell.accessoryView = theSwitch;
    
    UILongPressGestureRecognizer *gest = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(cellLongPress:)];
    [cell.contentView addGestureRecognizer:gest];
    gest.view.tag = indexPath.row | indexPath.section<<32;
    gest.minimumPressDuration = 1;
    
    return cell;
}

- (void)switchChanged:(id)sender {
    // https://stackoverflow.com/questions/31063571/getting-indexpath-from-switch-on-uitableview
    UISwitch *switchInCell = (UISwitch *)sender;
    CGPoint pos = [switchInCell convertPoint:switchInCell.bounds.origin toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pos];
    
    AppInfo* app = isFiltered? filteredApps[indexPath.row] : appsArray[indexPath.row];
    
    BOOL enabled = switchInCell.on;
    
    if(enabled && isBlacklistedApp(app.bundleIdentifier.UTF8String)) {
        [AppDelegate showMesage:Localized(@"This app is blacklisted by RootHide Manager, please unblacklist it first.") title:@""];
        [switchInCell setOn:NO];
        return;
    }
    
    if(![NSFileManager.defaultManager fileExistsAtPath:app.bundleURL.path]) {
        NSString* msg = [NSString stringWithFormat:@"%@\n\n%@",
                         Localized(@"App bundle does not exist, try Bootstrap->[settings]->[rebuild icon cache] to fix it."),
                         app.bundleURL.path];
        [AppDelegate showMesage:msg title:Localized(@"Error")];
        [switchInCell setOn:!enabled];
        return;
    }
    
    if([app.bundleURL.path hasPrefix:@"/Applications/"])
    {
        NSString* resignedBundlePath = [jbroot(@"/.sysroot") stringByAppendingPathComponent:app.bundleURL.path];
        if([NSFileManager.defaultManager fileExistsAtPath:resignedBundlePath])
        {
            NSString* InfoPlistPath = [resignedBundlePath stringByAppendingPathComponent:@"Info.plist"];
            
            struct stat st={0};
            if(lstat(InfoPlistPath.fileSystemRepresentation, &st)!=0 || S_ISLNK(st.st_mode)) {
                [AppDelegate showMesage:Localized(@"This app's injection is hosted by Bootstrap now, you don't have to deal with it.") title:@""];
                [switchInCell setOn:!enabled];
                return;
            }
        }
    }

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Applying")];
        
        killAllForBundle(app.bundleURL.path.fileSystemRepresentation);
        
        NSString* log=nil;
        NSString* err=nil;
        int status = spawn_root(NSBundle.mainBundle.executablePath, @[enabled ? @"enableapp" : @"disableapp",app.bundleURL.path], &log, &err);
        if(status != 0) {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"error(%d)",status]];
        }
        
        killAllForBundle(app.bundleURL.path.fileSystemRepresentation);
        
        //refresh app cache list
        [self updateData:NO];
        
        [AppDelegate dismissHud];
        
    });
}

- (void)cellLongPress:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        long tag = recognizer.view.tag;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:tag&0xFFFFFFFF inSection:tag>>32];
        
        AppInfo* app = isFiltered? filteredApps[indexPath.row] : appsArray[indexPath.row];

        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [LSApplicationWorkspace.defaultWorkspace openApplicationWithBundleID:app.bundleIdentifier];
        });
    }
}
@end
