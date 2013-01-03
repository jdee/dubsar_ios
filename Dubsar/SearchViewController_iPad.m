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

#import "DubsarAppDelegate_iPad.h"
#import "DubsarNavigationController_iPad.h"
#import "LoadDelegate.h"
#import "Search.h"
#import "SearchViewController_iPad.h"
#import "Word.h"
#import "WordViewController_iPad.h"


@implementation SearchViewController_iPad

@synthesize search;
@synthesize tableView;
@synthesize pageControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString *)text matchCase:(BOOL)matchCase
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        search = [[Search searchWithTerm:text matchCase:matchCase]retain];
        search.delegate = self;
        
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", text];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil wildcard:(NSString *)wildcard title:(NSString *)theTitle
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        search = [[Search searchWithWildcard:wildcard page:1 title:theTitle]retain];
        search.delegate = self;
        
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", theTitle];
    }
    return self;    
}

- (void)dealloc
{
    search.delegate = nil;
    [search release];
    [tableView release];
    [pageControl release];
    [super dealloc];
}

- (void)load
{
    [search load];
}

- (IBAction)pageChanged:(id)sender 
{
    int newPage = pageControl.currentPage + 1;
    if (newPage == search.currentPage) return ;
    
    [self setSearchTitle:[NSString stringWithFormat:@"Search \"%@\" p. %d of %d", search.title, newPage, search.totalPages]];
    
    NSLog(@"page changed to %d, requesting...", pageControl.currentPage);
    pageControl.enabled = NO;

    // not interested in the old search any more
    search.delegate = nil;
    
    self.search = [search newSearchForPage:newPage];
    search.delegate = self;
    [search load];
    
    // kick the app back to a loading state.
    search.complete = false;
    [tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setTableViewHeight];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setPageControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (search.complete && !search.error) {
        [self loadComplete:search withError:nil];
    }
    else if (search.complete) {
        // try again
        search.complete = search.error = false;
        search.results = nil;
        [self load];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (!search || !search.complete || search.error || search.results.count == 0) {
        return 1;  
    }
    
    return search.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!search || !search.complete) {
        static NSString* indicatorType = @"indicator";
        UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:indicatorType];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indicatorType]autorelease];
        }
        
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
        indicator.frame = frame;
        [indicator startAnimating];
        [cell.contentView addSubview:indicator];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    static NSString *CellIdentifier = @"search";
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    else {
        cell.detailTextLabel.text = @"";
    }
    
    DubsarAppDelegate_iPad* appDelegate = (DubsarAppDelegate_iPad*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
 
    if (search.error) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = search.errorMessage;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (search.results.count == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [NSString stringWithFormat:@"no results for \"%@\"", search.term];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else {
        Word* word = [search.results objectAtIndex:indexPath.row];
        cell.textLabel.text = word.nameAndPos;
        NSString* subtitle = [NSString string];
        if (word.freqCnt > 0) {
            subtitle = [subtitle stringByAppendingFormat:@"freq. cnt.: %d", word.freqCnt];
            if (word.inflections && word.inflections.length > 0) {
                subtitle = [subtitle stringByAppendingString:@"; "];
            }
        }
        if (word.inflections && word.inflections.length > 0) {
            subtitle = [subtitle stringByAppendingFormat:@"also %@", word.inflections];
        }
        
        if (subtitle.length > 0) {
            cell.detailTextLabel.text = subtitle;
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!search || !search.complete || search.error || search.results.count == 0) return;
    
    Word* word = [search.results objectAtIndex:indexPath.row];
    WordViewController_iPad* wordViewController = [[[WordViewController_iPad alloc] initWithNibName:@"WordViewController_iPad" bundle:nil word:word]autorelease];
    [wordViewController load];
    [self.navigationController pushViewController:wordViewController animated:YES];
}

- (void)loadComplete:(Model*)model withError:(NSString *)error
{
    NSLog(@"received search response");
    Search* theSearch = (Search*)model;

    /*
     * Ignore old responses.
     */
    if (search != theSearch) {
        NSLog(@"ignoring old response");
        return;
    }
        
    if (!search.error) {
        NSLog(@"search completed without error: %d total pages", search.totalPages);
        NSLog(@"search title: \"%@\"", search.title);
        
        pageControl.numberOfPages = search.totalPages;
        pageControl.hidden = search.totalPages <= 1;
        pageControl.enabled = YES;
        
        int rows = search.results.count > 1 ? search.results.count : 1 ;
        float height = (rows)*44.0;
        
        tableView.contentSize = CGSizeMake(tableView.frame.size.width, height);
        [self setTableViewHeight];
        if (search.totalPages > 1) {
            [self setSearchTitle:[NSString stringWithFormat:@"Search: \"%@\" p. %d of %d", search.title, search.currentPage, search.totalPages]];
        }
    }
    
    [tableView reloadData];
}

- (void)setTableViewHeight
{
    UIInterfaceOrientation currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
    float height = UIInterfaceOrientationIsPortrait(currentOrientation) ? 960.0 : 704.0 ;

    CGRect frame = tableView.frame;        

    if (!pageControl.hidden) {
        height -= 36.0;          
    }
    frame.size.height = height;
    
    tableView.frame = frame;

}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)setSearchTitle:(NSString *)theTitle
{
    self.title = theTitle;
    
    DubsarNavigationController_iPad* navigationController = (DubsarNavigationController_iPad*)self.navigationController;
    
    navigationController.titleLabel.title = theTitle;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self setTableViewHeight];
}

@end
