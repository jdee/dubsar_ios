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

#import "Autocompleter.h"
#import "AutocompleterApplicationTest_iPhone.h"
#import "DubsarAppDelegate_iPhone.h"
#import "DubsarViewController_iPhone.h"

@implementation AutocompleterApplicationTest_iPhone

- (void)tearDown
{
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    [appDelegate.navigationController popToRootViewControllerAnimated:NO];
}


/* 
 * https://github.com/jdee/dubsar_ios/issues/18
 * Issue #18: iPhone app crashes if you select a row from the autocompleter when there are no suggestions
 */
- (void)testNoResults
{
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    
    UINavigationController* navigationController = appDelegate.navigationController;
    
    
    // simulate no results
    Autocompleter* autocompleter = [[Autocompleter autocompleterWithTerm:@"foo" matchCase:NO]retain];
    
    autocompleter.results = [NSMutableArray array];
    
    autocompleter.error = false;
    autocompleter.complete = true;
    autocompleter.errorMessage = nil;
    
    DubsarViewController_iPhone* viewController = [[[DubsarViewController_iPhone alloc]initWithNibName:@"DubsarViewController_iPad" bundle:nil]autorelease];
    [viewController autocompleterFinished:autocompleter withError:nil];
    [navigationController pushViewController:viewController animated:NO];
    
    UITableView* tableView = viewController.autocompleterTableView;
    
    // simulate a tap
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    STAssertNotNil(tableView, @"autocompleter tableView not found");
    STAssertNotNil(tableView.delegate, @"autocompleter tableView delegate not found");
    STAssertNoThrow([tableView.delegate tableView:tableView didSelectRowAtIndexPath:indexPath], @"app crashes if you select a row from the autocompleter when there are no suggestions");
}

@end
