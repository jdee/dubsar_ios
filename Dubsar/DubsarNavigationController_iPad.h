//
//  DubsarNavigationController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 8/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForwardStack.h"
#import "LoadDelegate.h"

@class Autocompleter;

@interface DubsarNavigationController_iPad : UINavigationController <LoadDelegate, UISearchBarDelegate> {
    UIToolbar *searchToolbar;
    UISearchBar *searchBar;
    UIBarButtonItem *titleLabel;
    UIBarButtonItem* backBarButtonItem;
    UIBarButtonItem* fwdBarButtonItem;
    UINib* nib;
    UIPopoverController* popoverController;
    bool editing;
    UITableView* autocompleterTableView;
    bool popoverWasVisible;
}

@property (nonatomic, retain) Autocompleter* autocompleter;
@property (nonatomic, retain) NSString* _searchText;
@property (nonatomic, retain) ForwardStack* forwardStack;
@property (nonatomic, retain) IBOutlet UIToolbar *searchToolbar;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* titleLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* backBarButtonItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* fwdBarButtonItem;

- (void)addToolbar:(UIViewController*)viewController;
- (IBAction)forward:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)home:(id)sender;

@end
