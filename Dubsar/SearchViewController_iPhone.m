//
//  SearchViewController.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <stdlib.h>

#import "DubsarViewController_iPhone.h"
#import "SearchViewController_iPhone.h"
#import "Search.h"
#import "Word.h"
#import "WordViewController_iPHone.h"


@implementation SearchViewController_iPhone

@synthesize search;
@synthesize pageLabel = _pageLabel;
@synthesize searchText=_searchText;
@synthesize searchResultsTableView=_tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString*)theSearchText 
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _searchText = [theSearchText retain];
        
        // set up a new search request to the server asynchronously
        search = [[Search searchWithTerm:_searchText matchCase:NO] retain];
        search.delegate = self;
        
        // send the request
        [search load];
        
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", _searchText];
    }
    return self;
}

- (void)dealloc
{
    [_tableView release];
    [search release];
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
}

- (void)viewDidUnload
{
    [self setPageLabel:nil];
    [self setSearchBar:nil];
    [self setSearchResultsTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self adjustPageLabel];
    [self searchBar].text = [_searchText copy];
    [_tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar
{
    if (theSearchBar != [self searchBar]) return;
    
    _searchText = @"";
    [self adjustPageLabel];
    [super searchBarCancelButtonClicked:theSearchBar];
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)searchText
{
    if (theSearchBar != [self searchBar]) return;
    NSLog(@"search text changed in search view search bar");
    _searchText = [searchText copy];
    [super searchBar:theSearchBar textDidChange:searchText];
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != _tableView) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    int index = indexPath.section;
    Word* word = [search.results objectAtIndex:index];
    [self.navigationController pushViewController:[[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:word]autorelease] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    if (_tableView != tableView) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{    
    NSInteger sections = search.complete && search.results && search.results.count > 0 ? search.results.count : 1;
    return sections;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != _tableView) {
        return [super tableView:theTableView titleForHeaderInSection:section];
    }
    
    return @"";
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (tableView != _tableView) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    static NSString* cellType = @"search";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
    }
    
    if (!search.complete) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"]autorelease];
        }
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]autorelease];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [cell.contentView addSubview:indicator];
        [indicator startAnimating];
        return cell;
    }
    
    if (search.error) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = search.errorMessage;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        return cell;
    }
    else if (search.results.count == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [NSString stringWithFormat:@"no results for \"%@\"", _searchText];
        return cell;
    }
    
    NSLog(@"have view cell, loading data");

    int index = indexPath.section;
    NSLog(@"looking for index %d", index);
    Word* word = [search.results objectAtIndex:index];
    NSLog(@"found \"%@\"", [word nameAndPos]);
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [word nameAndPos];
    return cell;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)theTableView
{
    if (theTableView != _tableView) {
        return [super sectionIndexTitlesForTableView:theTableView];
    }
    
    NSMutableArray* titles = [NSMutableArray arrayWithCapacity:10];
    if (!search || !search.complete || search.results.count < 10) {
        return titles;
    }
    
    for (int j=0; j<10; ++j) {
        int index = (j*search.results.count)/10;
        Word* word = [search.results objectAtIndex:index];
        NSString* name = word.name;
        NSRange range;
        range.location = 0;
        range.length = name.length > 3 ? 3 : name.length;

        [titles addObject:[name substringWithRange:range]];
    }
    
    return titles;
}

- (NSInteger)tableView:(UITableView*)theTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if (theTableView != _tableView) {
        return [super tableView:theTableView sectionForSectionIndexTitle:title atIndex:index];
    }
    
    NSInteger section = (index*search.results.count)/10;
    Word* word = [search.results objectAtIndex:section];
    NSLog(@"word: \"%@\", title \"%@\"", word.name, title);
    return section;
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

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if (model != search) return;
    
    NSLog(@"search complete");
    
    float height = [self numberOfSectionsInTableView:_tableView]*44.0;
    if (height < self.view.frame.size.height) {
        CGRect frame = _tableView.frame;
        frame.size.height = height;
        _tableView.frame = frame;
    }
    [_tableView reloadData];
}

@end
