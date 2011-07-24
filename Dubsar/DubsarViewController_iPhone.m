//
//  DubsarViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "DubsarViewController_iPhone.h"
#import "LicenseViewController_iPhone.h"
#import "SearchBarManager_iPhone.h"

@implementation DubsarViewController_iPhone

@synthesize searchBarManager;
@synthesize searchBar;
@synthesize segmentedControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Home";
        UIImage* image = [UIImage imageNamed:@"dubsar-link.png"];
        self.navigationItem.titleView = [[UIImageView alloc]initWithImage:image];
        [self createToolbarItems];
    }
    return self;
}

- (void)dealloc
{
    [searchBarManager release];
    [segmentedControl release];
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
    searchBarManager = [[SearchBarManager_iPhone alloc]initWithSearchBar:searchBar navigationController:self.navigationController];
}

- (void)viewDidUnload
{
    [self setSearchBarManager:nil];
    [self setSegmentedControl:nil];
    [self setSearchBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    segmentedControl.selectedSegmentIndex = UISegmentedControlNoSegment;
    searchBar.text = @"";
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    
    return NO;
}

- (void)displayLicense 
{
    [self.navigationController pushViewController:[[LicenseViewController_iPhone alloc]
            initWithNibName:@"LicenseViewController_iPhone" bundle:nil] animated: YES];
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

- (void)createToolbarItems
{
    UIBarButtonItem* licenseButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"License" style:UIBarButtonItemStyleBordered target:self action:@selector(displayLicense)];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObject:licenseButtonItem];
    
    self.toolbarItems = buttonItems.retain;
}

@end
