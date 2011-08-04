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

#import "AboutViewController_iPad.h"
#import "Dubsar.h"
#import "DubsarAppDelegate_iPad.h"
#import "LicenseViewController_iPad.h"

@implementation AboutViewController_iPad
@synthesize versionLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"About Dubsar for iPad";
        
        
#if 0
        DubsarAppDelegate_iPad* delegate = UIApplication.sharedApplication.delegate;
        
        UIBarButtonItem* forwardButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Forward" style:UIBarButtonItemStyleBordered target:delegate action:@selector(forward)]autorelease];
        self.navigationItem.rightBarButtonItem = forwardButtonItem;
#endif

    }
    return self;
}

- (void)dealloc
{
    [versionLabel release];
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
    
    versionLabel.text = [NSString stringWithFormat:@"Dubsar for iPad Version %@", VERSION];
}

- (void)viewDidUnload
{
    [self setVersionLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)showLicense:(id)sender 
{
    LicenseViewController_iPad* licenseViewController = [[[LicenseViewController_iPad alloc] initWithNibName:@"LicenseViewController_iPad" bundle:nil]autorelease];
    [self.navigationController pushViewController:licenseViewController animated:YES];
}
@end
