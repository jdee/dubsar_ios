//
//  LicenseViewController.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchBarManager_iPhone;

@interface LicenseViewController_iPhone : UIViewController <UISearchBarDelegate> {
    UISearchBar *searchBar;
}

@property (nonatomic, retain) SearchBarManager_iPhone* searchBarManager;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

- (void)createToolbarItems;
- (void)loadRootController;


@end
