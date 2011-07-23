//
//  LicenseViewController.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchBarManager;

@interface LicenseViewController : UIViewController <UISearchBarDelegate> {
    UISearchBar *searchBar;
}

@property (nonatomic, retain) SearchBarManager* searchBarManager;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;


@end
