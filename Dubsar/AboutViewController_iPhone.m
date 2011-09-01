//
//  AboutViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

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
    
    [licenseScrollView setContentSize:CGSizeMake(320.0, 475.0)];
    [licenseScrollView addSubview:licenseText];
    [licenseView setHidden:YES];
    [self.view addSubview:licenseView];
    
    [aboutScrollView setContentSize:CGSizeMake(320.0, 416.0)];
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
    [self.parentViewController dismissModalViewControllerAnimated:YES];
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
}
@end
