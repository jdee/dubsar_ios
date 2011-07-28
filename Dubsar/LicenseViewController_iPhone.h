//
//  LicenseViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LicenseViewController_iPhone : UIViewController <UISearchBarDelegate> {
    UIScrollView *licenseScrollView;
    UIView *licenseView;
}

- (IBAction)dismiss:(id)sender;
@property (nonatomic, retain) IBOutlet UIScrollView *licenseScrollView;
@property (nonatomic, retain) IBOutlet UIView *licenseView;

@end
