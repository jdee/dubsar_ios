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

#import "AboutViewController_iPhone.h"
#import "Dubsar.h"

@implementation AboutViewController_iPhone
@synthesize versionLabel;
@synthesize copyrightLabel;
@synthesize aboutToolbar;
@synthesize licenseToolbar;
@synthesize mainViewController;
@synthesize licenseView;
@synthesize licenseScrollView;
@synthesize licenseText;
@synthesize aboutText;
@synthesize appStoreButton;
@synthesize aboutScrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewController:(UIViewController *)viewController
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [versionLabel release];
    [licenseView release];
    [licenseScrollView release];
    [licenseText release];
    [copyrightLabel release];
    [aboutToolbar release];
    [aboutText release];
    [aboutScrollView release];
    [licenseToolbar release];
    [appStoreButton release];
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
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    // NSLog(@"screen height: %f", bounds.size.height);
    
    // UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    [licenseScrollView setContentSize:CGSizeMake(bounds.size.width, 743.0)];
    [licenseScrollView addSubview:licenseText];
    [licenseView setHidden:YES];
    [self.view addSubview:licenseView];
    
    [aboutScrollView setContentSize:CGSizeMake(bounds.size.width, bounds.size.height-64.0)];
    [aboutScrollView addSubview:aboutText];
    
    NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    versionLabel.text = [NSString stringWithFormat:@"Version %@", version];
}

- (void)viewDidUnload
{
    [self setVersionLabel:nil];
    [self setLicenseView:nil];
    [self setLicenseScrollView:nil];
    [self setLicenseText:nil];
    [self setCopyrightLabel:nil];
    [self setAboutToolbar:nil];
    [self setAboutText:nil];
    [self setAboutScrollView:nil];
    [self setLicenseToolbar:nil];
    [self setAppStoreButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    
    return NO;
}

- (IBAction)showLicense:(id)sender
{
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromRight 
                    animations:^{
                        versionLabel.hidden = YES;
                        copyrightLabel.hidden = YES;
                        aboutToolbar.hidden = YES;
                        licenseView.hidden = NO;
                    } completion:nil];
}

- (IBAction)dismiss:(id)sender 
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending) {
        // iOS 5.0+
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        // iOS 4.x
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (IBAction)showAbout:(id)sender
{
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromLeft 
                    animations:^{
                        versionLabel.hidden = NO;
                        copyrightLabel.hidden = NO;
                        aboutToolbar.hidden = NO;
                        licenseView.hidden = YES;
                    } completion:nil];
}

- (IBAction)viewInAppStore:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(launchAppStore:) toTarget:self withObject:nil];
}

- (void)launchAppStore:(id)arg
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];
    [appStoreButton setEnabled:NO];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
    [appStoreButton setEnabled:YES];
    [pool release];
}
@end
