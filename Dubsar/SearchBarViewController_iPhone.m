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
#import "SearchBarViewController_iPhone.h"
#import "SearchViewController_iPhone.h"

@implementation SearchBarViewController_iPhone
@synthesize autocompleter;
@synthesize searchBar;
@synthesize autocompleterTableView;
@synthesize autocompleterNib;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        proxy = [[AutocompleterProxy alloc]init];
        proxy.delegate = self;
        
        autocompleterNib = [[UINib nibWithNibName:@"AutocompleterView_iPhone" bundle:nil]retain];
    }
    return self;
}

- (void)dealloc
{
    [proxy release];
    [autocompleter release];
    [autocompleterNib release];
    [searchBar release];
    [autocompleterTableView release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [autocompleterNib instantiateWithOwner:self options:nil];
    [self.view addSubview:autocompleterTableView];
    // Do any additional setup after loading the view from its nib.
    [self createToolbarItems];
    self.navigationController.navigationBar.tintColor = searchBar.tintColor;
    self.navigationController.toolbar.tintColor = searchBar.tintColor;
}

- (void)viewDidUnload {
    [self setAutocompleterTableView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [autocompleterTableView setHidden:YES];
    [searchBar resignFirstResponder];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self initOrientation];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    
    [theSearchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];
    
    // new SearchViewController for this search
    NSLog(@"presenting view controller for \"%@\"", theSearchBar.text);
    SearchViewController_iPhone* searchViewController = [[[SearchViewController_iPhone alloc] initWithNibName: @"SearchViewController_iPhone" bundle: nil text: theSearchBar.text]autorelease];
    [self.navigationController pushViewController:searchViewController animated: YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar 
{
    if (theSearchBar != searchBar) return;
    theSearchBar.text = @"";
    [theSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    theSearchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    theSearchBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    NSLog(@"search bar text changed to \"%@\"", theSearchText);
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
    if (error) {
        return;
    }
    
    /*
     * Ignore old responses.
     */
    if (theAutocompleter.seqNum <= autocompleter.seqNum || 
        searchBar.text.length == 0) return ;
    
    [self setAutocompleter:theAutocompleter];
    [theAutocompleter release];
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
    
    if (autocompleter.results.count > 0) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [autocompleter.results objectAtIndex:indexPath.row];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = @"no suggestions";
    }
    
    return cell;
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [searchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];

    if (!autocompleter.complete || !autocompleter.results) {
        return;
    }
    
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
