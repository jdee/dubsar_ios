//
//  DubsarViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "DubsarViewController_iPhone.h"
#import "LicenseViewController_iPhone.h"

@implementation DubsarViewController_iPhone

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Home";
        UIImage* image = [UIImage imageNamed:@"dubsar-link.png"];
        self.navigationItem.titleView = [[UIImageView alloc]initWithImage:image];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    searchBar.text = @"";
}

- (void)displayLicense 
{
    [self presentModalViewController:[[LicenseViewController_iPhone alloc]
            initWithNibName:@"LicenseViewController_iPhone" bundle:nil] animated: YES];
}

- (void)createToolbarItems
{
    UIBarButtonItem* licenseButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"License" style:UIBarButtonItemStyleBordered target:self action:@selector(displayLicense)];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObject:licenseButtonItem];
    
    self.toolbarItems = buttonItems.retain;
}

@end
