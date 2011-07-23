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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    DubsarViewController_iPad *aViewController = [[DubsarViewController_iPad alloc]
                                                    initWithNibName:@"DubsarViewController_iPad" bundle:nil];
    [self setDubsarViewController:aViewController];
    [aViewController release];
    self.window.rootViewController = self.dubsarViewController;    
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)dealloc
{
    [_dubsarViewController dealloc];
	[super dealloc];
}

@end
