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

#import "DubsarNavigationController_iPhone.h"

@implementation DubsarNavigationController_iPhone
@synthesize forwardStack;

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
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
    UIImage* backButtonImage = [UIImage imageNamed:@"wedge-blue-l-hr.png"];
    UIImage* highlightedImage = [UIImage imageNamed:@"wedge-white-l-hr.png"];
    
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [backButton setImage:backButtonImage forState:UIControlStateNormal];
    [backButton setImage:highlightedImage forState:UIControlStateHighlighted];
    [backButton setImage:backButtonImage forState:UIControlStateSelected];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    backButton.showsTouchWhenHighlighted = NO;
    
    CGRect frame = backButton.frame;
    frame.size = CGSizeMake(37.0, 37.0);
    backButton.frame = frame;


    UIBarButtonItem* backButtonItem = [[[UIBarButtonItem alloc]initWithCustomView:backButton]autorelease];
    
    self.topViewController.navigationItem.leftBarButtonItem = backButtonItem;
}

- (void)addForwardButton
{
    UIImage* fwdButtonImage = [UIImage imageNamed:@"wedge-blue-r-hr.png"];
    UIImage* highlightedImage = [UIImage imageNamed:@"wedge-white-r-hr.png"];

    UIButton* fwdButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [fwdButton setImage:fwdButtonImage forState:UIControlStateNormal];
    [fwdButton setImage:highlightedImage forState:UIControlStateHighlighted];
    [fwdButton setImage:fwdButtonImage forState:UIControlStateSelected];
    [fwdButton addTarget:self action:@selector(forward) forControlEvents:UIControlEventTouchUpInside];
    fwdButton.showsTouchWhenHighlighted = NO;
    
    CGRect frame = fwdButton.frame;
    frame.size = CGSizeMake(37.0, 37.0);
    fwdButton.frame = frame;
    
    
    UIBarButtonItem* fwdButtonItem = [[[UIBarButtonItem alloc]initWithCustomView:fwdButton]autorelease];
    
    self.topViewController.navigationItem.rightBarButtonItem = fwdButtonItem;
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
