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
    UIView *licenseView;
    UIScrollView *licenseScrollView;
    UIView *licenseText;
}

@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UILabel *copyrightLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *aboutToolbar;
@property (nonatomic, assign) UIViewController* mainViewController;
@property (nonatomic, retain) IBOutlet UIView *licenseView;
@property (nonatomic, retain) IBOutlet UIScrollView *licenseScrollView;
@property (nonatomic, retain) IBOutlet UIView *licenseText;

- (IBAction)showLicense:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)showAbout:(id)sender;

@end
