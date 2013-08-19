/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
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

#import "Autocompleter.h"
#import "AutocompleterPopoverViewController_iPad.h"
#import "DubsarAppDelegate_iPad.h"
#import "SearchViewController_iPad.h"

@implementation AutocompleterPopoverViewController_iPad
@synthesize autocompleter;
@synthesize navigationController;
@synthesize searchBar;
@synthesize popoverController;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 440.0);
    }
    return self;
}

- (void)dealloc
{
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!autocompleter) return 0;
    
    if (!autocompleter.complete || autocompleter.error) return 1;
    
    return autocompleter.results.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    if (!autocompleter.complete) {
        static NSString* indicatorType = @"indicator";
        cell = [tableView dequeueReusableCellWithIdentifier:indicatorType];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indicatorType]autorelease];
        }
        
        UIActivityIndicatorView* indicatorView = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]autorelease];
        [indicatorView startAnimating];
        indicatorView.frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        [cell.contentView addSubview:indicatorView];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    static NSString* cellType = @"autocompleter";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault   reuseIdentifier:cellType]autorelease];
    }
    
    DubsarAppDelegate_iPad* appDelegate = (DubsarAppDelegate_iPad*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    
    int index = indexPath.row;
    if (autocompleter.error) {
        cell.textLabel.text = autocompleter.errorMessage;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.textLabel.text = [autocompleter.results objectAtIndex:index];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!autocompleter.complete || !autocompleter.results || indexPath.row >= autocompleter.results.count) {
        return;
    }
    
    [popoverController dismissPopoverAnimated:YES];
    
    NSString* text = [autocompleter.results objectAtIndex:indexPath.row];
    // [searchBar setText:text];
    [searchBar resignFirstResponder];

#ifdef DEBUG
    NSLog(@"searching for \"%@\"", text);
#endif // DEBUG
    
    SearchViewController_iPad* searchViewController = [[[SearchViewController_iPad alloc] initWithNibName: @"SearchViewController_iPad" bundle: nil text:[text lowercaseString] matchCase:NO]autorelease];
    [searchViewController load];
    [self.navigationController pushViewController:searchViewController animated: YES];
}


@end
