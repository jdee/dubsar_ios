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

#import "LoadDelegate.h"
#import "Search.h"
#import "SearchViewController_iPad.h"
#import "Word.h"
#import "WordViewController_iPad.h"


@implementation SearchViewController_iPad

@synthesize search;
@synthesize tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString *)text matchCase:(BOOL)matchCase
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        search = [[Search searchWithTerm:text matchCase:matchCase]retain];
        search.delegate = self;
        
        self.title = [NSString stringWithFormat:@"Search: \"%@\"", text];
    }
    return self;
}

- (void)dealloc
{
    search.delegate = nil;
    [search release];
    [tableView release];
    [super dealloc];
}

- (void)load
{
    [search load];
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (!search.complete || search.error || search.results.count == 0) {
        return 1;  
    }
    
    return search.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!search.complete) {
        static NSString* indicatorType = @"indicator";
        UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:indicatorType];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indicatorType]autorelease];
        }
        
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
        indicator.frame = frame;
        [indicator startAnimating];
        [cell.contentView addSubview:indicator];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    static NSString *CellIdentifier = @"search";
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    if (search.error) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = search.errorMessage;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else if (search.results.count == 0) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [NSString stringWithFormat:@"no results for \"%@\"", search.term];
    }
    else {
        Word* word = [search.results objectAtIndex:indexPath.row];
        cell.textLabel.text = word.nameAndPos;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!search.complete || search.error) return;
    
    Word* word = [search.results objectAtIndex:indexPath.row];
    WordViewController_iPad* wordViewController = [[[WordViewController_iPad alloc] initWithNibName:@"WordViewController_iPad" bundle:nil word:word]autorelease];
    [wordViewController load];
    [self.navigationController pushViewController:wordViewController animated:YES];
}

- (void)loadComplete:(Model*)model withError:(NSString *)error
{
    if (model != search) return;

    if (!model.error) {
        int rows = search.results.count > 1 ? search.results.count : 1 ;
        float height = rows*44.0;
        if (height < self.view.frame.size.height) {
            CGRect frame = tableView.frame;
            frame.size.height = height;
            tableView.frame = frame;
        }
    }
    
    [tableView reloadData];
}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
