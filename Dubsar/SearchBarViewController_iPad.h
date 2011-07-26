//
//  SearchBarViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

@class Autocompleter;

@interface SearchBarViewController_iPad : UIViewController <LoadDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate> {
    
    UISearchBar *searchBar;
    UITableView *autocompleterTableView;
}

@property (nonatomic, retain) Autocompleter* autocompleter;
@property (nonatomic, retain) NSString* searchText;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *autocompleterTableView;

- (void)loadComplete:(Model *)model;

@end
