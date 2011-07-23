//
//  SearchBarManager.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/21/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Search.h"
#import "SearchBarManager.h"
#import "SearchViewController.h"

@implementation SearchBarManager
@synthesize viewController=_viewController;
@synthesize searchBar;

+ (id)managerWithSearchBar:(UISearchBar *)theSearchBar viewController:(UIViewController *)theViewController
{
    return [[self alloc]initWithSearchBar:theSearchBar viewController:theViewController];
}

- (id)initWithSearchBar:(UISearchBar *)theSearchBar viewController:(UIViewController *)theViewController
{
    self = [super init];
    if (self) {
        searchBar = theSearchBar;
        _viewController = theViewController;
    }
    return self;
}

- (void)dealloc
{
    [_viewController release];
    [searchBar release];
    [super dealloc];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    
    [theSearchBar resignFirstResponder];
    [_viewController dismissModalViewControllerAnimated:NO];
    
    // new modal SearchViewController for this search
    NSLog(@"presenting modal view controller for \"%@\"", theSearchBar.text);
    SearchViewController* searchViewController = [[SearchViewController alloc] initWithNibName: @"SearchViewController" bundle: nil text: theSearchBar.text viewController: _viewController];
    [_viewController presentModalViewController:searchViewController animated: YES];
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
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return theSearchBar == searchBar;
}

@end
