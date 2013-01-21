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

#import "DubsarAppDelegate_iPhone.h"
#import "EditInflectionsViewController_iPhone.h"
#import "InflectionsViewController_iPhone.h"
#import "WordViewController_iPhone.h"
#import "Sense.h"
#import "SenseViewController_iPhone.h"
#import "Word.h"

@implementation WordViewController_iPhone
@synthesize tableView;
@synthesize inflectionsTextView;
@synthesize word;
@synthesize parentDataSource;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        word = [theWord retain];
        word.delegate = self;
        self.loading = false;
        self.parentDataSource = nil;
        inflectionsViewController = nil;
        inflectionsShowing = false;

        self.title = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTableViewFrame) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [inflectionsViewController release];
    word.delegate = nil;
    [word release];
    [tableView release];
    [inflectionsTextView release];
    [super dealloc];
}

- (bool)loadedSuccessfully
{
    return word.complete && !word.error;
}

- (void)load
{
    NSLog(@"in [WordViewController_iPhone load]");
    if (!self.loading && !word.complete) {
        self.loading = true;
        [word load];
    }
    [self setTableViewFrame];
    [tableView reloadData];
}

- (void)createToolbarItems
{
    NSLog(@"In createToolbarItems");
    UIBarButtonItem* homeButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
    
#ifdef DUBSAR_EDITORIAL_BUILD
    UIBarButtonItem* editButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editInflections)]autorelease];
    
    self.toolbarItems = [NSArray arrayWithObjects:homeButtonItem, editButtonItem, nil];
#else
    if (word.inflections.count > 0) {
        UIBarButtonItem* inflectionsButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPageCurl target:self action:@selector(toggleInflections)] autorelease];
        self.toolbarItems = [NSArray arrayWithObjects:homeButtonItem, inflectionsButtonItem, nil];
        NSLog(@"Added two toolbar items");
    }
    else {
        self.toolbarItems = [NSArray arrayWithObject:homeButtonItem];
        NSLog(@"Added one toolbar item");
    }
#endif // DUBSAR_EDITORIAL_BUILD
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
    inflectionsViewController = [[InflectionsViewController_iPhone alloc] initWithNibName:@"InflectionsViewController_iPhone" bundle:nil word:word parent:self];
    
    [inflectionsViewController.view setHidden:YES];
    [self.view addSubview:inflectionsViewController.view];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setInflectionsTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"entering viewWillAppear:");
    [super viewWillAppear:animated];
    
    if (word.complete) {
        // If we are loaded with a word that is already complete, we aren't
        // going to get another chance to adjust things. Ordinarily, you
        // should call [viewController load] when you push it onto the
        // navigation stack though.
        [self adjustInflections];
        [self setTableViewFrame];
    }
    
    NSLog(@"exiting viewWillAppear:");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super numberOfSectionsInTableView:theTableView];
    }
    return word && word.complete ? word.senses.count : 1;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super sectionIndexTitlesForTableView:theTableView];
    }
    
    NSMutableArray* titles = [NSMutableArray array];
    if (!word || !word.complete || word.senses.count < 10) {
        return titles;
    }
    
    [titles addObject:@"top"];

    for (int j=4; j<word.senses.count; j += 5) {
        [titles addObject:[NSString stringWithFormat:@"%d", j+1]];
    }
    return titles;
}

