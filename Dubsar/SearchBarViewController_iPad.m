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
#import "AutocompleterPopoverViewController_iPad.h"
#import "Autocompleter.h"
#import "DailyWord.h"
#import "DubsarAppDelegate_iPad.h"
#import "DubsarNavigationController_iPad.h"
#import "FAQViewController_iPad.h"
#import "SearchBarViewController_iPad.h"
#import "SearchViewController_iPad.h"
#import "WordPopoverViewController_iPad.h"

@implementation SearchBarViewController_iPad
@synthesize navigationController=_navigationController;
@synthesize autocompleter;
@synthesize searchBar;
@synthesize autocompleterTableView;
@synthesize caseSwitch;
@synthesize wotdButton;
@synthesize searchText=_searchText;
@synthesize dailyWord;
@synthesize wordPopoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // let the autocompleter view controller handle the table view
        AutocompleterPopoverViewController_iPad* viewController = [[[AutocompleterPopoverViewController_iPad alloc]initWithNibName:@"AutocompleterPopoverViewController_iPad" bundle:nil]autorelease];
        autocompleterTableView = (UITableView*)viewController.view;
        
        popoverController = [[UIPopoverController alloc]initWithContentViewController:viewController];
        popoverController.delegate = self;
        viewController.popoverController = popoverController;
        popoverController.popoverContentSize = CGSizeMake(320.0, 440.0);
        
        editing = false;
    }
    return self;
}

- (void)dealloc
{
    [wordPopoverController release];
    [dailyWord release];
    [popoverController release];
    autocompleter.delegate = nil;
    [autocompleter release];
    [_searchText release];
    [searchBar release];
    [autocompleterTableView release];
    [caseSwitch release];
    [wotdButton release];
    [super dealloc];
}

- (void)setNavigationController:(UINavigationController *)navigationController
{
    _navigationController = navigationController;
    AutocompleterPopoverViewController_iPad* viewController = (AutocompleterPopoverViewController_iPad*)popoverController.contentViewController;
    viewController.navigationController = navigationController;
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
    AutocompleterPopoverViewController_iPad* viewController = (AutocompleterPopoverViewController_iPad*)popoverController.contentViewController;
    viewController.searchBar = searchBar;
}

- (void)viewDidUnload
{
    [self setSearchBar:nil];
    [self setAutocompleterTableView:nil];
    [self setCaseSwitch:nil];
    [self setWotdButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar resignFirstResponder];
    [popoverController dismissPopoverAnimated:YES];
    
    SearchViewController_iPad* searchViewController = [[SearchViewController_iPad alloc]initWithNibName:@"SearchViewController_iPad" bundle:nil text:_searchText matchCase:caseSwitch.on];
    [searchViewController load];
    [_navigationController pushViewController:searchViewController animated:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    editing = true;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    editing = false;
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
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return theSearchBar == searchBar;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if ([model isMemberOfClass:Autocompleter.class]) [self autocompleterFinished:(Autocompleter*)model];
    
    if ([model isMemberOfClass:DailyWord.class]) [self wotdFinished:(DailyWord*)model];
}

- (void)autocompleterFinished:(Autocompleter*)theAutocompleter
{
    /*
     * Ignore old responses.
     */
    if (!editing || ![searchBar isFirstResponder] || 
        theAutocompleter.seqNum <= autocompleter.seqNum || 
        searchBar.text.length == 0) return ;
    
    [self setAutocompleter:theAutocompleter];
    [theAutocompleter release];
    
    AutocompleterPopoverViewController_iPad* viewController = (AutocompleterPopoverViewController_iPad*)popoverController.contentViewController;
    
    viewController.autocompleter = autocompleter;
    [autocompleterTableView reloadData];
    [popoverController presentPopoverFromRect:searchBar.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)wotdFinished:(DailyWord *)theDailyWord
{    
    WordPopoverViewController_iPad* viewController = [[[WordPopoverViewController_iPad alloc]initWithNibName:@"WordPopoverViewController_iPad" bundle:nil word:theDailyWord.word]autorelease];
    [viewController load];
    self.wordPopoverController = [[[UIPopoverController alloc]initWithContentViewController:viewController]autorelease];
    viewController.popoverController = wordPopoverController;
    viewController.navigationController = _navigationController;
    
    [wordPopoverController presentPopoverFromRect:wotdButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)showWotd:(id)sender 
{
    dailyWord = [[DailyWord alloc]init];
    dailyWord.delegate = self;
    [dailyWord load];
}

- (IBAction)showFAQ:(id)sender 
{
    FAQViewController_iPad* faqViewController = [[[FAQViewController_iPad alloc] initWithNibName:@"FAQViewController_iPad" bundle:nil]autorelease];
    [_navigationController pushViewController:faqViewController animated:YES];
}

- (IBAction)loadRootController:(id)sender 
{
    searchBar.text = @"";
    caseSwitch.on = NO;
    
    AutocompleterPopoverViewController_iPad* viewController = (AutocompleterPopoverViewController_iPad*)popoverController.contentViewController;
    viewController.autocompleter = nil;
    [viewController.tableView reloadData];
    
    DubsarNavigationController_iPad* navigationController = (DubsarNavigationController_iPad*)_navigationController;    
    navigationController.searchBar.text = @"";
    
    viewController = (AutocompleterPopoverViewController_iPad*)navigationController.popoverController.contentViewController;
    viewController.autocompleter = nil;
    [viewController.tableView reloadData];
    
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [searchBar resignFirstResponder];
    if (popoverController.popoverVisible) {
        [popoverController dismissPopoverAnimated:YES];
    }
}

@end
