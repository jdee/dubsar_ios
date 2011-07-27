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
    
    bool editing;
    UISearchBar *searchBar;
    UITableView *autocompleterTableView;
    UISwitch *caseSwitch;
}

@property (nonatomic, assign) UINavigationController* navigationController;
@property (nonatomic, retain) Autocompleter* autocompleter;
@property (nonatomic, retain) NSString* searchText;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *autocompleterTableView;
@property (nonatomic, retain) IBOutlet UISwitch *caseSwitch;

- (void)loadComplete:(Model *)model;
- (IBAction)showFAQ:(id)sender;

@end
