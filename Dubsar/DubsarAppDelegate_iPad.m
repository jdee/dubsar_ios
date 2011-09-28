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

#import "DubsarAppDelegate_iPad.h"
#import "DubsarNavigationController_iPad.h"
#import "DubsarViewController_iPad.h"
#import "SearchBarViewController_iPad.h"

@implementation DubsarAppDelegate_iPad

@synthesize navigationController = _navigationController;
@synthesize splitViewController = _splitViewController;
@synthesize searchBarViewController = _searchBarViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    _searchBarViewController = [[[SearchBarViewController_iPad alloc]initWithNibName:@"SearchBarViewController_iPad" bundle:nil]autorelease];
    DubsarViewController_iPad* dubsarViewController = [[[DubsarViewController_iPad alloc]initWithNibName:@"DubsarViewController_iPad" bundle:nil]autorelease];
    
    _navigationController = [[DubsarNavigationController_iPad alloc]initWithRootViewController:dubsarViewController];
    _searchBarViewController.navigationController = _navigationController;
    
    _splitViewController = [[UISplitViewController alloc]init];
    _splitViewController.viewControllers = [NSArray arrayWithObjects:_searchBarViewController, _navigationController, nil];
    
    self.window.rootViewController = _splitViewController;    
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)dealloc
{
    [_navigationController release];
    [_splitViewController release];
	[super dealloc];
}

@end
