/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "UAirship.h"

#import "DailyWord.h"
#import "DubsarAppDelegate.h"

@implementation DubsarAppDelegate

@synthesize window=_window;
@synthesize dubsarTintColor;
@synthesize dubsarFontFamily;
@synthesize dubsarNormalFont;
@synthesize dubsarSmallFont;
@synthesize database;
@synthesize exactAutocompleterStmt;
@synthesize autocompleterStmt;
@synthesize databaseReady;
@synthesize authToken;
@synthesize wotdUrl, wotdUnread;

- (id)init
{
    self = [super init];
    if (self) {
        sranddev();
        dubsarTintColor  = [[UIColor colorWithRed:0.110 green:0.580 blue:0.769 alpha:1.0]retain];
        dubsarFontFamily = @"Trebuchet";
        dubsarNormalFont = [[UIFont fontWithName:@"TrebuchetMS" size:18.0]retain];
        dubsarSmallFont  = [[UIFont fontWithName:@"TrebuchetMS" size:14.0]retain];
        databaseReady = false;
        wotdUnread = false;
        
        self.authToken = nil;

        [self prepareDatabase:false];
    }
    return self;
}

- (id)initForTest
{
    self = [super init];
    if (self) {
        [self prepareDatabase:false];
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    
    //Init Airship launch options
    NSMutableDictionary *takeOffOptions = [[[NSMutableDictionary alloc] init] autorelease];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    [UAirship takeOff:takeOffOptions];
    
    // Register for notifications
    UAPush* uaPush = [UAPush shared];
    uaPush.delegate = self;
    
    [uaPush
     registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert)];
    
    [uaPush setAutobadgeEnabled:YES];
    
    // If cold launched from a push, this is how we get to the right screen,
    // via a call to handleBackgroundNotification:.
    [uaPush handleNotification:[launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey] applicationState:application.applicationState];
    
    [uaPush resetBadge];
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[UAPush shared] handleNotification:userInfo applicationState:application.applicationState];
    [[UAPush shared] resetBadge];
}

