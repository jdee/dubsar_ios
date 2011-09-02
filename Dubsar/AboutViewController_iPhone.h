//
//  AboutViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController_iPhone : UIViewController {
    
    UILabel *versionLabel;
    UILabel *copyrightLabel;
    UIToolbar *aboutToolbar;
    UIToolbar *licenseToolbar;
    UIView *licenseView;
    UIScrollView *licenseScrollView;
    UIView *licenseText;
    UIView *aboutView;
    UIScrollView *aboutScrollView;
    UIButton *appStoreButton;
}

@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UILabel *copyrightLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *aboutToolbar;
@property (nonatomic, retain) IBOutlet UIToolbar *licenseToolbar;
@property (nonatomic, assign) UIViewController* mainViewController;
@property (nonatomic, retain) IBOutlet UIView *licenseView;
@property (nonatomic, retain) IBOutlet UIScrollView *licenseScrollView;
@property (nonatomic, retain) IBOutlet UIView *licenseText;
@property (nonatomic, retain) IBOutlet UIView *aboutText;
@property (nonatomic, retain) IBOutlet UIButton *appStoreButton;
@property (nonatomic, retain) IBOutlet UIScrollView *aboutScrollView;

- (IBAction)showLicense:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)showAbout:(id)sender;
- (IBAction)viewInAppStore:(id)sender;

@end
