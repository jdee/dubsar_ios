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

#import "DubsarAppDelegate_iPhone.h"
#import "Search.h"
#import "SearchApplicationTest_iPhone.h"
#import "SearchViewController_iPhone.h"

@implementation SearchApplicationTest_iPhone

- (void)tearDown
{
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    [appDelegate.navigationController popToRootViewControllerAnimated:NO];
}


/* 
 * https://github.com/jdee/dubsar_ios/issues/16
 * Issue #16: iPhone app crashes if you tap on the screen after "no results" message appears.
 */
- (void)testNoResults
{
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    
    UINavigationController* navigationController = appDelegate.navigationController;
    
    
    // simulate no results
    Search* search = [[[Search alloc]init]autorelease];
    search.term = @"foo";
    search.results = [NSMutableArray array];
    search.error = false;
    search.complete = true;
    search.errorMessage = @"";
    
    SearchViewController_iPhone* viewController = [[[SearchViewController_iPhone alloc]initWithNibName:@"SearchViewController_iPad" bundle:nil]autorelease];
    
    [navigationController pushViewController:viewController animated:NO];
    
    // What now?
    // I want to tap the top row in the table view and make sure that nothing happens.
}

@end
