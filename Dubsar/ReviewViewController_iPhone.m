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
@synthesize deleting;

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
        self.deleting = false;
        
        [self createToolbarItems];
    }
    return self;
}

- (void)load
{
    if (self.loading || review.complete) return;

    self.loading = true;
 
    [review load];
    [tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.selectView.hidden = YES;
    if (!review.complete) [self load];
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
    
    self.deleting = false;

    [self createToolbarItems];
    [tableView reloadData];
}

- (void)createToolbarItems
{
    NSMutableArray* buttonItems = [NSMutableArray array];
    
    UIBarButtonItem* item = [[UIBarButtonItem alloc] initWithTitle:@"Home" style: UIBarButtonItemStyleBordered target:self action:@selector(loadMain)];
    [buttonItems addObject:item];
    
    if (review && review.complete && review.page > 1) {
        item = [[UIBarButtonItem alloc]initWithTitle:@"Prev" style:UIBarButtonItemStyleBordered target:self action:@selector(loadPrev)];
        [buttonItems addObject:item];
    }
    if (review && review.complete && review.page < review.totalPages) {
        item = [[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(loadNext)];
        [buttonItems addObject:item];
    }
    
    item = [[UIBarButtonItem alloc] initWithTitle:@"Select" style: UIBarButtonItemStyleBordered target:self action:@selector(displaySelectView)];
    [buttonItems addObject:item];
    
    if (editing) {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(finishEditingTableView)];
        [buttonItems addObject:item];        
    }
    else {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(startEditingTableView)];
        [buttonItems addObject:item];
    }
    
    self.toolbarItems = buttonItems;
}

- (void) loadPrev
{
    int prevPage = review.page - 1;
    ReviewViewController_iPhone* viewController = [[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:prevPage];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) loadNext
{
    int nextPage = review.page + 1;
    ReviewViewController_iPhone* viewController = [[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:nextPage];
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
    ReviewViewController_iPhone* viewController = [[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:pageNo];
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
    inflection.name = selectField.text;
    
    // update the local DB
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // PUT back to the server
    NSString* url = [NSString stringWithFormat:@"%@%@", DubsarSecureUrl, inflection._url];
    
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
    
    if (response.statusCode == 0 || response.statusCode >= 400) {
        editingRow = -1;
        return;
    }

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
    
    editingRow = -1;
    
    review.complete = false;
    [self load];
    [tableView reloadData];
}

- (void)deleteInflectionAtRow:(int)row
{
    Inflection* inflection = [review.inflections objectAtIndex:row];
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    NSString* url = [NSString stringWithFormat:@"%@%@", DubsarSecureUrl, inflection._url];
    
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
    
    if (response.statusCode == 0 || response.statusCode >= 400) {
        return;
    }
    
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
    WordViewController_iPhone* viewController = [[WordViewController_iPhone alloc] initWithNibName:@"WordViewController_iPhone" bundle:nil word:inflection.word title:nil];
    viewController.parentDataSource = self.review;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // If deleting, we're about to fill in the space at the bottom, so spinners down to ten rows
    return review.inflections.count <= 1 ? 1 : deleting ? 10 : review.inflections.count;
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
    self.deleting = true;
    [self deleteInflectionAtRow:indexPath.row];
    review.complete = false;
    [self load];
    [tableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (loading) return;
    
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
    int row = indexPath.row;
    
    if ((loading || !review || !review.complete) && row >= review.inflections.count) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"];
        }
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [cell.contentView addSubview:indicator];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [indicator startAnimating];
        return cell;
    }
    
    static NSString* cellType = @"inflection";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellType];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
        
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.selectionStyle = loading ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue;
    
    // transparent backgrounds for these
    cell.textLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    cell.detailTextLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    
    cell.backgroundView = loading ? [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"cell-bg.png"]]: nil;
    
    Inflection* inflection = [review.inflections objectAtIndex:row];
    cell.textLabel.text = inflection.name;
    
    NSString* prefix = [inflection.name commonPrefixWithString:inflection.word.name options:NSLiteralSearch];
    
    int prefixLen = prefix.length;
    
    NSString* suffix = [inflection.word.name substringFromIndex:prefixLen > 4 ? prefixLen-4 : 0];
    
    NSString* abbreviated = suffix.length < inflection.word.name.length && inflection.word.name.length > suffix.length + 1 ? [NSString stringWithFormat:@"-%@", suffix] : inflection.word.name;
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", abbreviated, inflection.word.pos];
    
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
