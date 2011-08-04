//
//  DubsarNavigationController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Autocompleter.h"
#import "AutocompleterPopoverViewController_iPad.h"
#import "DubsarNavigationController_iPad.h"
#import "SearchViewController_iPad.h"

@implementation DubsarNavigationController_iPad
@synthesize forwardStack;
@synthesize searchBar;
@synthesize searchToolbar;
@synthesize titleLabel;
@synthesize backBarButtonItem;
@synthesize fwdBarButtonItem;
@synthesize _searchText;
@synthesize autocompleter;

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        forwardStack = [[ForwardStack alloc]init];
        
        [self setNavigationBarHidden:YES animated:NO];
        
        nib = [UINib nibWithNibName:@"DubsarNavigationController_iPad" bundle:nil];
        [nib instantiateWithOwner:self options:nil];

        [self addToolbar:rootViewController];
        
        // let the autocompleter view controller handle the search bar
        AutocompleterPopoverViewController_iPad* viewController = [[[AutocompleterPopoverViewController_iPad alloc]initWithNibName:@"AutocompleterPopoverViewController_iPad" bundle:nil]autorelease];
        autocompleterTableView = (UITableView*)viewController.view;
        viewController.searchBar = searchBar;
        viewController.navigationController = self;
        
        popoverController = [[UIPopoverController alloc]initWithContentViewController:viewController];
        viewController.popoverController = popoverController;
        popoverController.popoverContentSize = CGSizeMake(320.0, 440.0);
        
        editing = false;
    }
    
    return self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    if (viewController != forwardStack.topViewController) {
        [forwardStack clear];
        fwdBarButtonItem.enabled = NO;
    }
    else {
        [forwardStack popViewController];
        fwdBarButtonItem.enabled = forwardStack.count > 0;
    }
    
    backBarButtonItem.enabled = YES;
    [self addToolbar:viewController];
}

- (NSArray*)popToRootViewControllerAnimated:(BOOL)animated
{
    [forwardStack clear];
    backBarButtonItem.enabled = NO;
    fwdBarButtonItem.enabled = NO;
    NSArray* stack = [super popToRootViewControllerAnimated:animated];
    [self addToolbar:self.topViewController];
    return stack;
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    [forwardStack pushViewController:self.topViewController];
    
    UIViewController* viewController = [super popViewControllerAnimated:animated];

    fwdBarButtonItem.enabled = YES;
    backBarButtonItem.enabled = self.viewControllers.count > 1;
    [self addToolbar:self.topViewController];
    return viewController;
}

- (void)dealloc 
{
    [_searchText release];
    [popoverController release];
    [backBarButtonItem release];
    [fwdBarButtonItem release];
    [forwardStack release];
    [searchToolbar release];
    [searchBar release];
    [titleLabel release];
    [nib release];
    [super dealloc];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    popoverWasVisible = popoverController.popoverVisible;
    [popoverController dismissPopoverAnimated:YES];    
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (popoverWasVisible) {
        [popoverController presentPopoverFromRect:searchBar.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
}

- (void)addToolbar:(UIViewController *)viewController
{
    [viewController.view addSubview:searchToolbar];
    titleLabel.title = viewController.title;
}

- (IBAction)back:(id)sender
{
    [self popViewControllerAnimated:YES];
}

- (IBAction)home:(id)sender 
{
    [self popToRootViewControllerAnimated:YES];
}

- (IBAction)forward:(id)sender
{
    [self pushViewController:forwardStack.topViewController animated:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar resignFirstResponder];
    
    SearchViewController_iPad* searchViewController = [[SearchViewController_iPad alloc]initWithNibName:@"SearchViewController_iPad" bundle:nil text:_searchText matchCase:NO];
    [searchViewController load];
    [self pushViewController:searchViewController animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar 
{
    theSearchBar.text = @"";
    [theSearchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    editing = true;
    [popoverController presentPopoverFromRect:searchBar.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    theSearchBar.showsCancelButton = YES;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    editing = false;
    theSearchBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    _searchText = [theSearchText copy];
    
    if (!editing) return;
    
    if (theSearchText.length > 0) {
        Autocompleter* _autocompleter = [[Autocompleter autocompleterWithTerm:theSearchText matchCase:NO]retain];
        _autocompleter.delegate = self;
        [_autocompleter load];
    }
    else {
    }
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return theSearchBar == searchBar;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if (error) {
        return;
    }
    Autocompleter* theAutocompleter = (Autocompleter*)model;
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
}


@end
