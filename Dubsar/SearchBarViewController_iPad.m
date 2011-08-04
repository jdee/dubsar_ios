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

#import "AboutViewController_iPad.h"
#import "Autocompleter.h"
#import "DubsarAppDelegate_iPad.h"
#import "FAQViewController_iPad.h"
#import "SearchBarViewController_iPad.h"
#import "SearchViewController_iPad.h"

@implementation SearchBarViewController_iPad
@synthesize navigationController=_navigationController;
@synthesize autocompleter;
@synthesize searchBar;
@synthesize autocompleterTableView;
@synthesize caseSwitch;
@synthesize searchText=_searchText;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        editing = false;

    }
    return self;
}

- (void)dealloc
{
    autocompleter.delegate = nil;
    [autocompleter release];
    [_searchText release];
    [searchBar release];
    [autocompleterTableView release];
    [caseSwitch release];
    [super dealloc];
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

    autocompleterTableView = [[UITableView alloc]initWithFrame:CGRectMake(0.0, 44.0, 320.0, 308.0) style:UITableViewStylePlain];
    autocompleterTableView.backgroundColor = self.view.backgroundColor;
    autocompleterTableView.dataSource = self;
    autocompleterTableView.delegate = self;
    [self.view addSubview:autocompleterTableView];
}

- (void)viewDidUnload
{
    [self setSearchBar:nil];
    [self setAutocompleterTableView:nil];
    [self setCaseSwitch:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [autocompleterTableView setHidden:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    
    [theSearchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];
    
    SearchViewController_iPad* searchViewController = [[SearchViewController_iPad alloc]initWithNibName:@"SearchViewController_iPad" bundle:nil text:_searchText matchCase:caseSwitch.on];
    [searchViewController load];
    [_navigationController pushViewController:searchViewController animated:YES];
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
    editing = true;
    theSearchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    editing = false;
    theSearchBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    _searchText = [theSearchText copy];
    
    if (!editing) return;
    
    if (theSearchText.length > 0) {
        Autocompleter* _autocompleter = [[Autocompleter autocompleterWithTerm:theSearchText matchCase:caseSwitch.on]retain];
        _autocompleter.delegate = self;
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

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if (error) {
        [model release];
        return;
    }
    
    Autocompleter* theAutocompleter = (Autocompleter*)model;
    /*
     * Ignore old responses.
     */
    if (!editing || ![searchBar isFirstResponder] || 
        (autocompleter && theAutocompleter.seqNum <= autocompleter.seqNum) || 
        searchBar.text.length == 0) return ;
    
    [autocompleter release];
    autocompleter = theAutocompleter;
    
    autocompleterTableView.hidden = NO;
    CGRect frame = CGRectMake(0.0, 44.0, 320.0, 44 * ([self tableView:autocompleterTableView numberOfRowsInSection:0]+1));
    autocompleterTableView.frame = frame;
    [autocompleterTableView reloadData];
}

- (IBAction)showFAQ:(id)sender 
{
    FAQViewController_iPad* faqViewController = [[[FAQViewController_iPad alloc] initWithNibName:@"FAQViewController_iPad" bundle:nil]autorelease];
    [_navigationController pushViewController:faqViewController animated:YES];
}

- (IBAction)loadRootController:(id)sender {
    [_navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)showAboutPage:(id)sender
{
    [_navigationController pushViewController:[[[AboutViewController_iPad alloc]initWithNibName:@"AboutViewController_iPad" bundle:nil]autorelease] animated:YES];
}

- (void)wildcardSearch:(NSString *)regexp title:(NSString *)title
{
    SearchViewController_iPad* viewController = [[[SearchViewController_iPad alloc]initWithNibName:@"SearchViewController_iPad" bundle:nil wildcard:regexp title:title]autorelease];
    [viewController load];
    [_navigationController pushViewController:viewController animated:YES];
}

- (IBAction)browseAB:(id)sender
{
    [self wildcardSearch:@"^[ABab]" title:@"AB"];
}

- (IBAction)browseCD:(id)sender
{
    [self wildcardSearch:@"^[CDcd]" title:@"CD"];
}

- (IBAction)browseEF:(id)sender
{
    [self wildcardSearch:@"^[EFef]" title:@"EF"];
}

- (IBAction)browseGH:(id)sender
{
    [self wildcardSearch:@"^[GHgh]" title:@"GH"];
}

- (IBAction)browseIJ:(id)sender
{
    [self wildcardSearch:@"^[IJij]" title:@"IJ"];
}

- (IBAction)browseKL:(id)sender
{
    [self wildcardSearch:@"^[KLkl]" title:@"KL"];
}

- (IBAction)browseMN:(id)sender
{
    [self wildcardSearch:@"^[MNmn]" title:@"MN"];
}

- (IBAction)browseOP:(id)sender
{
    [self wildcardSearch:@"^[OPop]" title:@"OP"];
}

- (IBAction)browseQR:(id)sender
{
    [self wildcardSearch:@"^[QRqr]" title:@"QR"];
}

- (IBAction)browseST:(id)sender
{
    [self wildcardSearch:@"^[STst]" title:@"ST"];
}

- (IBAction)browseUV:(id)sender
{
    [self wildcardSearch:@"^[UVuv]" title:@"UV"];
}

- (IBAction)browseWX:(id)sender
{
    [self wildcardSearch:@"^[WXwx]" title:@"WX"];
}

- (IBAction)browseYZ:(id)sender
{
    [self wildcardSearch:@"^[YZyz]" title:@"YZ"];
}

- (IBAction)browseOther:(id)sender
{
    [self wildcardSearch:@"^[^A-Za-z]" title:@"..."];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"suggestions";
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return autocompleter.results.count < 7 && autocompleter.results.count > 0 ? autocompleter.results.count :
    autocompleter.results.count == 0 ? 1 : 7;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellType = @"autocompleter";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault   reuseIdentifier:cellType]autorelease];
    }

    DubsarAppDelegate_iPad* appDelegate = (DubsarAppDelegate_iPad*)UIApplication.sharedApplication.delegate;
 
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
   
    if (autocompleter.results.count > 0) {
        int index = indexPath.row;
        cell.textLabel.text = [autocompleter.results objectAtIndex:index];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else {
        cell.textLabel.text = @"no suggestions";
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!autocompleter.complete || !autocompleter.results) {
        return;
    }
    
    NSString* text = [autocompleter.results objectAtIndex:indexPath.row];
    [searchBar setText:text];
    [searchBar resignFirstResponder];
    [autocompleterTableView setHidden:YES];
    
    SearchViewController_iPad* searchViewController = [[[SearchViewController_iPad alloc] initWithNibName: @"SearchViewController_iPad" bundle: nil text: text matchCase:caseSwitch.on]autorelease];
    [searchViewController load];
    [self.navigationController pushViewController:searchViewController animated: YES];
}

@end
