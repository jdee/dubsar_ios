//
//  DubsarAppDelegate_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "DubsarAppDelegate_iPad.h"
#import "DubsarViewController_iPad.h"

@implementation DubsarAppDelegate_iPad

@synthesize dubsarViewController=_dubsarViewController;
@synthesize splitViewController = _splitViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    self.window.rootViewController = _splitViewController;    
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)dealloc
{
    [_dubsarViewController dealloc];
    [_splitViewController release];
	[super dealloc];
}

@end
