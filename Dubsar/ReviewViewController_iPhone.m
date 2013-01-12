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

#include <errno.h>
#include <stdio.h>

#import "Dubsar.h"
#import "DubsarViewController_iPhone.h"
#import "Inflection.h"
#import "ReviewViewController_iPhone.h"
#import "Review.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

static int loadLastPage()
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    sqlite3_stmt* statement;
    int rc = 0;
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               "SELECT page FROM bookmarks ORDER BY id DESC LIMIT 1", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3 error %d", rc);
        return 0;
    }
    
    int page = 0;
    if (sqlite3_step(statement) == SQLITE_ROW) {
        page = sqlite3_column_int(statement, 0);
    }
    sqlite3_finalize(statement);
    return page;
}

static void saveLastPage(int page)
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    sqlite3_stmt* statement;
    int rc = 0;
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               "INSERT INTO bookmarks (page) VALUES (?)", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing INSERT: %d", rc);
        return;
    }
    
    if (sqlite3_bind_int(statement, 1, page) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        return;
    }
    
    sqlite3_step(statement);
    sqlite3_finalize(statement);
    
    // is there a better way to get the new id back?
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               "SELECT id FROM bookmarks ORDER BY id DESC LIMIT 1", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing SELECT: %d", rc);
        return;
    }
    
    int _id = 0;
    if (sqlite3_step(statement) == SQLITE_ROW) {
        _id = sqlite3_column_int(statement, 0);
    }
    sqlite3_finalize(statement);
    
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               "DELETE FROM bookmarks WHERE id < ?", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing DELETE: %d", rc);
        return;
    }
    
    if (sqlite3_bind_int(statement, 1, _id) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        return;
    }
    
    sqlite3_step(statement);
    sqlite3_finalize(statement);
}

@interface ReviewViewController_iPhone ()

@end

@implementation ReviewViewController_iPhone
@synthesize editing;
@synthesize editingRow;
@synthesize loading;
@synthesize selectButton;
@synthesize selectField;
@synthesize selectLabel;
@synthesize selectView;
@synthesize tableView;
@synthesize review;
@synthesize page;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil page:(int)thePage
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        page = thePage;
        
        // If called with page 0, try to start where we left off.
        if (page == 0) {
            page = loadLastPage();
            if (page) {
                NSLog(@"last page was %d", page);
            }
            else {
                NSLog(@"no last page available");
            }
        }
        
        // If this is the first time, we won't have a last page, so
        // start at 1.
        if (page == 0) {
            NSLog(@"starting at page 1");
            page = 1;
        }
        
        // Now this is our last page, whether we just now loaded from storage or
        // are being launched by a Next or Prev button tap.
        NSLog(@"saving last page %d", page);
        saveLastPage(page);
        
        self.review = [Review reviewWithPage:page];
        self.review.delegate = self;
        self.title = [NSString stringWithFormat:@"Review p. %d", page];
        self.loading = self.editing = false;
        self.editingRow = -1;
        
        [self createToolbarItems];
    }
    return self;
}

- (void)dealloc
{
    [review release];
    [super dealloc];
}

- (void)load
{
    if (self.loading) return;
 
    [review load];
    
    self.loading = true;
    [tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.selectView.hidden = YES;
    [self load];
    [tableView reloadData];
    saveLastPage(page);
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    NSLog(@"Review response received");
    self.loading = false;
    
    if (model != review) return;
    
    NSLog(@"Response is for our request");
    
    if (error) {
        // handle error
        NSLog(@"Error : %@", error);
        
        return;
    }
    
    NSLog(@"Reloading table view");
    
    self.title = [NSString stringWithFormat:@"Review p. %d/%d", review.page, review.totalPages];

    [self createToolbarItems];
    [tableView reloadData];
}

- (void)createToolbarItems
{
    NSMutableArray* buttonItems = [NSMutableArray array];
    
    UIBarButtonItem* item = [[[UIBarButtonItem alloc] initWithTitle:@"Home" style: UIBarButtonItemStyleBordered target:self action:@selector(loadMain)]autorelease];
    [buttonItems addObject:item];
    
    if (review && review.complete && review.page > 1) {
        item = [[[UIBarButtonItem alloc]initWithTitle:@"Prev" style:UIBarButtonItemStyleBordered target:self action:@selector(loadPrev)]autorelease];
        [buttonItems addObject:item];
    }
    if (review && review.complete && review.page < review.totalPages) {
        item = [[[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(loadNext)]autorelease];
        [buttonItems addObject:item];
    }
    
    item = [[[UIBarButtonItem alloc] initWithTitle:@"Select" style: UIBarButtonItemStyleBordered target:self action:@selector(displaySelectView)]autorelease];
    [buttonItems addObject:item];
    
    if (editing) {
        item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishEditingTableView)] autorelease];
        [buttonItems addObject:item];        
    }
    else {
        item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditingTableView)]autorelease];
        [buttonItems addObject:item];
    }
    
    self.toolbarItems = buttonItems;
}

