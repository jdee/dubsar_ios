//
//  DubsarNavigationController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DubsarNavigationController_iPad.h"

@implementation DubsarNavigationController_iPad
@synthesize forwardStack;
@synthesize searchBar;
@synthesize searchToolbar;
@synthesize titleLabel;
@synthesize backBarButtonItem;
@synthesize fwdBarButtonItem;

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        forwardStack = [[ForwardStack alloc]init];
        
        [self setNavigationBarHidden:YES animated:NO];
        
        nib = [UINib nibWithNibName:@"DubsarNavigationController_iPad" bundle:nil];
        [nib instantiateWithOwner:self options:nil];

        [self addToolbar:rootViewController];
    }
    
    return self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    if (viewController != forwardStack.topViewController) {
        [forwardStack clear];
        fwdBarButtonItem.enabled = NO;
    }
    else {
        [forwardStack popViewController];
        if (forwardStack.count > 0) {
            fwdBarButtonItem.enabled = YES;
        }
    }
    
    backBarButtonItem.enabled = YES;
    [self addToolbar:viewController];
}

- (NSArray*)popToRootViewControllerAnimated:(BOOL)animated
{
    [forwardStack clear];
    backBarButtonItem.enabled = NO;
    fwdBarButtonItem.enabled = NO;
    NSArray* stack = [super popToRootViewControllerAnimated:animated];
    [self addToolbar:self.topViewController];
    return stack;
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    [forwardStack pushViewController:self.topViewController];
    
    UIViewController* viewController = [super popViewControllerAnimated:animated];

    fwdBarButtonItem.enabled = YES;
    backBarButtonItem.enabled = self.viewControllers.count > 1;
    [self addToolbar:self.topViewController];
    return viewController;
}

- (IBAction)toggleSearchBar:(id)sender
{
    searchBar.hidden = ! searchBar.hidden;
}

- (void)dealloc 
{
    [backBarButtonItem release];
    [fwdBarButtonItem release];
    [forwardStack release];
    [searchToolbar release];
    [searchBar release];
    [titleLabel release];
    [nib release];
    [super dealloc];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
}

- (void)addToolbar:(UIViewController *)viewController
{
    [viewController.view addSubview:searchToolbar];
    titleLabel.title = viewController.title;
}

- (IBAction)back:(id)sender
{
    [self popViewControllerAnimated:YES];
}

- (IBAction)home:(id)sender 
{
    [self popToRootViewControllerAnimated:YES];
}

- (IBAction)forward:(id)sender
{
    [self pushViewController:forwardStack.topViewController animated:YES];
}

@end
