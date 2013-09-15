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
    
    [licenseView setHidden:YES];
    [self.view addSubview:licenseView];
    
    [licenseText loadHTMLString:self.licenseHtml baseURL:nil];
    
    [aboutScrollView setContentSize:CGSizeMake(bounds.size.width, 743.0 /* bounds.size.height - 64.0 */)];
    [aboutScrollView addSubview:aboutText];
    
    NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    versionLabel.text = [NSString stringWithFormat:@"Version %@", version];
}

- (void)viewDidUnload
{
    [self setVersionLabel:nil];
    [self setLicenseView:nil];
    [self setLicenseText:nil];
    [self setCopyrightLabel:nil];
    [self setAboutToolbar:nil];
    [self setAboutText:nil];
    [self setAboutScrollView:nil];
    [self setLicenseToolbar:nil];
    [self setAppStoreButton:nil];
    [super viewDidUnload];
    // Release any stronged subviews of the main view.
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
        [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
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
    @autoreleasepool {
        [appStoreButton setEnabled:NO];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        [appStoreButton setEnabled:YES];
    }
}

- (NSString *)licenseHtml
{
    return @"<!DOCTYPE html><html><body style='color:#f85400; background-color:#000; font: bold 24pt Trebuchet MS'>"
    "<p>Dubsar is free, open-source software distributed under version 2 of the GNU General Public License.</p><hr/>"
    "<h2>Dubsar Dictionary Project</h2><h3>Copyright &copy; 2010&ndash;2013 Jimmy Dee</h3>"
    "<p>This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.</p>"
    "<p>This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.</p>"
    "<p>You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.</p><hr/>"
    "<p>WordNet&reg; &copy; 2013 The Trustees of Princeton University</p>"
    "<p>WordNet&reg; is available under the WordNet 3.0 License.<hr/>"
    "<p>JSONKit &copy; 2011 John Engelhart</p>"
    "<p>JSONKit is dual licensed under either the terms of the BSD License, or alternatively under the terms of the Apache License, Version 2.0.</p><hr/>"
    "</body></html>";
}

@end
