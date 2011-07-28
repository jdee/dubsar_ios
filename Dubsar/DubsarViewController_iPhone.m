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

#import "DubsarViewController_iPhone.h"
#import "FAQViewController_iPhone.h"
#import "LicenseViewController_iPhone.h"

@implementation DubsarViewController_iPhone

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Home";
        UIImage* image = [UIImage imageNamed:@"dubsar-link-hr.png"];
        UIImageView* titleView = [[[UIImageView alloc]initWithImage:image]autorelease];
        CGRect frame = titleView.frame;
        frame.size = CGSizeMake(88.0, 20.0);
        titleView.frame = frame;
        self.navigationItem.titleView = titleView;
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

- (void)displayFAQ
{
    [self presentModalViewController:[[[FAQViewController_iPhone alloc]
            initWithNibName:@"FAQViewController_iPhone" bundle:nil]autorelease] animated: YES];    
}

- (void)displayLicense 
{
    [self presentModalViewController:[[[LicenseViewController_iPhone alloc]
            initWithNibName:@"LicenseViewController_iPhone" bundle:nil]autorelease] animated: YES];
}

- (void)createToolbarItems
{
    UIBarButtonItem* faqButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"FAQ" style:UIBarButtonItemStyleBordered target:self action:@selector(displayFAQ)]autorelease];
    UIBarButtonItem* licenseButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"License" style:UIBarButtonItemStyleBordered target:self action:@selector(displayLicense)]autorelease];
    
    NSMutableArray* buttonItems = [NSMutableArray array];
    [buttonItems addObject:faqButtonItem];
    [buttonItems addObject:licenseButtonItem];
    
    self.toolbarItems = buttonItems.retain;
}

@end
