/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
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
#import "SearchBarViewController_iPhone.h"
#import "SearchViewController_iPhone.h"

@implementation SearchBarViewController_iPhone
@synthesize autocompleter;
@synthesize searchBar;
@synthesize autocompleterTableView;
@synthesize autocompleterNib;
@synthesize preEditText;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        proxy = [[AutocompleterProxy alloc]init];
        proxy.delegate = self;
        
        autocompleterNib = [[UINib nibWithNibName:@"AutocompleterView_iPhone" bundle:nil]retain];
        
        preEditText = nil;
        
    }
    return self;
}

- (void)dealloc
{
    [preEditText release];
    [proxy release];
    autocompleter.delegate = nil;
    [autocompleter release];
    [autocompleterNib release];
    [searchBar release];
    [autocompleterTableView release];
    [super dealloc];
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
    
    // BUG: Why does this have to be reloaded every time?
    // If I'm in airplane mode and tap a link to something, it comes
    // back with a network error. Then I exit airplane mode and try
    // again once the network is back. When I go back and forward
    // again, the page is loaded correctly. Then I go back and forward
    // again, with the network available, and the view comes back
    // with stale data (network error) unless it's reloaded every time.
    
    // if (!self.loadedSuccessfully) {
        [self load];
    // }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    
    [theSearchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];
    
    // new SearchViewController for this search
    SearchViewController_iPhone* searchViewController = [[[SearchViewController_iPhone alloc] initWithNibName: @"SearchViewController_iPhone" bundle: nil text: theSearchBar.text]autorelease];
    [self.navigationController pushViewController:searchViewController animated: YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar 
{
    if (theSearchBar != searchBar) return;
    theSearchBar.text = preEditText;
    NSLog(@"canceled, restored search text to \"%@\"", preEditText);
    self.preEditText = nil;
    [autocompleterTableView setHidden:YES];
    [theSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    self.preEditText = [NSString stringWithString:searchBar.text];
    NSLog(@"editing began, started with \"%@\"", preEditText);
    theSearchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    self.preEditText = nil;
    theSearchBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    if (theSearchText.length > 0) {
        Autocompleter* _autocompleter = [[Autocompleter autocompleterWithTerm:theSearchText matchCase:NO]retain];
        _autocompleter.delegate = proxy;
        [_autocompleter load];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [self.navigationController setToolbarHidden:NO animated:YES];
            [self.view setNeedsLayout];
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [self.navigationController setToolbarHidden:YES animated:YES];
            [self.view setNeedsLayout];
            break;
        default:
            break;
    }
}


- (void)initOrientation
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation))
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
    UIBarButtonItem* homeButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObject:homeButtonItem];
    
    self.toolbarItems = buttonItems;
}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)autocompleterFinished:(Autocompleter *)theAutocompleter withError:(NSString *)error
{
    /*
     * Ignore old responses.
     */
    if (preEditText == nil || (autocompleter && theAutocompleter.seqNum <= autocompleter.seqNum) || 
        searchBar.text.length == 0) {
        [theAutocompleter release];
        return;
    }
    
    [autocompleter release];
    autocompleter = theAutocompleter;
    
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
        default:
            return 3;
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
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
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
    NSLog(@"in didSelect...");
    if (!autocompleter.complete || !autocompleter.results || autocompleter.results.count == 0) {
        return;
    }
    
    [searchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];
    
    NSString* text = [autocompleter.results objectAtIndex:indexPath.row];
    SearchViewController_iPhone* searchViewController = [[[SearchViewController_iPhone alloc] initWithNibName: @"SearchViewController_iPhone" bundle: nil text: text]autorelease];
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

@end
