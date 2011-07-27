//
//  SearchBarViewController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Autocompleter.h"
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

#ifdef AUTOCOMPLETER_FROM_NIB
        autocompleterNib = [UINib nibWithNibName:@"AutocompleterView" bundle:nil];
#endif // AUTOCOMPLETER_FROM_NIB
    }
    return self;
}

- (void)dealloc
{
#ifdef AUTOCOMPLETER_FROM_NIB
    [autocompleterNib release];
#endif // AUTOCOMPLETER_FROM_NIB
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

#ifdef AUTOCOMPLETER_FROM_NIB
    // Would prefer to get this from the NIB, but this wasn't working.
    [autocompleterNib instantiateWithOwner:self options:nil];
#else    
    autocompleterTableView = [[UITableView alloc]initWithFrame:CGRectMake(0.0, 44.0, 320.0, 308.0) style:UITableViewStylePlain];
    autocompleterTableView.backgroundColor = self.view.backgroundColor;
    autocompleterTableView.dataSource = self;
    autocompleterTableView.delegate = self;
#endif // AUTOCOMPLETER_FROM_NIB
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
    NSLog(@"search bar text changed to \"%@\"", theSearchText);
    
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

- (void)loadComplete:(Model *)model
{
    Autocompleter* theAutocompleter = (Autocompleter*)model;
    /*
     * Ignore old responses.
     */
    if (!editing || ![searchBar isFirstResponder] || 
        theAutocompleter.seqNum <= autocompleter.seqNum || 
        searchBar.text.length == 0) return ;
    
    [self setAutocompleter:theAutocompleter];    
    autocompleterTableView.hidden = NO;
    CGRect frame = CGRectMake(0.0, 44.0, 320.0, 44 * ([self tableView:autocompleterTableView numberOfRowsInSection:0]+1));
    autocompleterTableView.frame = frame;
    
    NSLog(@"autocompleter at (%f, %f) %fx%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    [autocompleterTableView reloadData];
}

- (IBAction)showFAQ:(id)sender 
{
    [_navigationController pushViewController:[[[FAQViewController_iPad alloc] initWithNibName:@"FAQViewController_iPad" bundle:nil]autorelease] animated:YES];
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
    [self.navigationController pushViewController:searchViewController animated: YES];
}

@end
