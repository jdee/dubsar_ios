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
@synthesize navigationController=_navigationController;
@synthesize searchBar;

+ (id)managerWithSearchBar:(UISearchBar *)theSearchBar navigationController:(UINavigationController *)theNavigationController
{
    return [[self alloc]initWithSearchBar:theSearchBar navigationController:theNavigationController];
}

- (id)initWithSearchBar:(UISearchBar *)theSearchBar navigationController:(UINavigationController *)theNavigationController
{
    self = [super init];
    if (self) {
        searchBar = theSearchBar;
        _navigationController = theNavigationController;
    }
    return self;
}

- (void)dealloc
{
    [_navigationController release];
    [searchBar release];
    [super dealloc];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != searchBar) return;
    
    [theSearchBar resignFirstResponder];
    [_navigationController dismissModalViewControllerAnimated:NO];
    
    // new modal SearchViewController for this search
    NSLog(@"presenting modal view controller for \"%@\"", theSearchBar.text);
    SearchViewController* searchViewController = [[SearchViewController alloc] initWithNibName: @"SearchViewController" bundle: nil text: theSearchBar.text];
    [_navigationController pushViewController:searchViewController animated: YES];
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
