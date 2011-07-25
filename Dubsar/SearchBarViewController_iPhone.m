//
//  SearchBarViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/24/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Autocompleter.h"
#import "SearchBarViewController_iPhone.h"
#import "SearchViewController_iPhone.h"

@implementation AutocompleterProxy
@synthesize delegate;

- (void)loadComplete:(Model *)model
{
    if (delegate) [delegate autocompleterFinished:(Autocompleter*)model];
}
@end

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
        
        autocompleterNib = [UINib nibWithNibName:@"AutocompleterView" bundle:nil];
    }
    return self;
}

- (void)dealloc
{
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
    // Do any additional setup after loading the view from its nib.
    [self createToolbarItems];
    self.navigationController.navigationBar.tintColor = searchBar.tintColor;
    self.navigationController.toolbar.tintColor = searchBar.tintColor;
}

- (void)viewWillAppear:(BOOL)animated
{
    [autocompleterTableView removeFromSuperview];
    [searchBar resignFirstResponder];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    
    [theSearchBar resignFirstResponder];
    [autocompleterTableView removeFromSuperview];
    
    // new SearchViewController for this search
    NSLog(@"presenting view controller for \"%@\"", theSearchBar.text);
    SearchViewController_iPhone* searchViewController = [[SearchViewController_iPhone alloc] initWithNibName: @"SearchViewController_iPhone" bundle: nil text: theSearchBar.text];
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
        Autocompleter* _autocompleter = [[Autocompleter autocompleterWithTerm:theSearchText]retain];
        _autocompleter.delegate = proxy;
        [_autocompleter load];
    }
    else {
        [autocompleterTableView removeFromSuperview];
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

- (void)createToolbarItems
{
    UIBarButtonItem* homeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObject:homeButtonItem];
    
    self.toolbarItems = buttonItems;
}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)autocompleterFinished:(Autocompleter *)theAutocompleter
{
    /*
     * Ignore old responses.
     */
    if (theAutocompleter.seqNum <= autocompleter.seqNum || 
        searchBar.text.length == 0) return ;
    
    [self setAutocompleter:theAutocompleter];
    [self.view addSubview:autocompleterTableView];
    [autocompleterTableView reloadData];
}

- (void)viewDidUnload {
    [self setAutocompleterTableView:nil];
    [super viewDidUnload];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    return autocompleter.results.count < 3 ? autocompleter.results.count : 3;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    return @"suggestions";
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellType = @"autocomplete";
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [autocompleter.results objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [searchBar resignFirstResponder];
    [autocompleterTableView removeFromSuperview];

    if (!autocompleter.complete || !autocompleter.results) {
        return;
    }
    
    NSString* text = [autocompleter.results objectAtIndex:indexPath.row];
    SearchViewController_iPhone* searchViewController = [[SearchViewController_iPhone alloc] initWithNibName: @"SearchViewController_iPhone" bundle: nil text: text];
    [self.navigationController pushViewController:searchViewController animated: YES];
}

@end
