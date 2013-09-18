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

@interface SearchSpinnerCell : UITableViewCell
@property (nonatomic, strong) UIActivityIndicatorView* indicator;
- (id) initWithIdentifier:(NSString*)identifier;
@end

@implementation SearchSpinnerCell
@synthesize indicator;
- (id) initWithIdentifier:(NSString*)identifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    if (self) {
        indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        indicator.frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.autoresizingMask = UIViewAutoresizingNone;
        [indicator startAnimating];
        
        [self.contentView addSubview:indicator];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    indicator.frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
}
@end

@implementation SearchViewController_iPad

@synthesize search;
@synthesize tableView;
@synthesize pageControl;
@synthesize previewButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString *)text matchCase:(BOOL)matchCase
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        search = [Search searchWithTerm:text matchCase:matchCase];
        search.delegate = self;
        
        previewShowing = false;
        previewViewController = nil;
        originalColor = nil;
        
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", text];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(straightenAllTheShitOut) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil wildcard:(NSString *)wildcard title:(NSString *)theTitle
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        search = [Search searchWithWildcard:wildcard page:1 title:theTitle];
        search.delegate = self;
        
        previewShowing = false;
        previewViewController = nil;
        originalColor = nil;
        
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", theTitle];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(straightenAllTheShitOut) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;    
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

#ifdef DEBUG
    NSLog(@"page changed to %d, requesting...", pageControl.currentPage);
#endif // DEBUG
    pageControl.enabled = NO;

    // not interested in the old search any more
    search.delegate = nil;
    
    self.search = [search newSearchForPage:newPage];
    search.delegate = self;
    [previewViewController reset];
    [search load];
    
    if (previewShowing) {
        previewShowing = false;
        [self togglePreview:nil];
    }
    
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
    
    previewViewController = [[WordViewController_iPad alloc] initWithNibName:@"WordViewController_iPad" bundle:nil word:nil title:nil];
    
    UIView* previewView = previewViewController.view;
    previewViewController.bannerLabel.hidden = YES;
    // transparent background
    previewView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    
    [self.tableView addSubview:previewView];
    
    CGRect bounds = previewView.bounds;
    bounds.origin.y = 88.0;
    bounds.size.height += 88.0;
    previewView.bounds = bounds;
    
    originalColor = tableView.backgroundColor;
    [self setTableViewHeight];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setPageControl:nil];
    [super viewDidUnload];
    // Release any stronged subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [previewViewController reload];
    
    if (search.complete && !search.error) {
        [self loadComplete:search withError:nil];
    }
    else if (search.complete) {
        // try again
        search.complete = search.error = false;
        search.results = nil;
        [self load];
    }
    
    [self adjustPreview];
    [self setTableViewHeight];
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
    if (!search || !search.complete || search.error || search.results.count == 0 || previewShowing) {
        return 1;  
    }
    
    return search.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!search || !search.complete) {
        static NSString* indicatorType = @"search_indicator";
        UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:indicatorType];
        if (cell == nil) {
            cell = [[SearchSpinnerCell alloc] initWithIdentifier:indicatorType];
        }
        
        return cell;
    }
    
    static NSString *CellIdentifier = @"search";
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
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
    WordViewController_iPad* wordViewController = [[WordViewController_iPad alloc] initWithNibName:@"WordViewController_iPad" bundle:nil word:word title:nil];
    [wordViewController load];
    [self.navigationController pushViewController:wordViewController animated:YES];
}

- (void)loadComplete:(Model*)model withError:(NSString *)error
{
#ifdef DEBUG
    NSLog(@"received search response");
#endif // DEBUG
    Search* theSearch = (Search*)model;

    /*
     * Ignore old responses.
     */
    if (search != theSearch) {
#ifdef DEBUG
        NSLog(@"ignoring old response");
#endif // DEBUG
        return;
    }
        
    if (!search.error) {
#ifdef DEBUG
        NSLog(@"search completed without error: %d total pages", search.totalPages);
        NSLog(@"search title: \"%@\"", search.title);
#endif // DEBUG

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
        
        if (search.results.count > 0 && !previewShowing) {
            [self togglePreview:nil];
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

- (void)straightenAllTheShitOut
{
    [self setTableViewHeight];
    [self adjustPreview];
}

- (void)adjustPreview
{
    CGRect frame = previewViewController.view.frame;
    CGRect bounds = previewViewController.view.bounds;
    
    frame.size.width = self.view.bounds.size.width;
    frame.size.height = self.view.bounds.size.height + 88.0;
    
    bounds.size.width = self.view.bounds.size.width;
    bounds.size.height = self.view.bounds.size.height + 88.0;
    
    previewViewController.view.frame = frame;
    previewViewController.view.bounds = bounds;
    
    [previewViewController adjustPreview];
    [previewViewController setTableViewHeight];
}

- (IBAction)togglePreview:(id)sender
{
    if (previewShowing) {
        // hide preview
        CGRect frame = previewViewController.view.frame;
        frame.origin.y = UIScreen.mainScreen.bounds.size.height - 44.0;
        [UIView animateWithDuration:0.4 animations:^{
            previewViewController.view.frame = frame;
        } completion:^(BOOL finished) {
            if (finished) previewViewController.view.hidden = YES;
        }];
        previewShowing = false;
        
        tableView.backgroundColor = originalColor;
        [previewButton setTitle:@"Show"];
    }
    else {
        // show preview
        if (search.results.count < 1) return;
        
        Word* word = [search.results objectAtIndex:0];
        
        previewViewController.word = [Word wordWithId:word._id name:word.name partOfSpeech:word.partOfSpeech];
        previewViewController.word.preview = true;
        previewViewController.word.delegate = previewViewController;
        previewViewController.actualNavigationController = self.navigationController;
        [previewViewController load];
        tableView.backgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.00];
        
        CGRect frame = previewViewController.view.frame;
        frame.origin.y = UIScreen.mainScreen.bounds.size.height-44.0;
        previewViewController.view.frame = frame;
        
        frame.origin.y = 44.0;
        previewViewController.view.hidden = NO;
        [UIView animateWithDuration:0.4 animations:^{
            previewViewController.view.frame = frame;
        }];
        previewShowing = true;
        [self adjustPreview];
        [previewViewController reload];
        [previewButton setTitle:@"Hide"];
    }
    [tableView reloadData];
}

@end
