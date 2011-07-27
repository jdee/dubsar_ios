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
@synthesize segmentedControl;
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
    [autocompleter release];
    [_searchText release];
    [searchBar release];
    [autocompleterTableView release];
    [caseSwitch release];
    [segmentedControl release];
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
    [self setSegmentedControl:nil];
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

- (IBAction)segmentedControlActivated:(id)sender 
{
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            [_navigationController popToRootViewControllerAnimated:YES];
            break;
        case 1:
            [self showFAQ:sender];
            break;
    }
}

- (void)resetSegmentedControl:(id)arg
{
    segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment;
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
    FAQViewController_iPad* faqViewController = [[[FAQViewController_iPad alloc] initWithNibName:@"FAQViewController_iPad" bundle:nil]autorelease];
    faqViewController.searchBarViewController = self;
    [_navigationController pushViewController:faqViewController animated:YES];
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
