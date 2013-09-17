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

#import "Autocompleter.h"
#import "DubsarAppDelegate_iPhone.h"
#import "DubsarNavigationController_iPhone.h"
#import "SearchBarViewController_iPhone.h"
#import "SearchViewController_iPhone.h"

@implementation SearchBarViewController_iPhone
@synthesize autocompleter;
@synthesize searchBar;
@synthesize autocompleterTableView;
@synthesize autocompleterNib;
@synthesize preEditText;
@synthesize navigationGestureRecognizer;
@synthesize loading;
@synthesize executingAutocompleter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        proxy = [[AutocompleterProxy alloc]init];
        proxy.delegate = self;
        
        autocompleterNib = [UINib nibWithNibName:@"AutocompleterView_iPhone" bundle:nil];
        
        preEditText = nil;
        navigationGestureRecognizer = nil;
        loading = false;
        executingAutocompleter = nil;
    }
    return self;
}

- (bool)loadedSuccessfully
{
    return true;
}

- (void)load
{
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [autocompleterNib instantiateWithOwner:self options:nil];
    [self.view addSubview:autocompleterTableView];
    CGRect frame = autocompleterTableView.frame;
    frame.origin.y = 44.0;
    autocompleterTableView.frame = frame;
    
    // Do any additional setup after loading the view from its nib.
    [self createToolbarItems];
    self.navigationController.navigationBar.tintColor = searchBar.tintColor;
    self.navigationController.toolbar.tintColor = searchBar.tintColor;
    
    [self addGestureRecognizers];
}

- (void)viewDidUnload {
    [self setAutocompleterTableView:nil];
    [self setSearchBar:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [autocompleterTableView setHidden:YES];
    [searchBar resignFirstResponder];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self initOrientation];
    if (preEditText != nil) searchBar.text = preEditText;
    [self load];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    
    [theSearchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];
    
    editing = false;
    
    // new SearchViewController for this search
    SearchViewController_iPhone* searchViewController = [[SearchViewController_iPhone alloc] initWithNibName: @"SearchViewController_iPhone" bundle: nil text: theSearchBar.text];
    [self.navigationController pushViewController:searchViewController animated: YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar 
{
    if (theSearchBar != searchBar) return;
    
    editing = false;
    
    theSearchBar.text = preEditText;
#ifdef DEBUG
    NSLog(@"canceled, restored search text to \"%@\"", preEditText);
#endif // DEBUG
    self.preEditText = nil;
    [autocompleterTableView setHidden:YES];
    [theSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    editing = true;
    
    self.preEditText = [NSString stringWithString:searchBar.text];
#ifdef DEBUG
    NSLog(@"editing began, started with \"%@\"", preEditText);
#endif // DEBUG
    theSearchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    self.preEditText = nil;
    theSearchBar.showsCancelButton = NO;
    editing = false;
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    if (theSearchText.length > 0) {
        // cancel any ongoing search
        @synchronized(self) {
            Autocompleter* theAutocompleter = self.executingAutocompleter;
            if (theAutocompleter != nil) {
                if (theAutocompleter != nil) {
                    theAutocompleter.aborted = true;
                }
            }
        }
        
        if (!editing) return;
        
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        Autocompleter* _autocompleter = [Autocompleter autocompleterWithTerm:theSearchText matchCase:NO];
        _autocompleter.delegate = proxy;
        _autocompleter.max = UIInterfaceOrientationIsPortrait(orientation) ? [UIScreen mainScreen].bounds.size.height == 568.0 ? 5 : 3 : 1;
        _autocompleter.lock = self;
        [_autocompleter load];
        self.executingAutocompleter = _autocompleter;
    }
    else {
        [autocompleterTableView setHidden:YES];
    }
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return theSearchBar == searchBar;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [self.navigationController setToolbarHidden:NO animated:NO];
            [self.view setNeedsLayout];
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [self.navigationController setToolbarHidden:YES animated:NO];
            [self.view setNeedsLayout];
            break;
        default:
            break;
    }
}

- (void)initOrientation
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    // NSLog(@"device orientation: %d", deviceOrientation);
    
    // Can start with unknown orientation in iOS 6
    if (deviceOrientation == UIDeviceOrientationUnknown ||
        UIDeviceOrientationIsPortrait(deviceOrientation))
    {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
    else if (UIDeviceOrientationIsLandscape(deviceOrientation))
    {
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

- (void)createToolbarItems
{
    UIBarButtonItem* homeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObject:homeButtonItem];
    
    self.toolbarItems = buttonItems;
}

- (void)loadRootController
{
#ifdef DEBUG
    NSLog(@"in [SearchBarViewController_iPhone loadRootController]");
#endif // DEBUG
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)autocompleterFinished:(Autocompleter *)theAutocompleter withError:(NSString *)error
{
    @synchronized(self) {
        if (theAutocompleter == executingAutocompleter) {
            self.executingAutocompleter = nil;
        }
    }
    
    if (theAutocompleter.aborted || autocompleter.seqNum >= theAutocompleter.seqNum || !editing) {
        return;
    }
    
    self.autocompleter = theAutocompleter;

    [autocompleterTableView setHidden:NO];
    [autocompleterTableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    switch (autocompleter.results.count) {
        case 0:
        case 1:
            return 1;
        case 2:
            return 2;
        case 3:
            return 3;
        case 4:
            return 4;
        default:
            return 5;
    }
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    return @"suggestions";
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellType = @"autocomplete";
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType];
    }
    
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    
    if (autocompleter.error) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = autocompleter.errorMessage;
    }
    else if (autocompleter.results.count > 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [autocompleter.results objectAtIndex:indexPath.row];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = @"no suggestions";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!autocompleter.complete || !autocompleter.results || autocompleter.results.count == 0) {
        return;
    }
    
    [searchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];
    
    NSString* text = [[autocompleter.results objectAtIndex:indexPath.row]lowercaseString];
    SearchViewController_iPhone* searchViewController = [[SearchViewController_iPhone alloc] initWithNibName: @"SearchViewController_iPhone" bundle: nil text: text];
    [self.navigationController pushViewController:searchViewController animated: YES];
}

- (void)tableView:(UITableView*)theTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return -1;
}

- (void)addGestureRecognizers
{
    DubsarNavigationController_iPhone* navigationController = (DubsarNavigationController_iPhone*)self.navigationController;
    navigationGestureRecognizer = [navigationController addGestureRecognizerToView:self.view];
}

@end
