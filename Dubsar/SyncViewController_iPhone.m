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

#import "Dubsar.h"
#import "DubsarAppDelegate.h"
#import "JSONKit.h"
#import "SyncViewController_iPhone.h"

@interface SyncViewController_iPhone ()

@end

@implementation SyncViewController_iPhone
@synthesize fetchProgressView;
@synthesize insertProgressView;
@synthesize startButton;
@synthesize synching;
@synthesize mustStop;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        buffer = [[NSMutableData alloc]init];
        totalPages = insertFinished = 0;
        self.synching = false;
        self.mustStop = false;
        [self loadInflections:1];
    }
    return self;
}

- (void)dealloc
{
    [buffer release];
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    [startButton setEnabled:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)start:(id)sender
{
    if (!synching) {
        synching = true;
        [startButton setEnabled:NO];
        [self performSelectorInBackground:@selector(startSync) withObject:nil];
    }
}

- (IBAction)cancel:(id)sender
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;
    mustStop = true;
    synching = false;
    
    // reopen the main DB
    [appDelegate closeDB];
    [self deleteDatabase:@"backup.sqlite3"];
    [appDelegate prepareDatabase:false];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending) {
        // iOS 5.0+
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        // iOS 4.x
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (void)startSync
{
    [self backupDatabase];
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate prepareDatabase:true name:@"backup.sqlite3"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadInflections:(int)page
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;
    NSString* urlString = [NSString stringWithFormat:@"%@/inflections?page=%d&auth_token=%@", DubsarSecureUrl, page, appDelegate.authToken];
    NSURL* url = [NSURL URLWithString:urlString];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPMethod:@"GET"];
    
    NSLog(@"GET %@", urlString);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)backupDatabase
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL* appDataDir = [[url URLByAppendingPathComponent:appBundleID]
                         URLByAppendingPathComponent:@"Data"];
    NSString* installedDBPath = [[appDataDir path] stringByAppendingPathComponent:PRODUCTION_DB_NAME];
    
    NSString* backupPath = [[appDataDir path] stringByAppendingPathComponent:@"backup.sqlite3"];
    NSError* error;
    
    // could fail; don't care
    [fileManager removeItemAtPath:backupPath error:nil];
    
    NSLog(@"backing up DB");
    
    if ([fileManager copyItemAtPath:installedDBPath toPath:backupPath error:&error]) {
        NSLog(@"Backed up DB");
    }
    else {
        NSLog(@"failed to back up DB: %@", error.localizedDescription);
    }
}

- (void)restoreBackup
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL* appDataDir = [[url URLByAppendingPathComponent:appBundleID]
                         URLByAppendingPathComponent:@"Data"];
    NSString* installedDBPath = [[appDataDir path] stringByAppendingPathComponent:PRODUCTION_DB_NAME];
    
    NSString* backupPath = [[appDataDir path] stringByAppendingPathComponent:@"backup.sqlite3"];
    NSError* error;
    
    // could fail; don't care
    [fileManager removeItemAtPath:installedDBPath error:nil];
    
    NSLog(@"Restoring DB backup");
    if ([fileManager moveItemAtPath:backupPath toPath:installedDBPath error:&error]) {
        NSLog(@"Restored backup");
    }
    else {
        NSLog(@"failed to restore backup: %@", error.localizedDescription);
    }    
}

- (void)deleteDatabase:(NSString *)dbName
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSURL* appDataDir = [[url URLByAppendingPathComponent:appBundleID]
                         URLByAppendingPathComponent:@"Data"];
    
    NSString* backupPath = [[appDataDir path] stringByAppendingPathComponent:dbName];
    [fileManager removeItemAtPath:backupPath error:nil];
    NSLog(@"deleted %@", backupPath);
}

- (void)insertInflections:(NSArray*)inflections
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;