// Called when user taps an iOS notification
- (void)handleBackgroundNotification:(NSDictionary *)notification
{
    NSDictionary* dubsarPayload = [notification valueForKey:@"dubsar"];
    NSString* type = [dubsarPayload valueForKey:@"type"];
    if (![type isEqualToString:@"wotd"]) {
        NSLog(@"Unrecognized message type: \"%@\"", type);
        return;
    }

    NSString* url = [dubsarPayload valueForKey:@"url"];
    [self updateWotdByUrl:url];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

// Called when a notification is received in the foreground
- (void)handleNotification:(NSDictionary *)notification withCustomPayload:(NSDictionary *)customPayload
{
    NSLog(@"push received");
    NSDictionary *dubsarPayload = [notification valueForKey:@"dubsar"];
    NSString* type = [dubsarPayload valueForKey:@"type"];
    if (![type isEqualToString:@"wotd"]) {
        NSLog(@"Unrecognized message type: \"%@\"", type);
        return;
    }
        
    NSString* url = [dubsarPayload valueForKey:@"url"];
    if (url) {
        NSLog(@"dubsar url: %@", url);
        [self updateWotdByUrl:url];
        
        self.wotdUrl = url;
        self.wotdUnread = true;
        [self addWotdButton];
    }
}

- (void)updateWotdByUrl:(NSString *)url
{
    int wotdId = [[url lastPathComponent]intValue];
    [DailyWord updateWotdId:wotdId];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [UAirship land];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Updates the device token and registers the token with UA
    [[UAPush shared] registerDeviceToken:deviceToken];
}

- (void)dealloc
{
    [self closeDB];
    [dubsarFontFamily release];
    [dubsarNormalFont release];
    [dubsarTintColor release];
    [_window release];
    [super dealloc];
}

- (void)closeDB
{
    if (!database) return;
    
    sqlite3_finalize(autocompleterStmt);
    sqlite3_finalize(exactAutocompleterStmt);
    sqlite3_close(database);
    
    autocompleterStmt = exactAutocompleterStmt = NULL;
    database = NULL;
}

- (void)prepareDatabase:(bool)recreateFTSTables
{
    [self prepareDatabase:recreateFTSTables name:nil];
}

- (void)prepareDatabase:(bool)recreateFTSTables name:(NSString *)dbName
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];
    
    NSURL* resourceURL = [[NSBundle mainBundle] resourceURL];
    
    NSURL* srcURL = nil;
    if (dbName) {
        srcURL = [resourceURL URLByAppendingPathComponent:dbName];
    }
    else {
        srcURL = [resourceURL URLByAppendingPathComponent:PRODUCTION_DB_NAME];
    }
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL* appDataDir = [[url URLByAppendingPathComponent:appBundleID]
                         URLByAppendingPathComponent:@"Data"];
    
    NSString* installedDBPath = nil;
    if (dbName) {
        installedDBPath = [[appDataDir path] stringByAppendingPathComponent:dbName];
    } else {
        installedDBPath = [[appDataDir path] stringByAppendingPathComponent:PRODUCTION_DB_NAME];
    }
    
    if (![fileManager fileExistsAtPath:[appDataDir path]]) {
        NSError* error;
        if (![fileManager createDirectoryAtURL:appDataDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"creating app data dir: %@", error.localizedDescription);
            return;
        }
    }
    
    if (![fileManager fileExistsAtPath:installedDBPath]) {
        NSError* error;
        if (![fileManager copyItemAtURL:srcURL toURL:[NSURL fileURLWithPath:installedDBPath] error:&error]) {
            NSLog(@"copying DB: %@", error.localizedDescription);
            return;
        }
        NSLog(@"Copied DB to application data directory");
    }
    
    [self closeDB];
       
    int rc;
    if ((rc=sqlite3_open_v2([installedDBPath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_READWRITE, NULL)) != SQLITE_OK) {
        NSLog(@"error opening database %@, %d", installedDBPath, rc);
        database = NULL;
        return;
    }
    
    NSLog(@"successfully opened database %@", dbName);
    NSString* sql;
    
    if (recreateFTSTables) {
        sqlite3_stmt* statement;
        if ((rc=sqlite3_prepare_v2(database,
                                   "DELETE FROM inflections", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);

        if ((rc=sqlite3_prepare_v2(database,
                                   "DROP TABLE IF EXISTS inflections_fts", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);
        
        if ((rc=sqlite3_prepare_v2(database,
                                   "DROP TABLE IF EXISTS inflections_fts_content", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);
        
        if ((rc=sqlite3_prepare_v2(database,
                                   "DROP TABLE IF EXISTS inflections_fts_segdir", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);
        
        if ((rc=sqlite3_prepare_v2(database,
                                   "DROP TABLE IF EXISTS inflections_fts_segments", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);
        
        if ((rc=sqlite3_prepare_v2(database,
                                   "CREATE VIRTUAL TABLE inflections_fts USING fts3(id, name, word_id)", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);
    }
#if 0
    // recovering from an error
    else {
        sqlite3_stmt* statement;
        int rc;
        if ((rc=sqlite3_prepare_v2(database,
                                   "DELETE FROM inflections_fts", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);

        if ((rc=sqlite3_prepare_v2(database,
                               "INSERT INTO inflections_fts(id, name, word_id) SELECT id, name, word_id FROM inflections", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);
    
        if ((rc=sqlite3_prepare_v2(database,
                               "INSERT INTO inflections_fts(inflections_fts) VALUES('optimize')", -1, &statement, NULL)) != SQLITE_OK) {
            NSLog(@"sqlite3 error %d", rc);
            return;
        }
        sqlite3_step(statement);
        sqlite3_finalize(statement);
    }
#endif
    
    /*
     * Prepared statements for the Autocompleter
     */
    
    /*
     * Exact match first
     */
    sql = @"SELECT w.name "
    @"FROM inflections i "
    @"INNER JOIN words w "
    @"ON w.id = i.word_id "
    @"WHERE i.name = ? "
    @"ORDER BY w.name ASC";
    
    NSLog(@"preparing statement \"%@\"", sql);
    if ((rc=sqlite3_prepare_v2(database,
                               [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &exactAutocompleterStmt, NULL)) != SQLITE_OK) {
        NSLog(@"error preparing exact match statement, error %d", rc);
        return;
    }
    
    /* FTS search */
    sql = @"SELECT DISTINCT name "
    @"FROM inflections_fts "
    @"WHERE name MATCH ? AND name != ? "
    @"ORDER BY name ASC "
    @"LIMIT ?";
    
    NSLog(@"preparing statement \"%@\"", sql);
    if ((rc=sqlite3_prepare_v2(database,
                               [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &autocompleterStmt, NULL)) != SQLITE_OK) {
        NSLog(@"error preparing match statement, error %d", rc);
        return;
    }
    
    self.databaseReady = true;
    
    [pool release];
}

@end