- (NSInteger)tableView:(UITableView*)theTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (theTableView != tableView) {
        return [super tableView:theTableView sectionForSectionIndexTitle:title atIndex:index];
    }
    
    switch (index) {
        case 0:
            return 0;
    }
    return 5*index - 1;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForHeaderInSection:section];
    }
    
    if (!word || !word.complete) return @"loading...";
    
    Sense* sense = [word.senses objectAtIndex:section];
    
    NSString* textLine = [NSString string];
    if (sense.freqCnt > 0) {
        textLine = [textLine stringByAppendingFormat:@"freq. cnt.: %d", sense.freqCnt];
    }
    textLine = [textLine stringByAppendingFormat:@" <%@>", sense.lexname];
    if (sense.marker) {
        textLine = [textLine stringByAppendingFormat:@" (%@)", sense.marker];
    }
    return textLine;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForFooterInSection:section];
    }
    return @"";
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) {
        [super tableView:theTableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    [self.navigationController pushViewController:[[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:sense]autorelease] animated:YES];
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView numberOfRowsInSection:section];
    }
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != theTableView) {
        return [super tableView:theTableView cellForRowAtIndexPath:indexPath];
    }
    
    static NSString* cellType = @"word";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType] autorelease];
    }
    
    if (!word.complete) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"]autorelease];
        }
        
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
        [cell.contentView addSubview:indicator];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [indicator startAnimating];
        return cell;
    }
    
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", index+1, sense.gloss];
    cell.detailTextLabel.text = sense.synonymsAsString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
   
    return cell;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    self.loading = false;
    if (model != word) return;
    
    assert(word.complete);
    
    if (error) {
        [tableView setHidden:YES];
        [inflectionsTextView setText:error];
        return;
    }
    
    NSLog(@"word %@ inflections \"%@\"", word.nameAndPos, word.inflections);
   
    self.title = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];

    [self adjustInflections];
    
    NSLog(@"Load complete; adjusting table view");
    [self setTableViewFrame];
    [tableView reloadData];
}

- (void)adjustInflections
{
    if (word.freqCnt == 0) {
        inflectionsTextView.hidden = YES;
        CGRect frame = tableView.frame;
        frame.origin.y = 44.0;
        tableView.frame = frame;
        return;
    }
    
    NSString* text = [NSString string];
    if (word.freqCnt > 0) {
        text = [text stringByAppendingFormat:@"freq. cnt.: %d", word.freqCnt];
    }
    inflectionsTextView.text = text;
}

- (void)editInflections
{
    EditInflectionsViewController_iPhone* viewController = [[[EditInflectionsViewController_iPhone alloc] initWithNibName:@"EditInflectionsViewController_iPhone" bundle:nil word:word]autorelease];
    viewController.delegate = self;
    [self presentModalViewController:viewController animated:YES];
}

- (void)showInflections
{
    [UIView transitionWithView:self.view duration:0.4
                       options:UIViewAnimationOptionTransitionCurlUp
                    animations:^{
                        [self searchBar].hidden = YES;
                        tableView.hidden = YES;
                        inflectionsViewController.view.hidden = NO;
                    } completion:nil];
    inflectionsShowing = true;
}

- (void)dismissInflections
{
    [UIView transitionWithView:self.view duration:0.4
                       options:UIViewAnimationOptionTransitionCurlDown
                    animations:^{
                        [self searchBar].hidden = NO;
                        tableView.hidden = NO;
                        inflectionsViewController.view.hidden = YES;
                    } completion:nil];
    inflectionsShowing = false;
}

- (void)toggleInflections
{
    if (inflectionsShowing) [self dismissInflections];
    else [self showInflections];
}

- (void)setTableViewFrame
{
    bool inflectionsShowing = word.freqCnt > 0;
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    // BUG: Where do these extra 12 points come from? Should be 212 in landscape.
    float maxHeight = UIInterfaceOrientationIsPortrait(orientation) ? bounds.size.height - 152.0 : 224.0 ;
    if (inflectionsShowing) maxHeight -= 44.0;
    
    float height = 66.0*[self numberOfSectionsInTableView:tableView];  
    
    CGRect frame = tableView.frame;        
    
    frame.size.height = height > maxHeight ? maxHeight : height;
    frame.size.width = UIInterfaceOrientationIsPortrait(orientation) ? bounds.size.width : bounds.size.height;
    frame.origin.x = 0.0;
    frame.origin.y = inflectionsShowing ? 88.0 : 44.0;
    
    tableView.contentSize = CGSizeMake(frame.size.width, height);
    tableView.frame = frame;
    
    inflectionsTextView.hidden = !inflectionsShowing;
}

- (void)modalViewControllerDismissed:(UIViewController *)viewController mustReload:(BOOL)reload
{
    NSLog(@"entering modalViewControllerDismissed:mustReload:");
    NSLog(@"Word controller %s reload", reload ? "must" : "need not");
    [parentDataSource setComplete:!reload];
    self.loading = false;
    if (reload) [self load];
    NSLog(@"exiting modalViewControllerDismissed:mustReload:");
}

@end
