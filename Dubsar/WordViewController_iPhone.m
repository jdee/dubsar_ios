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
@synthesize bannerTextView;
@synthesize word;
@synthesize parentDataSource;
@synthesize actualNavigationController;
@synthesize previewButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord title:(NSString*)theTitle
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        word = theWord;
        word.delegate = self;
        self.loading = false;
        self.parentDataSource = nil;
        inflectionsViewController = nil;
        inflectionsShowing = false;
        previewShowing = false;
        previewButton = nil;
        originalColor = nil;
        actualNavigationController = nil;
        
        firstSenseViewController = [[SenseViewController_iPhone alloc] initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:nil];

        if (theTitle) {
            customTitle = true;
            self.title = theTitle;
        }
        else {
            customTitle = false;
            self.title = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];
        }
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTableViewFrame) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;
}

- (bool)loadedSuccessfully
{
    return word.complete && !word.error;
}

- (void)load
{
#ifdef DEBUG
    NSLog(@"in [WordViewController_iPhone load]");
#endif // DEBUG
    if (!self.loading) {
        self.loading = true;
        [word load];
    }
    [self setTableViewFrame];
    [tableView reloadData];
}

- (void)reset
{
    self.word = nil;
    firstSenseViewController.sense = nil;
}

- (void)loadRootController
{
    [super loadRootController];
}

- (void)createToolbarItems
{
#ifdef DEBUG
    NSLog(@"In createToolbarItems");
#endif // DEBUG
    NSMutableArray* buttons = [NSMutableArray array];
    UIBarButtonItem* homeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)];
    [buttons addObject:homeButtonItem];
    
    UIBarButtonItem* spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [buttons addObject:spacer];
    
    self.previewButton = [[UIBarButtonItem alloc] initWithTitle:@"Preview" style:UIBarButtonItemStyleBordered target:self action:@selector(togglePreview)];
    [buttons addObject:previewButton];
    
#ifdef DUBSAR_EDITORIAL_BUILD
    UIBarButtonItem* editButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleBordered target:self action:@selector(editInflections)]autorelease];
    
    [buttons addObject:editButtonItem];
#endif // DUBSAR_EDITORIAL_BUILD
    
    if (word.inflections.count > 0) {
        UIBarButtonItem* inflectionsButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Inflections" style:UIBarButtonItemStylePlain target:self action:@selector(toggleInflections)];
        [buttons addObject:inflectionsButtonItem];
    }
    
    self.toolbarItems = buttons;
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
    
    firstSenseViewController.view.hidden = YES;
    [self.view addSubview:firstSenseViewController.view];
    CGRect frame = firstSenseViewController.view.frame;
    CGRect bounds = firstSenseViewController.view.bounds;
    
    // clip this many points off the top of the embedded view
    double clip = 132.0;
    
    // offset for the clipped embedded view in the main one
    double offset = 154.0;
    
    bounds.origin.y = clip;
    bounds.size.height -= clip;
    
    frame.origin.y = offset;
    // frame.size.height -= offset;
    
    firstSenseViewController.view.bounds = bounds;
    firstSenseViewController.view.frame = frame;

#ifdef DEBUG
    NSLog(@"bounds: origin.x=%f, origin.y=%f, size.width=%f, size.height=%f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
    NSLog(@"frame: origin.x=%f, origin.y=%f, size.width=%f, size.height=%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
#endif // DEBUG
    
    firstSenseViewController.autocompleterTableView.hidden = YES;
    firstSenseViewController.searchBar.hidden = YES;
    firstSenseViewController.bannerLabel.hidden = YES;
    firstSenseViewController.glossTextView.hidden = YES;
    
    originalColor = tableView.backgroundColor;
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setBannerTextView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUG
    NSLog(@"entering [WordViewController_iPhone viewWillAppear:]");
#endif // DEBUG
    [super viewWillAppear:animated];
    
    if (word.complete) {
        // If we are loaded with a word that is already complete, we aren't
        // going to get another chance to adjust things. Ordinarily, you
        // should call [viewController load] when you push it onto the
        // navigation stack though.
        [self adjustBanner];
        [self setTableViewFrame];
    }
    
    if (previewShowing) {
       [firstSenseViewController.tableView reloadData];
    }
        
    if (!actualNavigationController) self.actualNavigationController = self.navigationController;

#ifdef DEBUG
    NSLog(@"exiting [WordViewController_iPhone viewWillAppear:]");
#endif // DEBUG
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
    [actualNavigationController pushViewController:[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:sense] animated:YES];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType];
    }
    
    if (!word.complete) {
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
        [bannerTextView setText:error];
        return;
    }
    
    [self createToolbarItems];

#ifdef DEBUG
    NSLog(@"word %@ inflections \"%@\"", word.nameAndPos, word.inflections);
#endif // DEBUG
   
    if (!customTitle) self.title = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];

    [self adjustBanner];
    [inflectionsViewController loadComplete];

#ifdef DEBUG
    NSLog(@"Load complete; adjusting table view");
#endif // DEBUG
    [self setTableViewFrame];
    [tableView reloadData];
    
    if (inflectionsShowing) return;
    
    if (!previewShowing) {
        [self togglePreview:true];
    }
    else {
        previewShowing = false;
        [self togglePreview:false];
    }
}

