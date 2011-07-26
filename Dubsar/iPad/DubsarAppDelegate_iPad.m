//
//  DubsarAppDelegate_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "DubsarAppDelegate_iPad.h"
#import "DubsarViewController_iPad.h"
#import "SearchBarViewController_iPad.h"

@implementation DubsarAppDelegate_iPad

@synthesize navigationController = _navigationController;
@synthesize splitViewController = _splitViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    SearchBarViewController_iPad* searchBarViewController = [[SearchBarViewController_iPad alloc]initWithNibName:@"SearchBarViewController_iPad" bundle:nil];
    DubsarViewController_iPad* dubsarViewController = [[DubsarViewController_iPad alloc]initWithNibName:@"DubsarViewController_iPad" bundle:nil];
    
    _navigationController = [[UINavigationController alloc]initWithRootViewController:dubsarViewController];
    
    _splitViewController = [[UISplitViewController alloc]init];
    _splitViewController.viewControllers = [NSArray arrayWithObjects:searchBarViewController, _navigationController, nil];
    
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
