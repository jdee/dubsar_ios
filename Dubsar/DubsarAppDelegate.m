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

- (id)init
{
    self = [super init];
    if (self) {
        sranddev();
        dubsarTintColor  = [[UIColor colorWithRed:0.110 green:0.580 blue:0.769 alpha:1.0]retain];
        dubsarFontFamily = [[NSString stringWithString:@"Trebuchet"] retain];
        dubsarNormalFont = [[UIFont fontWithName:@"TrebuchetMS" size:18.0]retain];
        dubsarSmallFont  = [[UIFont fontWithName:@"TrebuchetMS" size:14.0]retain];
        databaseReady = false;

        [self prepareDatabase];
    }
    return self;
}

- (id)initForTest
{
    self = [super init];
    if (self) {
        [self prepareDatabase];
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    return YES;
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
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    sqlite3_finalize(autocompleterStmt);
    sqlite3_finalize(exactAutocompleterStmt);
    sqlite3_close(database);
    [dubsarFontFamily release];
    [dubsarNormalFont release];
    [dubsarTintColor release];
    [_window release];
    [super dealloc];
}

- (void)prepareDatabase
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];
    
    NSURL* resourceURL = [[NSBundle mainBundle] resourceURL];
    NSURL* srcURL = [resourceURL URLByAppendingPathComponent:PRODUCTION_DB_NAME];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL* appDataDir = [[url URLByAppendingPathComponent:appBundleID]
                         URLByAppendingPathComponent:@"Data"];
    NSString* installedDBPath = [[appDataDir path] stringByAppendingPathComponent:PRODUCTION_DB_NAME];
    
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
       
    int rc;
    if ((rc=sqlite3_open_v2([installedDBPath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_READWRITE, NULL)) != SQLITE_OK) {
        NSLog(@"error opening database %@, %d", installedDBPath, rc);
        database = NULL;
        return;
    }
    
    NSLog(@"successfully opened database %@", PRODUCTION_DB_NAME);
    NSString* sql;
    
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
