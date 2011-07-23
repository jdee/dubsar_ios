//
//  SearchViewController.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <stdlib.h>

#import "SearchBarManager.h"
#import "SearchViewController.h"
#import "Search.h"
#import "Word.h"
#import "WordViewController.h"


@implementation SearchViewController

@synthesize search;
@synthesize pageLabel = _pageLabel;
@synthesize searchBarManager;
@synthesize searchText=_searchText;
@synthesize searchDisplayController=_dubsarSearchDisplayController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString*)theSearchText 
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Search Results";
        
        /*
         * The argument (theSearchText) is the content of the search bar from the previous 
         * view that launched this search, not the search bar associated with this
         * controller. That view was just unloaded. We make a copy here.
         */
        _searchText = [[theSearchText copy] retain];
        
        // set up a new search request to the server asynchronously
        search = [[Search searchWithTerm:_searchText] retain];
        search.delegate = self;
        
        // send the request
        [search load];
    }
    return self;
}

- (void)dealloc
{
    [search release];
    [searchBarManager release];
    [_dubsarSearchDisplayController release];
    [_searchText release];
    [_pageLabel release];
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
    // Do any additional setup after loading the view from its nib.
    searchBarManager = [[SearchBarManager managerWithSearchBar:_dubsarSearchDisplayController.searchBar navigationController:self.navigationController] retain];
}

- (void)viewDidUnload
{
    [self setSearchBarManager:nil];
    [self setPageLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self adjustPageLabel];
    _dubsarSearchDisplayController.searchBar.text = [_searchText copy];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    
    return NO;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarSearchButtonClicked:theSearchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar 
{
    if (theSearchBar != _dubsarSearchDisplayController.searchBar) return;

    _searchText = @"";
    [self adjustPageLabel];
    [searchBarManager searchBarCancelButtonClicked:theSearchBar];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar*)theSearchBar
{
    [searchBarManager searchBarTextDidBeginEditing:theSearchBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarTextDidEndEditing:theSearchBar];
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    if (theSearchBar != _dubsarSearchDisplayController.searchBar) return;
    
    _searchText = [theSearchText copy];
    // [self adjustPageLabel];
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [searchBarManager searchBar:theSearchBar shouldChangeTextInRange:range
                       replacementText:text];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    Word* word = [search.results objectAtIndex:index];
    [self.navigationController pushViewController:[[WordViewController alloc]initWithNibName:@"WordViewController" bundle:nil word:word] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    NSInteger rows = tableView == _dubsarSearchDisplayController.searchResultsTableView && search.complete && search.results ? search.results.count : 0;
    NSLog(@"tableView:numberOfRowsInSection: = %d", rows);
    return rows;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (tableView != _dubsarSearchDisplayController.searchResultsTableView) return nil;
    
    static NSString* cellType = @"search";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
    }
    
    NSLog(@"have view cell, loading data");

    int index = indexPath.row;
    NSLog(@"looking for index %d", index);
    Word* word = [search.results objectAtIndex:index];
    NSLog(@"found \"%@\"", [word nameAndPos]);
    
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    cell.textLabel.text = [word nameAndPos];
    return cell;
}

- (void)adjustPageLabel
{
    if (_searchText.length > 0) {
        _pageLabel.text = [NSString stringWithFormat:@"search results for \"%@\"", _searchText];
    }
    else {
        _pageLabel.text = @"enter a word or words";
    }
}

- (void)loadComplete:(id)model
{
    if (model != search) return;
    
    NSLog(@"search complete");
    [_dubsarSearchDisplayController.searchResultsTableView reloadData];
}

@end
