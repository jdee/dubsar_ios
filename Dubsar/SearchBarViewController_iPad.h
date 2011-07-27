//
//  SearchBarViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

// #define to load the autocompleter's table view from a NIB file
// instead of creating it programmatically
#undef AUTOCOMPLETER_FROM_NIB
@class Autocompleter;

@interface SearchBarViewController_iPad : UIViewController <LoadDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate> {
    
    bool editing;
    UISearchBar *searchBar;
    UITableView *autocompleterTableView;
    UISwitch *caseSwitch;
#ifdef AUTOCOMPLETER_FROM_NIB
    UINib* autocompleterNib;
#endif // AUTOCOMPLETER_FROM_NIB
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
