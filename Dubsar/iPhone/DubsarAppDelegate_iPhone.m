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
#import "DubsarNavigationController_iPhone.h"
#import "DubsarViewController_iPhone.h"

@implementation DubsarAppDelegate_iPhone

@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    DubsarViewController_iPhone *rootViewController = [[DubsarViewController_iPhone alloc]
                                              initWithNibName:@"DubsarViewController_iPhone" bundle:nil];
    UINavigationController* navigationController = [[[DubsarNavigationController_iPhone alloc]initWithRootViewController:rootViewController]autorelease];
    [rootViewController release];
   
    [self.window setRootViewController:navigationController];
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)dealloc
{
    [_navigationController release];
	[super dealloc];
}

@end
