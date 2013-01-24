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
#import "EditInflectionsViewController_iPhone.h"
#import "Inflection.h"
#import "JSONKit.h"
#import "Word.h"

@interface EditInflectionsViewController_iPhone()

@end

@implementation EditInflectionsViewController_iPhone
@synthesize dialogTextField;
@synthesize dialogView;
@synthesize editButton;
@synthesize editing;
@synthesize inflections;
@synthesize tableView;
@synthesize word;
@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.editing = false;
        editingInflection = nil;
        self.word = theWord;
        [self load];
    }
    return self;
}

- (void)dealloc
{
    [dialogTextField release];
    [dialogView release];
    [editButton release];
    [inflections release];
    [tableView release];
    [word release];
    [super dealloc];
}

- (void)load
{
    // Retrieve inflections for the specified word from the server
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString* url = [NSString stringWithFormat:@"%@/words/%d/inflections?auth_token=%@", DubsarSecureUrl, word._id, appDelegate.authToken];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPMethod:@"GET"];
    
    NSLog(@"GET %@", url);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSHTTPURLResponse* response;
    NSError* error;
    NSData* body = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"HTTP status code %d", response.statusCode);
    
    if (response.statusCode != 200) {
        return;
    }
    
    JSONDecoder* decoder = [JSONDecoder decoder];
    self.inflections = [decoder objectWithData:body];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    self.dialogView.hidden = YES;
}

- (IBAction)edit:(id)sender
{
    editing = !editing;
    if (editing) {
        editButton.title = @"Done";
    }
    else {
        editButton.title = @"Edit";
    }
    [tableView setEditing:editing animated:YES];
}

- (IBAction)close:(id)sender
{
    bool complete = word.complete;
    NSLog(@"Dismissing modal view controller. Word is%s complete", complete ? "" : " not");
    [delegate modalViewControllerDismissed:self mustReload:!complete];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending) {
        // iOS 5.0+
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        // iOS 4.x
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (IBAction)cancel:(id)sender
{
    dialogView.hidden = YES;
    [dialogTextField resignFirstResponder];
}

- (IBAction)update:(id)sender
{
    dialogView.hidden = YES;
    [dialogTextField resignFirstResponder];
    
    if (editingInflection) {
        [self updateInflection];
    }
    else {
        [self createInflection];
    }
    [self load];
    [tableView reloadData];
}

- (IBAction)newInflection:(id)sender
{
    editingInflection = nil;
    dialogTextField.text = word.name;
    dialogView.hidden = NO;
    [dialogTextField becomeFirstResponder];
}

- (void)createInflection
{
    word.complete = false;
    NSLog(@"set complete to false");
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    NSString* url = [NSString stringWithFormat:@"%@/inflections?auth_token=%@", DubsarSecureUrl, appDelegate.authToken];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPMethod:@"POST"];
    
    NSString* payload = [NSString stringWithFormat:@"{\"name\":\"%@\",\"word_id\":%d}", dialogTextField.text, word._id];
    [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"POST %@", url);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSHTTPURLResponse* response;
    NSError* error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"HTTP status code %d", response.statusCode);
    
    if (response.statusCode == 0 || response.statusCode >= 400) {
        return;
    }
    
    NSDictionary* headers = [response allHeaderFields];
    NSString* location = [headers valueForKey:@"Location"];
    NSLog(@"Location: %@", location);
    int id = [[location lastPathComponent]intValue];
    NSLog(@"ID: %d", id);
    
    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(appDelegate.database, "INSERT INTO inflections(id, name, word_id) VALUES (?, ?, ?)", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing delete statement: %d", rc);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 1, id)) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_text(statement, 2, [dialogTextField.text cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 3, word._id)) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);
    
    if ((rc=sqlite3_prepare_v2(appDelegate.database, "INSERT INTO inflections_fts(id, name, word_id) VALUES (?, ?, ?)", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing delete statement: %d", rc);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 1, id)) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_text(statement, 2, [dialogTextField.text cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 3, word._id)) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);
}

- (void)deleteInflection:(int)row
{
    word.complete = false;
    NSLog(@"set complete to false");
    
    NSDictionary* container = [inflections objectAtIndex:row];
    NSDictionary* inflection = [container valueForKey:@"inflection"];
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    NSString* url = [NSString stringWithFormat:@"%@/inflections/%d?auth_token=%@", DubsarSecureUrl, [[inflection valueForKey:@"id"] intValue], appDelegate.authToken];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPMethod:@"DELETE"];
    
    NSLog(@"DELETE %@", url);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSHTTPURLResponse* response;
    NSError* error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"HTTP status code %d", response.statusCode);
    
    if (response.statusCode == 0 || response.statusCode >= 400) {
        return;
    }

    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(appDelegate.database, "DELETE FROM inflections WHERE id = ?", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing delete statement: %d", rc);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 1, [[inflection valueForKey:@"id"]intValue])) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);

    if ((rc=sqlite3_prepare_v2(appDelegate.database, "DELETE FROM inflections_fts WHERE id = ?", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing delete statement: %d", rc);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 1, [[inflection valueForKey:@"id"]intValue])) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);
}

- (void)updateInflection
{
    word.complete = false;
    NSLog(@"set complete to false");
    
    // update the local DB
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    NSString* url = [NSString stringWithFormat:@"%@/inflections/%d?auth_token=%@", DubsarSecureUrl, [[editingInflection valueForKey:@"id"] intValue], appDelegate.authToken];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPMethod:@"PUT"];
    
    NSString* payload = [NSString stringWithFormat:@"{\"name\":\"%@\"}", dialogTextField.text];
    [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"PUT %@", url);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSHTTPURLResponse* response;
    NSError* error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"HTTP status code %d", response.statusCode);
    
    if (response.statusCode == 0 || response.statusCode >= 400) {
        return;
    }

    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(appDelegate.database, "UPDATE inflections SET name = ? WHERE id = ?", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing statement", rc);
        return;
    }
    if ((rc=sqlite3_bind_text(statement, 1, [dialogTextField.text cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"error %d binding parameter", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 2, [[editingInflection valueForKey:@"id"]intValue])) != SQLITE_OK) {
        NSLog(@"error %d binding parameter", rc);
        sqlite3_finalize(statement);
        return;
    }
    
    sqlite3_step(statement);
    sqlite3_finalize(statement);

    if ((rc=sqlite3_prepare_v2(appDelegate.database, "UPDATE inflections_fts SET name = ? WHERE id = ?", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing statement", rc);
        return;
    }
    if ((rc=sqlite3_bind_text(statement, 1, [dialogTextField.text cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"error %d binding parameter", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 2, [[editingInflection valueForKey:@"id"]intValue])) != SQLITE_OK) {
        NSLog(@"error %d binding parameter", rc);
        sqlite3_finalize(statement);
        return;
    }
    
    sqlite3_step(statement);
    sqlite3_finalize(statement);
}

# pragma mark - table view management

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return inflections.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)theTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self deleteInflection:indexPath.row];
    
    [self load];
    [tableView reloadData];
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    NSDictionary* container = [inflections objectAtIndex:row];
    editingInflection = [container valueForKey:@"inflection"];
    dialogTextField.text = [editingInflection valueForKey:@"name"];
    dialogView.hidden = NO;
    [dialogTextField becomeFirstResponder];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellType = @"inflection";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
    }
        
    int row = indexPath.row;
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSDictionary* container = [inflections objectAtIndex:row];
    NSDictionary* inflection = [container valueForKey:@"inflection"];
    cell.textLabel.text = [inflection valueForKey:@"name"];
    
    return cell;
}

@end
