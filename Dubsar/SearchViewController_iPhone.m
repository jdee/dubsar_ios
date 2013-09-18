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

#import <stdlib.h>

#import "DubsarAppDelegate_iPhone.h"
#import "DubsarViewController_iPhone.h"
#import "SearchViewController_iPhone.h"
#import "Search.h"
#import "Word.h"
#import "WordViewController_iPHone.h"


@implementation SearchViewController_iPhone

@synthesize search;
@synthesize searchText=_searchText;
@synthesize searchResultsTableView=_tableView;
@synthesize pageControl = _pageControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString*)theSearchText 
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _searchText = theSearchText;
        
        // set up a new search request to the server asynchronously
        search = [Search searchWithTerm:_searchText matchCase:NO];
        search.delegate = self;
                
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", _searchText];
        firstWordViewController = nil;
        previewShowing = false;
        
        originalColor = nil;

        self.navigationController.toolbar.translucent = NO;
    }
    return self;
}

- (bool)loadedSuccessfully
{
    return search.complete && !search.error;
}

- (void)load
{
    if (self.loading || (search.complete && !search.error)) return;

    self.loading = true;
    
    [search load];
}

- (void)createToolbarItems
{
    UIBarButtonItem* homeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)];
    UIBarButtonItem* spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* detailButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Preview" style:UIBarButtonItemStyleBordered target:self action:@selector(togglePreview)];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObjects:homeButtonItem, spacer, detailButtonItem, nil];
    
    self.toolbarItems = buttonItems;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    firstWordViewController = [[WordViewController_iPhone alloc] initWithNibName:@"WordViewController_iPhone" bundle:nil word:nil title:nil];
    firstWordViewController.view.hidden = YES;
    firstWordViewController.searchBar.hidden = YES;
    firstWordViewController.autocompleterTableView.hidden = YES;
    firstWordViewController.bannerTextView.hidden = YES;
    
    [self.view addSubview:firstWordViewController.view];
    
    CGRect frame = firstWordViewController.view.frame;
    CGRect bounds = firstWordViewController.view.bounds;
    
    // clip this many points off the top of the embedded view
    double clip = 88.0;
    
    // offset for the clipped embedded view in the main one
    double offset = 88.0;
    
    bounds.origin.y = clip;
    bounds.size.height -= clip;
    
    frame.origin.y = offset;
    // frame.size.height -= offset;
    
    firstWordViewController.view.bounds = bounds;
    firstWordViewController.view.frame = frame;

#ifdef DEBUG
    NSLog(@"bounds: origin.x=%f, origin.y=%f, size.width=%f, size.height=%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    NSLog(@"frame: origin.x=%f, origin.y=%f, size.width=%f, size.height=%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
#endif // DEBUG
}

- (void)viewDidUnload
{
    [self setSearchBar:nil];
    [self setSearchResultsTableView:nil];
    [self setPageControl:nil];
    [super viewDidUnload];
    // Release any stronged subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self searchBar].text = [_searchText copy];
    if (search.complete && !search.error) {
        [self loadComplete:search withError:nil];
    }
    else {
        [self load];
    }
    
    if (previewShowing) {
        [firstWordViewController reload];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != [self searchBar]) return;
    
    _searchText = @"";
    [super searchBarCancelButtonClicked:theSearchBar];
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)searchText
{
    if (theSearchBar != [self searchBar]) return;
    self.searchText = searchText;
    [super searchBar:theSearchBar textDidChange:searchText];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != _tableView) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }

    if (!search.complete || search.error || search.results.count == 0) {
        return;
    }
    
    int index = indexPath.section;
    
    Word* word = [search.results objectAtIndex:index];
    Word* wordCopy = [Word wordWithId:word._id name:word.name partOfSpeech:word.partOfSpeech];
    WordViewController_iPhone* viewController = [[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:wordCopy title:nil];
    [wordCopy setDelegate:viewController];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    if (_tableView != tableView) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
    if (tableView != _tableView) return [super numberOfSectionsInTableView:tableView];
    
    NSInteger sections = search.complete && search.results && search.results.count > 0 ? search.results.count : 1;
    return sections;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != _tableView) {
        return [super tableView:theTableView titleForHeaderInSection:section];
    }
    
    return @"";
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (tableView != _tableView) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    static NSString* cellType = @"search";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType];
    }
    
    if (!search.complete) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"];
        }
        UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [cell.contentView addSubview:indicator];
        [indicator startAnimating];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
    
    if (search.error) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = search.errorMessage;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.text = @"";
        return cell;
    }
    else if (search.results.count == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [NSString stringWithFormat:@"no results for \"%@\"", _searchText];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.detailTextLabel.text = @"";
        return cell;
    }

    int index = indexPath.section;
    Word* word = [search.results objectAtIndex:index];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [word nameAndPos];
    
    NSString* subtitle = [NSString string];
    if (word.freqCnt > 0) {
        subtitle = [subtitle stringByAppendingFormat:@"freq. cnt.: %d", word.freqCnt];
        if (word.inflections && word.inflections.count > 0) {
            subtitle = [subtitle stringByAppendingString:@"; "];
        }
    }
    if (word.inflections && word.inflections.count > 0) {
        NSString* inflections = [NSString string];
        int j;
        for (j=0; j<word.inflections.count-1; ++j) {
            inflections = [inflections stringByAppendingFormat:@"%@, ", [word.inflections objectAtIndex:j]];
        }
        inflections = [inflections stringByAppendingString:[word.inflections objectAtIndex:j]];
        subtitle = [subtitle stringByAppendingFormat:@"also %@", inflections];
    }
    cell.detailTextLabel.text = subtitle;
    
    return cell;
}

