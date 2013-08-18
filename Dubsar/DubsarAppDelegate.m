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

#import "DailyWord.h"
#import "Dubsar.h"
#import "DubsarAppDelegate.h"

@interface DubsarAppDelegate()
@property (copy) NSURL* alertURL;
- (void) landUA:(NSString*)deviceToken;
- (void) postDeviceToken:(NSData*)deviceToken;
@end

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
@synthesize wotdUrl, wotdUnread, alertURL;

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
    [self.window makeKeyAndVisible];

    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound];

    [self application:application didReceiveRemoteNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];

    if (application.applicationIconBadgeNumber > 0) application.applicationIconBadgeNumber = 0;

    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSDictionary* dubsarPayload = [userInfo valueForKey:@"dubsar"];
    if (!dubsarPayload) return;
    NSString* url = [dubsarPayload valueForKey:@"url"];
    NSString* type = [dubsarPayload valueForKey:@"type"];

    if ([type isEqualToString:@"wotd"]) {
        [self updateWotdByUrl:url expiration:[dubsarPayload valueForKey:@"expiration"]];
    }

    if (application.applicationState != UIApplicationStateActive) {
        [application openURL:[NSURL URLWithString:url]];
    }
    else if ([type isEqualToString:@"wotd"]) {
        self.wotdUrl = url;
        self.wotdUnread = true;
        [self addWotdButton];
    }
    else {
        /* non-WOTD notification received while app in FG. present alert view */
        self.alertURL = [NSURL URLWithString:url];
        UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Dubsar Notification" message:[((NSDictionary*)[userInfo valueForKey:@"aps"]) valueForKey:@"alert"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"More", nil]autorelease];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:self.alertURL];
    }
}

- (void)landUA:(NSString*)deviceToken
{
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"https://device-api.urbanairship.com/api/device_tokens/%@/", deviceToken]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"DELETE"];
    
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [connection start];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSDictionary* uaconfig = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"AirshipConfig.plist"]];

    NSString* appKey = nil;
    NSString* appSecret = nil;

#ifdef DUBSAR_DEVELOPMENT
    appKey = [uaconfig valueForKey:@"DEVELOPMENT_APP_KEY"];
    appSecret = [uaconfig valueForKey:@"DEVELOPMENT_APP_SECRET"];
#else
    appKey = [uaconfig valueForKey:@"PRODUCTION_APP_KEY"];
    appSecret = [uaconfig valueForKey:@"PRODUCTION_APP_SECRET"];
#endif // DUBSAR_DEVELOPMENT

    NSURLCredential* cred = [NSURLCredential credentialWithUser:appKey password:appSecret persistence:NSURLCredentialPersistenceNone];
    [challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"connection to UA failed: %@", error.localizedDescription);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
    NSURL* url = httpResp.URL;

    NSLog(@"response status code from %@: %d", url.absoluteString, httpResp.statusCode);

    if ([url.host hasSuffix:@".urbanairship.com"] && ((httpResp.statusCode >= 200 && httpResp.statusCode < 300) || httpResp.statusCode == 404))
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DubsarUADisabled"];
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)updateWotdByUrl:(NSString *)url expiration:(id)expiration
{
    int wotdId = [[url lastPathComponent]intValue];
    
    time_t texpiration = 0;
    
    if ([expiration isKindOfClass:NSString.class] && [expiration hasPrefix:@"+"]) {
        NSLog(@"push has relative expiration: %@", expiration);
        texpiration = time(0) + [expiration intValue];
    }
    else {
        texpiration = [expiration intValue];
    }
    
    [DailyWord updateWotdId:wotdId expiration:texpiration];
}

- (void)addWotdButton
{
    // Implemented by subclasses. This squelches a compiler warning.
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
    if (application.applicationIconBadgeNumber > 0) application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self postDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register for remote notifications: %@", error.localizedDescription);
}

- (void)dealloc
{
    [authToken release];
    [wotdUrl release];
    
    [self closeDB];
    [dubsarFontFamily release];
    [dubsarNormalFont release];
    [dubsarTintColor release];
    [_window release];
    [super dealloc];
}

- (void)postDeviceToken:(NSData *)deviceToken
{
    /*
     * 1. convert deviceToken to hex
     */
    unsigned char data[32];
    assert(deviceToken.length == sizeof(data));
    size_t length;

    [deviceToken getBytes:data length:&length];

    // data is now a buffer of 32 numeric bytes.
    // represent as hex in sdata, which will be
    // 64 bytes plus termination. Use a power of
    // 2 for the buffer.

    char sdata[128];
    memset(sdata, 0, sizeof(sdata));

    for (int j=0; j<sizeof(data); ++j) {
        sprintf(sdata+j*2, "%02x", data[j]);
    }

    NSString* token = [NSString stringWithCString:sdata encoding:NSUTF8StringEncoding];
    NSLog(@"Device token is %@", token);

    BOOL uaDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"DubsarUADisabled"];
    NSLog(@"DubsarUADisabled = %@", (uaDisabled == YES ? @"YES" : @"NO"));
    if (!uaDisabled) [self landUA:token];

    /*
     * 2. Read client secret from bundle
     */
    NSError* error;
    NSString* filepath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"client_secret.txt"];
    NSString* secret = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    if (error && !secret) {
        NSLog(@"Failed to read client_secret.txt: %@", error.localizedDescription);
    }

    /*
     * 3. Get app version
     */
    
    /*
     * Could also use kCFBundleVersionKey and strip the .x from the end
     */
    NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSLog(@"App version is %@", version);

    /*
     * 4. Determine production flag from preprocessor macro
     */
    NSString* production = nil;
#ifdef DUBSAR_DEVELOPMENT
    production = @"false";
#else
    production = @"true";
#endif // DUBSAR_DEVELOPMENT

    /*
     * 5. Construct JSON payload from this info
     */
    NSString* payload = [NSString stringWithFormat:@"{\"version\":\"%@\", \"secret\":\"%@\", \"device_token\":{\"token\":\"%@\", \"production\":%@} }", version, secret, token, production];

    /*
     * 6. Execute POST
     */
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/device_tokens", DubsarBaseUrl]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];

    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [connection start];
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
    
#ifdef DUBSAR_EDITORIAL_BUILD
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
#else
    [self closeDB];
    
    int rc;
    if ((rc=sqlite3_open_v2([srcURL.path cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_READONLY, NULL)) != SQLITE_OK) {
        NSLog(@"error opening database %@, %d", srcURL.path, rc);
        database = NULL;
        return;
    }
#endif // DUBSAR_EDITORIAL_BUILD
    
    NSLog(@"successfully opened database %@", dbName);
    NSString* sql;
   
#ifdef DUBSAR_EDITORIAL_BUILD
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
#endif // DUBSAR_EDITORIAL_BUILD
    
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
