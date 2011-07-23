//
//  DubsarAppDelegate_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "DubsarAppDelegate_iPhone.h"
#import "DubsarViewController_iPhone.h"

@implementation DubsarAppDelegate_iPhone

@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    DubsarViewController_iPhone *rootViewController = [[DubsarViewController_iPhone alloc]
                                              initWithNibName:@"DubsarViewController_iPhone" bundle:nil];
    UINavigationController* navigationController = [[UINavigationController alloc]initWithRootViewController:rootViewController];
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