- (void) loadPrev
{
    int prevPage = review.page - 1;
    ReviewViewController_iPhone* viewController = [[[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:prevPage] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) loadNext
{
    int nextPage = review.page + 1;
    ReviewViewController_iPhone* viewController = [[[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:nextPage] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) loadMain
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)startEditingTableView
{
    editing = true;
    [self createToolbarItems];
    [tableView setEditing:YES animated:YES];
}

- (void)finishEditingTableView
{
    editing = false;
    [self createToolbarItems];
    [tableView setEditing:NO animated:YES];
}

- (IBAction)selectPage:(id)sender
{
    [self dismissSelectView:sender];

    if (editingRow >= 0) {
        [self updateInflection];
        return;
    }
    
    int pageNo = [selectField.text intValue];
    ReviewViewController_iPhone* viewController = [[[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:pageNo] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)displaySelectView
{
    selectLabel.text = @"Select page";
    selectField.placeholder = @"page number";
    selectField.keyboardType = UIKeyboardTypeNumberPad;
    selectButton.titleLabel.text = @"Go";
    selectView.hidden = NO;
    [selectField becomeFirstResponder];
}

- (IBAction)dismissSelectView:(id)sender
{
    [selectField resignFirstResponder];
    selectView.hidden = YES;
}

- (void)updateInflection
{
    Inflection* inflection = [review.inflections objectAtIndex:editingRow];
    
    // update the local DB
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(appDelegate.database, "UPDATE inflections SET name = ? WHERE id = ?", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing statement", rc);
        return;
    }
    if ((rc=sqlite3_bind_text(statement, 1, [selectField.text cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"error %d binding parameter", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 2, inflection._id)) != SQLITE_OK) {
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
    if ((rc=sqlite3_bind_text(statement, 1, [selectField.text cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
        NSLog(@"error %d binding parameter", rc);
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 2, inflection._id)) != SQLITE_OK) {
        NSLog(@"error %d binding parameter", rc);
        sqlite3_finalize(statement);
        return;
    }
    
    sqlite3_step(statement);
    sqlite3_finalize(statement);
    
    // PUT back to the server
    NSString* url = [[NSString stringWithFormat:@"%@%@", DubsarSecureUrl, inflection._url]retain];
    
    NSString* jsonPayload = [NSString stringWithFormat:@"{\"name\":\"%@\"}", selectField.text];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"PUT"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:[jsonPayload dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"PUT %@", url);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSHTTPURLResponse* response;
    NSError* error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"HTTP status code %d", response.statusCode);

    editingRow = -1;
    
    [self load];
    [tableView reloadData];
}

- (void)deleteInflectionAtRow:(int)row
{
    Inflection* inflection = [review.inflections objectAtIndex:row];
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(appDelegate.database, "DELETE FROM inflections WHERE id = ?", -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing delete statement: %d", rc);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 1, inflection._id)) != SQLITE_OK) {
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
    if ((rc=sqlite3_bind_int(statement, 1, inflection._id)) != SQLITE_OK) {
        NSLog(@"sqlite3_bind_int: %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    sqlite3_step(statement);
    sqlite3_finalize(statement);
    
    NSString* url = [[NSString stringWithFormat:@"%@%@", DubsarSecureUrl, inflection._url]retain];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"DELETE"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSLog(@"DELETE %@", url);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSHTTPURLResponse* response;
    NSError* error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"HTTP status code %d", response.statusCode);   

    [review.inflections removeObjectAtIndex:row];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

# pragma mark - Table View Management

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    Inflection* inflection = [review.inflections objectAtIndex:indexPath.row];
    WordViewController_iPhone* viewController = [[[WordViewController_iPhone alloc] initWithNibName:@"WordViewController_iPhone" bundle:nil word:inflection.word]autorelease];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return loading ? 1 : review.inflections.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)theTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"deleting row at %d", indexPath.row);
    [self deleteInflectionAtRow:indexPath.row];
    [self load];
    [tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Inflection* inflection = [review.inflections objectAtIndex:indexPath.row];
    
    selectLabel.text = @"Change inflection";
    selectField.placeholder = @"new inflection";
    selectField.text = inflection.name;
    selectField.keyboardType = UIKeyboardTypeDefault;
    selectButton.titleLabel.text = @"Save";
    selectView.hidden = NO;
    self.editingRow = indexPath.row;
    [selectField becomeFirstResponder];
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellType = @"inflection";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType]autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (loading || !review || !review.complete) {
        NSLog(@"review is not complete");
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"]autorelease];
        }
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]autorelease];
        [cell.contentView addSubview:indicator];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [indicator startAnimating];
        return cell;
    }
    
    int row = indexPath.row;
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    Inflection* inflection = [review.inflections objectAtIndex:row];
    cell.textLabel.text = inflection.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@.)", inflection.word.name, inflection.word.pos];
    
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

@end
