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

#import "Autocompleter.h"
#import "AutocompleterPopoverViewController_iPad.h"
#import "DubsarNavigationController_iPad.h"
#import "SearchViewController_iPad.h"

@implementation DubsarNavigationController_iPad
@synthesize forwardStack;
@synthesize searchBar;
@synthesize searchToolbar;
@synthesize titleLabel;
@synthesize backBarButtonItem;
@synthesize fwdBarButtonItem;
@synthesize _searchText;
@synthesize autocompleter;
@synthesize popoverController;

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        forwardStack = [[ForwardStack alloc]init];
        
        [self setNavigationBarHidden:YES animated:NO];
        
        nib = [UINib nibWithNibName:@"DubsarNavigationController_iPad" bundle:nil];
        [nib instantiateWithOwner:self options:nil];

        [self addToolbar:rootViewController];
        
        // let the autocompleter view controller handle the table view
        AutocompleterPopoverViewController_iPad* viewController = [[[AutocompleterPopoverViewController_iPad alloc]initWithNibName:@"AutocompleterPopoverViewController_iPad" bundle:nil]autorelease];
        autocompleterTableView = (UITableView*)viewController.view;
        viewController.searchBar = searchBar;
        viewController.navigationController = self;
        
        popoverController = [[UIPopoverController alloc]initWithContentViewController:viewController];
        popoverController.delegate = self;
        viewController.popoverController = popoverController;
        popoverController.popoverContentSize = CGSizeMake(320.0, 440.0);
        
        editing = false;
    }
    
    return self;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSLog(@"called pushViewController");
    [super pushViewController:viewController animated:animated];
    
    if (viewController != forwardStack.topViewController) {
        // should already have a gesture recognizer from the first
        // time it was pushed
        [self addGestureRecognizerToView:viewController.view];
    }
    
    if (viewController != forwardStack.topViewController) {
        [forwardStack clear];
        fwdBarButtonItem.enabled = NO;
    }
    else {
        [viewController.view setNeedsDisplay];
        [forwardStack popViewController];
        fwdBarButtonItem.enabled = forwardStack.count > 0;
    }
    
    backBarButtonItem.enabled = YES;
    [self addToolbar:viewController];
    
    originalFrame = self.topViewController.view.frame;
}

- (NSArray*)popToRootViewControllerAnimated:(BOOL)animated
{
    [forwardStack clear];
    backBarButtonItem.enabled = NO;
    fwdBarButtonItem.enabled = NO;
    NSArray* stack = [super popToRootViewControllerAnimated:animated];
    [self addToolbar:self.topViewController];
    
    originalFrame = self.topViewController.view.frame;

    return stack;
}

- (UIViewController*)popViewControllerAnimated:(BOOL)animated
{
    [forwardStack pushViewController:self.topViewController];
    
    UIViewController* viewController = [super popViewControllerAnimated:animated];

    fwdBarButtonItem.enabled = YES;
    backBarButtonItem.enabled = self.viewControllers.count > 1;
    [self addToolbar:self.topViewController];
    
    originalFrame = self.topViewController.view.frame;

    return viewController;
}

- (void)dealloc 
{
    [_searchText release];
    [popoverController release];
    [backBarButtonItem release];
    [fwdBarButtonItem release];
    [forwardStack release];
    [searchToolbar release];
    [searchBar release];
    [titleLabel release];
    [nib release];
    [super dealloc];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    popoverWasVisible = popoverController.popoverVisible;
    [popoverController dismissPopoverAnimated:YES];
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    if (popoverWasVisible) {
        [popoverController presentPopoverFromRect:searchBar.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    
    originalFrame = self.topViewController.view.frame;
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

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [theSearchBar resignFirstResponder];
    [popoverController dismissPopoverAnimated:YES];
    
    SearchViewController_iPad* searchViewController = [[SearchViewController_iPad alloc]initWithNibName:@"SearchViewController_iPad" bundle:nil text:_searchText matchCase:NO];
    [searchViewController load];
    [self pushViewController:searchViewController animated:YES];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    editing = true;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    editing = false;
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    _searchText = [theSearchText copy];
    
    if (!editing) return;
    
    if (theSearchText.length > 0) {
        Autocompleter* _autocompleter = [[Autocompleter autocompleterWithTerm:theSearchText matchCase:NO]retain];
        _autocompleter.delegate = self;
        [_autocompleter load];
    }
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return theSearchBar == searchBar;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{    
    Autocompleter* theAutocompleter = (Autocompleter*)model;
    /*
     * Ignore old responses.
     */
    if (!editing || ![searchBar isFirstResponder] || 
        theAutocompleter.seqNum <= autocompleter.seqNum || 
        searchBar.text.length == 0) return ;
    
    [self setAutocompleter:theAutocompleter];
    [theAutocompleter release];
    
    AutocompleterPopoverViewController_iPad* viewController = (AutocompleterPopoverViewController_iPad*)popoverController.contentViewController;
    
    viewController.autocompleter = autocompleter;
    [autocompleterTableView reloadData];
    [popoverController presentPopoverFromRect:searchBar.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)addGestureRecognizerToView:(UIView *)view
{
    UIPanGestureRecognizer* recognizer = [[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGesture:)]autorelease];
    [view addGestureRecognizer:recognizer];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    CGPoint translate = [sender translationInView:self.view];
    
    CGRect newFrame = originalFrame;
    newFrame.origin.x += translate.x;
    sender.view.frame = newFrame;
    
    if (sender.state != UIGestureRecognizerStateEnded) return;
    
    if (newFrame.origin.x <= -0.5*newFrame.size.width && fwdBarButtonItem.enabled) {
        [self forward:nil];
    }
    else if (newFrame.origin.x >= 0.5*newFrame.size.width && backBarButtonItem.enabled) {
        [self back:nil];
    }
    else {
        // snap back
        sender.view.frame = originalFrame;
    }
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![touch.view isKindOfClass:UIScrollView.class];
}

@end
