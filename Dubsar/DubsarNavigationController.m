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

#import "DubsarNavigationController.h"

@implementation DubsarNavigationController
@synthesize forwardStack;

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        // Initialization code here.
        forwardStack = [[ForwardStack alloc]init];
    }
    
    return self;
}

- (void)dealloc
{
    [forwardStack release];
    [super dealloc];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super pushViewController:viewController animated:animated];
    if (viewController != forwardStack.topViewController) {
        [forwardStack clear];
    }
    else {
        [forwardStack popViewController];
        if (forwardStack.count > 0) [self addForwardButton];
    }
    
    if (self.viewControllers.count > 1) [self addBackButton];
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    [forwardStack pushViewController:self.topViewController];
    NSLog(@"pushed view controller %@ onto forward stack", self.topViewController.title);
    
    [super popViewControllerAnimated:animated];
    [self addForwardButton];
    return forwardStack.topViewController;
}

- (NSArray*)popToRootViewControllerAnimated:(BOOL)animated
{
    [forwardStack clear];
    NSArray* stack = [super popToRootViewControllerAnimated:animated];
    self.topViewController.navigationItem.leftBarButtonItem = nil;
    self.topViewController.navigationItem.rightBarButtonItem = nil;
    return stack;
}

- (void)addBackButton
{
    UIImage* backButtonImage = [UIImage imageNamed:@"wedge-gray-l.png"];
    UIBarButtonItem* backButtonItem = [[[UIBarButtonItem alloc]initWithImage:backButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(back)]autorelease];
    
    self.topViewController.navigationItem.leftBarButtonItem = backButtonItem;
    
}

- (void)addForwardButton
{
    UIImage* forwardButtonImage = [UIImage imageNamed:@"wedge-gray-r.png"];
    UIBarButtonItem* forwardButtonItem = [[[UIBarButtonItem alloc]initWithImage:forwardButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(forward)]autorelease];
                                           
    self.topViewController.navigationItem.rightBarButtonItem = forwardButtonItem;
}

- (void)forward
{
    [self pushViewController:forwardStack.topViewController animated:YES];
}

- (void)back
{
    [self popViewControllerAnimated:YES];
    if (self.viewControllers.count == 1) {
        self.topViewController.navigationItem.leftBarButtonItem = nil;
    }
}

@end
