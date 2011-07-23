//
//  LicenseViewController.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "LicenseViewController.h"
#import "SearchBarManager.h"

@implementation LicenseViewController
@synthesize searchBarManager;
@synthesize searchBar;
@synthesize viewController=_viewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewController:(UIViewController *)theViewController
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"License";
        _viewController = theViewController;
    }
    return self;
}

- (void)dealloc
{
    [_viewController release];
    [searchBarManager release];
    [searchBar release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    searchBarManager = [[SearchBarManager alloc]initWithSearchBar:searchBar viewController:_viewController];
}

- (void)viewDidUnload
{
    [self setSearchBarManager:nil];
    [self setSearchBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    
    return NO;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarTextDidBeginEditing:theSearchBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarTextDidEndEditing:theSearchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarCancelButtonClicked:theSearchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarSearchButtonClicked:theSearchBar];
}

- (IBAction)doneSelected:(id)sender 
{
    [_viewController dismissModalViewControllerAnimated:YES];
}
@end