#if 1
    const char* sql = "INSERT INTO inflections(id, word_id, name) VALUES (?, ?, ?)";
    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(appDelegate.database, sql, -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing insert statement: %d", rc);
        return;
    }
    for (int j=0; !mustStop && j<inflections.count; ++j) {
        NSDictionary* inflection = [inflections objectAtIndex:j];
        NSDictionary* word = [inflection valueForKey:@"word"];
        
        if ((rc=sqlite3_reset(statement)) != SQLITE_OK) {
            NSLog(@"sqlite3_reset: %d", rc);
            return;
        }
        
        if ((rc=sqlite3_bind_int(statement, 1, [[inflection valueForKey:@"id"]intValue])) != SQLITE_OK) {
            NSLog(@"sqlite3_bind_int: %d", rc);
            return;
        }
        
        if ((rc=sqlite3_bind_int(statement, 2, [[word valueForKey:@"id"]intValue])) != SQLITE_OK) {
            NSLog(@"sqlite3_bind_int: %d", rc);
            return;
        }
        
        if ((rc=sqlite3_bind_text(statement, 3, [[inflection valueForKey:@"name"] cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
            NSLog(@"sqlite3_bind_text: %d", rc);
            return;
        }
        sqlite3_step(statement);
    }
    sqlite3_finalize(statement);
#else
    // This should be faster but has problems like properly escaping inflection names
    // and a very long SQL statement.
    NSString* sql = @"INSERT INTO inflections(id, name, word_id) VALUES ";
    int j;
    for (j=0; j<inflections.count; ++j) {
        NSDictionary* inflection = [inflections objectAtIndex:j];
        NSDictionary* word = [inflection valueForKey:@"word"];
        
        sql = [sql stringByAppendingFormat:@"(%d, \"%@\", %d),", [[inflection valueForKey:@"id"]intValue], [inflection valueForKey:@"name"], [[word valueForKey:@"id"]intValue]];
        
        if (j % 1000 == 0) {
            sql = [sql stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
            
            // flush
            int rc;
            sqlite3_stmt* statement;
            if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
                NSLog(@"preparing insert statement: %d", rc);
                return;
            }
            
            if ((rc=sqlite3_step(statement)) != SQLITE_OK) {
                NSLog(@"insert statement: error %d", rc);
            }
            sqlite3_finalize(statement);
            
            sql = @"INSERT INTO inflections(id, name, word_id) VALUES ";
        }
    }
    
    sql = [sql stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        
    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing insert statement: %d", rc);
        return;
    }
    
    if ((rc=sqlite3_step(statement)) != SQLITE_OK) {
        NSLog(@"insert statement: error %d", rc);
    }
    sqlite3_finalize(statement);
#endif
    
    [inflections release];
    
    if (mustStop) {
        return;
    }
    
    ++ insertFinished;
    insertProgressView.progress = ((float)insertFinished/(float)(totalPages+1));
    
    if (insertFinished >= totalPages) {
        [self.class buildFTSTable];
        
        // Successfully finished sync.
        
        // now move backup to production and reopen
        [appDelegate closeDB];
        [self deleteDatabase:@"production.sqlite3"];
        [self restoreBackup];
        [appDelegate prepareDatabase:false];
        
        ++insertFinished;
        insertProgressView.progress = 1.0;
        
        if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending) {
            // iOS 5.0+
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else {
            // iOS 4.x
            [self.parentViewController dismissModalViewControllerAnimated:YES];
        }
    }
}

+ (void)buildFTSTable
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;
    sqlite3_stmt* statement;
    int rc;
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               "INSERT INTO inflections_fts(id, name, word_id) SELECT id, name, word_id FROM inflections", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3 error %d", rc);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);
    
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               "INSERT INTO inflections_fts(inflections_fts) VALUES('optimize')", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3 error %d", rc);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);
}

# pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)data
{
    [buffer appendData:data];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSLog(@"HTTP status code %d", httpResponse.statusCode);
    [buffer setLength:0];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSLog(@"Received %d bytes", buffer.length);
    
    JSONDecoder* decoder = [JSONDecoder decoder];
    NSDictionary* jsonResponse = [decoder objectWithData:buffer];
    int page = [[jsonResponse valueForKey:@"page"] intValue];
    totalPages = [[jsonResponse valueForKey:@"total_pages"] intValue];
    
    fetchProgressView.progress = ((float)page/(float)totalPages);
    
    NSLog(@"Received inflections response, page %d", page);
    
    if (!mustStop && page < totalPages) {
        // request the next page
        ++ page;
        [self loadInflections:page];
    }
    
    NSArray* inflections = [jsonResponse valueForKey:@"inflections"];
    [self performSelectorInBackground:@selector(insertInflections:) withObject:[inflections retain]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSLog(@"HTTP request failed: %@", error.localizedDescription);
}

@end