- (IBAction)pageChanged:(id)sender 
{
    int newPage = _pageControl.currentPage + 1;
    if (newPage == search.currentPage) return ;

#ifdef DEBUG
    NSLog(@"page changed to %d, requesting...", _pageControl.currentPage);
#endif // DEBUG
    _pageControl.enabled = NO;

    [self setSearchTitle:[NSString stringWithFormat:@"\"%@\" p. %d of %d", search.title, newPage, search.totalPages]];
    
    // not interested in the old search any more
    search.delegate = nil;
    
    // when the preview is shown, reload for current page
    [firstWordViewController reset];
    
    self.search = [search newSearchForPage:newPage];
    search.delegate = self;
    [search load];
    
    // kick the app back to a loading state.
    search.complete = false;
    
    // don't show the preview by default when paging
    if (previewShowing) [self togglePreview];
    
    [_tableView reloadData];
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    self.loading = false;
    if (model != search) return;
    
    if (!error) {
#ifdef DEBUG
        NSLog(@"search complete");
        NSLog(@"search completed without error: %d total pages", search.totalPages);
        NSLog(@"search title: \"%@\"", search.title);
#endif // DEBUG
    
        _pageControl.numberOfPages = search.totalPages;
        _pageControl.hidden = search.totalPages <= 1;
        _pageControl.enabled = YES;
        
        int rows = search.results.count > 1 ? search.results.count : 1 ;
        float height = rows * 44.0;
        
        _tableView.contentSize = CGSizeMake(_tableView.frame.size.width, height);
        [self setTableViewHeight];
        if (search.totalPages > 1) {
            [self setSearchTitle:[NSString stringWithFormat:@"\"%@\" p. %d of %d", search.title, search.currentPage, search.totalPages]];
        }
        
        if (search.results.count > 0 && search.currentPage <= 1 && !previewShowing) {
            [self togglePreview:true];
        }
    }
    [_tableView reloadData];
}

- (void)setTableViewHeight
{
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    float height = UIInterfaceOrientationIsPortrait(orientation) ? bounds.size.height - 152.0 : 225.0 ;
    
    CGRect frame = _tableView.frame;        
    
    if (!_pageControl.hidden) {
        height -= 36.0;          
    }
    frame.size.height = height;
    
    _tableView.frame = frame;

#ifdef DEBUG
    NSLog(@"table view origin y: %f", _tableView.frame.origin.y);
#endif // DEBUG
}

- (void)setSearchTitle:(NSString *)theTitle
{
    
    [self setTitle:[NSString stringWithFormat:@"Search: %@", theTitle]];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // NSLog(@"device rotated");
    [self setTableViewHeight];
}

- (void)togglePreview
{
    [self togglePreview:true];
}

- (void)togglePreview:(bool)animated
{
    if (!previewShowing && search.results.count > 0) {
        firstWordViewController.actualNavigationController = self.navigationController;
        Word* word = [search.results objectAtIndex:0];
        
        if (!firstWordViewController.word) {
            firstWordViewController.word = [Word wordWithId:word._id name:nil partOfSpeech:POSUnknown];
            firstWordViewController.loading = false;
            firstWordViewController.word.delegate = firstWordViewController;
            [firstWordViewController load];
        }
        
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGRect frame = firstWordViewController.view.frame;
        frame.origin.y = screenBounds.size.height - 44.0;
        firstWordViewController.view.frame = frame;
        firstWordViewController.view.hidden = NO;
        previewShowing = true;
        
        frame.origin.y = 88.0;
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^{
                firstWordViewController.view.frame = frame;
            } completion:^(BOOL finished) {
                if (finished) [firstWordViewController.tableView reloadData];
            }];
        }
        else {
            firstWordViewController.view.frame = frame;
            [firstWordViewController reload];
        }
        
        originalColor = _tableView.backgroundColor;
        _tableView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];
        
        UIBarButtonItem* detailButtonItem = [self.toolbarItems objectAtIndex:2];
        detailButtonItem.title = @"Hide";
    }
    else {
        CGRect frame = firstWordViewController.view.frame;
        frame.origin.y = UIScreen.mainScreen.bounds.size.height - 44.0;
        
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^{
                firstWordViewController.view.frame = frame;
            } completion:^(BOOL finished) {
                if (finished) firstWordViewController.view.hidden = YES;
            }];
        }
        else {
            firstWordViewController.view.frame = frame;
            firstWordViewController.view.hidden = YES;
        }
        
        previewShowing = false;
        _tableView.backgroundColor = originalColor;
        originalColor = nil;
        
        UIBarButtonItem* detailButtonItem = [self.toolbarItems objectAtIndex:2];
        detailButtonItem.title = @"Show";
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    if (previewShowing) [self togglePreview:false];
    [super searchBarTextDidBeginEditing:theSearchBar];
}

@end
