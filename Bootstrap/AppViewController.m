// ref https://github.com/XsF1re/FlyJB-App

#import "AppViewController.h"
#include "AppDelegate.h"
#import "AppList.h"
#include "common.h"
#include "AppDelegate.h"
#include <sys/stat.h>

@interface PrivateApi_LSApplicationWorkspace
- (NSArray*)allInstalledApplications;
- (bool)openApplicationWithBundleID:(id)arg1;
- (NSArray*)privateURLSchemes;
- (NSArray*)publicURLSchemes;
- (BOOL)_LSPrivateRebuildApplicationDatabasesForSystemApps:(BOOL)arg1
                                                  internal:(BOOL)arg2
                                                      user:(BOOL)arg3;
@end

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
        for (AppList* app in appsArray) {
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
    
    [self setTitle:Localized(@"Tweak Enabler")];
    
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
    [refreshControl addTarget:self action:@selector(startRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    [self updateData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startRefresh)
                                          name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)startRefresh {
    [self.tableView.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self updateData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadSearch];
            [self.tableView reloadData];
            [self.tableView.refreshControl endRefreshing];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView.refreshControl beginRefreshing];
    [self.tableView.refreshControl endRefreshing];
}

- (void)updateData {
    NSMutableArray* applications = [NSMutableArray new];
    PrivateApi_LSApplicationWorkspace* _workspace = [NSClassFromString(@"LSApplicationWorkspace") new];
    NSArray* allInstalledApplications = [_workspace allInstalledApplications];

    for(id proxy in allInstalledApplications)
    {
        AppList* app = [AppList appWithPrivateProxy:proxy];
    
//        if(app.isHiddenApp) continue;
                
        if(![app.bundleURL.path hasPrefix:@"/Applications/"] && !isDefaultInstallationPath(app.bundleURL.path)) {
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
        
        if([app.bundleURL.path.lastPathComponent isEqualToString:@"TrollStore.app"])
            continue;
        
        if([app.bundleURL.path.lastPathComponent isEqualToString:@"Bootstrap.app"])
            continue;
            
        [applications addObject:app];
    }
    
    NSArray *appsSortedByName = [applications sortedArrayUsingComparator:^NSComparisonResult(AppList *app1, AppList *app2) {
        return [app1.name localizedStandardCompare:app2.name];
    }];
    
    self->appsArray = appsSortedByName;
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
    
    AppList* app = isFiltered? filteredApps[indexPath.row] : appsArray[indexPath.row];
    
    UIImage *image = app.icon;
    cell.imageView.image = [self imageWithImage:image scaledToSize:CGSizeMake(40, 40)];
    
    cell.textLabel.text = app.name;
    cell.detailTextLabel.text = app.bundleIdentifier;
    
    UISwitch *theSwitch = [[UISwitch alloc] init];
    
    if([unsupportedBundleIDs containsObject:app.bundleIdentifier])
        theSwitch.enabled = NO;
    
    struct stat st;
    BOOL enabled = lstat([app.bundleURL.path stringByAppendingPathComponent:@".jbroot"].fileSystemRepresentation, &st)==0;
    [theSwitch setOn:enabled];
    [theSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    cell.accessoryView = theSwitch;
    return cell;
}

- (void)switchChanged:(id)sender {
    // https://stackoverflow.com/questions/31063571/getting-indexpath-from-switch-on-uitableview
    UISwitch *switchInCell = (UISwitch *)sender;
    CGPoint pos = [switchInCell convertPoint:switchInCell.bounds.origin toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pos];
    BOOL enabled = switchInCell.on;
    AppList* app = isFiltered? filteredApps[indexPath.row] : appsArray[indexPath.row];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [AppDelegate showHudMsg:Localized(@"Applying")];
        
        killAllForApp(app.bundleURL.path.UTF8String);
        
        int status;
        NSString* log=nil;
        NSString* err=nil;
        if(enabled) {
            status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"enableapp",app.bundleURL.path], &log, &err);
        } else {
            status = spawnRoot(NSBundle.mainBundle.executablePath, @[@"disableapp",app.bundleURL.path], &log, &err);
        }
        
        if(status != 0) {
            [AppDelegate showMesage:[NSString stringWithFormat:@"%@\n\nstderr:\n%@",log,err] title:[NSString stringWithFormat:@"code(%d)",status]];
        }
        
        killAllForApp(app.bundleURL.path.UTF8String);
        
        //refresh app cache list
        [self updateData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadSearch];
            [self.tableView reloadData];
        });
        
        [AppDelegate dismissHud];
        
    });
}
@end
