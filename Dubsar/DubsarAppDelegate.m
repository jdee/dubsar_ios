/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
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
        dubsarTintColor  = [[UIColor colorWithRed:0.110 green:0.580 blue:0.769 alpha:1.0]retain];
        dubsarFontFamily = [[NSString stringWithString:@"Trebuchet"] retain];
        dubsarNormalFont = [[UIFont fontWithName:@"TrebuchetMS" size:18.0]retain];
        dubsarSmallFont  = [[UIFont fontWithName:@"TrebuchetMS" size:14.0]retain];
        databaseReady = false;
        // [self performSelectorInBackground:@selector(prepareDatabase) withObject:nil];
        [self prepareDatabase];
        databaseReady = true;
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
    
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString* srcPath = [resourcePath stringByAppendingPathComponent:PRODUCTION_DB_NAME];
    
    /* copy to Documents folder
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex: 0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError* error;
    NSString* dstPath = [documentsDir stringByAppendingPathComponent:PRODUCTION_DB_NAME];
    
    NSDictionary* attrs;
    NSDate* bundleDBCreationDate = nil;
    
    bool deploying = false;
    
    if (![fileManager fileExistsAtPath:srcPath]) {
        NSLog(@"cannot find bundle DB file %@", srcPath);
    }
    else {
        NSLog(@"found bundle DB file %@", srcPath);
        attrs = [fileManager attributesOfItemAtPath:srcPath error:&error];
        bundleDBCreationDate = [attrs valueForKey:NSFileCreationDate];
        NSLog(@"created at %@", bundleDBCreationDate);
        NSLog(@"modified at %@", [attrs valueForKey:NSFileModificationDate]);
    }
    
    if (![fileManager fileExistsAtPath:dstPath]) {
        NSLog(@"%@ does not exist, deploying", dstPath);
        if (![fileManager copyItemAtPath:srcPath toPath:dstPath error:&error]) {
            NSLog(@"error copying database %@ to %@, %@", srcPath, dstPath, error.localizedDescription);
            database = NULL;
            return;
        }
        deploying = true;
        NSLog(@"successfully deployed database %@", dstPath);
    }
    else {
        attrs = [fileManager attributesOfItemAtPath:dstPath error:&error];
        NSLog(@"%@ created at %@", dstPath, [attrs valueForKey:NSFileCreationDate]);
        NSLog(@"%@ modified at %@", dstPath, [attrs valueForKey:NSFileModificationDate]);
    
        if ([bundleDBCreationDate compare:[attrs valueForKey:NSFileModificationDate]] != NSOrderedAscending) {
            NSLog(@"%@ already deployed, removing", dstPath);
            if (![fileManager removeItemAtPath:dstPath error:&error]) {
                NSLog(@"could not remove DB %@: %@", dstPath, error.localizedDescription);
                database = NULL;
                return;
            }
            NSLog(@"removed old database, deploying to %@", dstPath);
            
            if (![fileManager copyItemAtPath:srcPath toPath:dstPath error:&error]) {
                NSLog(@"error copying database %@ to %@, %@", srcPath, dstPath, error.localizedDescription);
                database = NULL;
                return;
            }
            deploying = true;
            NSLog(@"successfully deployed database %@", dstPath);
        }
        else {
            NSLog(@"not deploying, using existing DB");
        }
    }
    
    attrs = [fileManager attributesOfItemAtPath:dstPath error:&error];
    NSLog(@"%@ created at %@", dstPath, [attrs valueForKey:NSFileCreationDate]);
    NSLog(@"%@ modified at %@", dstPath, [attrs valueForKey:NSFileModificationDate]);
     */
   
    int rc;
    if ((rc=sqlite3_open_v2([srcPath cStringUsingEncoding:NSUTF8StringEncoding], &database, SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_READONLY, NULL)) != SQLITE_OK) {
        NSLog(@"error opening database %@, %d", srcPath, rc);
        database = NULL;
        return;
    }
    
    NSLog(@"successfully opened database %@", PRODUCTION_DB_NAME);
    NSString* sql;
    
    /*
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(database, "INSERT INTO inflections_fts(inflections_fts) VALUES('optimize')", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing statement", rc);
        return;
    }
    
    if (sqlite3_step(statement) == SQLITE_ERROR) {
        NSLog(@"error optimizing FTS table");
        return;
    }
    
    sqlite3_finalize(statement);
    NSLog(@"optimized FTS table successfully");
     */
    
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
    
    sql = @"SELECT DISTINCT ifts.name "
    @"FROM inflections_fts ifts "
    @"INNER JOIN inflections i USING (id) "
    @"INNER JOIN words w ON w.id = i.word_id "
    @"WHERE ifts.name MATCH ? AND w.name != ? AND i.name != ? "
    @"ORDER BY ifts.name ASC "
    @"LIMIT ?";
    
    NSLog(@"preparing statement \"%@\"", sql);
    
    if ((rc=sqlite3_prepare_v2(database,
                               [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &autocompleterStmt, NULL)) != SQLITE_OK) {
        NSLog(@"error preparing match statement, error %d", rc);
        return;
    }
    else {
        NSLog(@"prepared statement successfully");
    }
    
    self.databaseReady = true;
    [self databasePrepFinished];
    
    [pool release];
}

-(void)databasePrepFinished
{
    // implemented in child classes
}

@end
