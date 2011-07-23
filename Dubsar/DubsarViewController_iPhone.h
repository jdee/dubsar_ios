//
//  DubsarViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LicenseViewController;
@class SearchBarManager;


@interface DubsarViewController_iPhone : UIViewController <UISearchBarDelegate> {
    UISegmentedControl *segmentedControl;
    UISearchBar *searchBar;
}
@property (nonatomic, retain) SearchBarManager* searchBarManager;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) LicenseViewController* licenseViewController;

- (IBAction)licenseSelected:(id)sender;
- (void)displayLicense;
@end