- (void)adjustBanner
{
    NSString* text = word.nameAndPos;
    if (word.freqCnt > 0) {
        text = [text stringByAppendingFormat:@" freq. cnt.: %d", word.freqCnt];
    }
    bannerTextView.text = text;
}

- (void)editInflections
{
    EditInflectionsViewController_iPhone* viewController = [[EditInflectionsViewController_iPhone alloc] initWithNibName:@"EditInflectionsViewController_iPhone" bundle:nil word:word];
    viewController.delegate = self;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)showInflections
{
    [UIView transitionWithView:self.view duration:0.4
                       options:UIViewAnimationOptionTransitionCurlUp
                    animations:^{
                        [self searchBar].hidden = YES;
                        tableView.hidden = YES;
                        inflectionsViewController.view.hidden = NO;
                        firstSenseViewController.view.hidden = YES;
                    } completion:nil];
    inflectionsShowing = true;
}

- (void)dismissInflections
{
    inflectionsShowing = false;
    [UIView transitionWithView:self.view duration:0.4
                       options:UIViewAnimationOptionTransitionCurlDown
                    animations:^{
                        [self searchBar].hidden = NO;
                        tableView.hidden = NO;
                        inflectionsViewController.view.hidden = YES;
                        if (previewShowing) {
                            previewShowing = false;
                            [self togglePreview:false];
                        }
                    } completion:nil];
}

- (void)toggleInflections
{
    if (inflectionsShowing) [self dismissInflections];
    else [self showInflections];
}

- (void)setTableViewFrame
{
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    // BUG: Where do these extra 12 points come from? Should be 212 in landscape.
    // Update a year or so later: The nav bar in landscape seems to be narrower.
    float maxHeight = UIInterfaceOrientationIsPortrait(orientation) ? bounds.size.height - 152.0 : 224.0 ;
    maxHeight -= 44.0;
    
    float height = 66.0*[self numberOfSectionsInTableView:tableView];  
    
    CGRect frame = tableView.frame;        
    
    frame.size.height = height > maxHeight ? maxHeight : height;
    frame.size.width = UIInterfaceOrientationIsPortrait(orientation) ? bounds.size.width : bounds.size.height;
    frame.origin.x = 0.0;
    frame.origin.y = 88.0;
    
    tableView.contentSize = CGSizeMake(frame.size.width, height);
    tableView.frame = frame;
    
    // bannerTextView.hidden = NO;
}

- (void)modalViewControllerDismissed:(UIViewController *)viewController mustReload:(BOOL)reload
{
#ifdef DEBUG
    NSLog(@"entering modalViewControllerDismissed:mustReload:");
    NSLog(@"Word controller %s reload", reload ? "must" : "need not");
#endif // DEBUG
    [parentDataSource setComplete:!reload];
    self.loading = false;
    if (reload) [self load];
#ifdef DEBUG
    NSLog(@"exiting modalViewControllerDismissed:mustReload:");
#endif // DEBUG
}

- (void)togglePreview
{
    if (inflectionsShowing) return;
    
    [self togglePreview:true];
}

- (void)togglePreview:(bool)animated
{
    if (previewShowing) {
        // hide the preview
        CGRect frame = firstSenseViewController.view.frame;
        frame.origin.y = UIScreen.mainScreen.bounds.size.height - 44.0;
        if (animated) {
            [UIView animateWithDuration:0.4 animations:^{
                firstSenseViewController.view.frame = frame;
            } completion:^(BOOL finished){
                if (finished) firstSenseViewController.view.hidden = YES;
            }];
        }
        else {
            firstSenseViewController.view.frame = frame;
            firstSenseViewController.view.hidden = YES;
        }
        previewShowing = false;
        tableView.backgroundColor = originalColor;
        // previewButton.title = @"Show";
    }
    else {
        if (!firstSenseViewController.sense) {
            Sense* sense = [word.senses objectAtIndex:0];
            firstSenseViewController.sense = [Sense senseWithId:sense._id name:nil partOfSpeech:POSUnknown];
            firstSenseViewController.sense.preview = true;
            firstSenseViewController.sense.delegate = firstSenseViewController;
            firstSenseViewController.loading = false;
            firstSenseViewController.actualNavigationController = actualNavigationController;
            [firstSenseViewController load];
        }
        
        // show the preview
        CGRect frame = firstSenseViewController.view.frame;
        firstSenseViewController.view.hidden = NO;
        tableView.backgroundColor = [UIColor colorWithRed:1.00 green:0.89 blue:0.62 alpha:1.0];
        // tableView.backgroundColor = [UIColor colorWithRed:1.00 green:0.78 blue:0.24 alpha:1.0];
        
        frame.origin.y = 154.0;
        if (animated) {
            CGRect startFrame = frame;
            startFrame.origin.y = UIScreen.mainScreen.bounds.size.height - 44.0;
            firstSenseViewController.view.frame = startFrame;
            [UIView animateWithDuration:0.4 animations:^{
                firstSenseViewController.view.frame = frame;
            } completion:^(BOOL finished) {
                if (finished) [firstSenseViewController.tableView reloadData];
            }];
        }
        else {
            firstSenseViewController.view.frame = frame;
        }
        previewShowing = true;
        // previewButton.title = @"Hide";
    }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    if (previewShowing) [self togglePreview:false];
    [super searchBarTextDidBeginEditing:theSearchBar];
}

- (void)reload
{
    [self setTableViewFrame];
    [tableView reloadData];
    [firstSenseViewController.tableView reloadData];
}

@end
