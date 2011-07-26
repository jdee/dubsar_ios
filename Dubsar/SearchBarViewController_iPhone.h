//
//  SearchBarViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/24/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoadDelegate.h"

@class Autocompleter;

@protocol AutocompleterDelegate
- (void)autocompleterFinished:(Autocompleter*)theAutocompleter;
@end

@interface AutocompleterProxy : NSObject<LoadDelegate> {
    
}
@property (nonatomic, assign) id<AutocompleterDelegate> delegate;
@end

@interface SearchBarViewController_iPhone : UIViewController <LoadDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, AutocompleterDelegate> {
    UISearchBar *searchBar;
    UITableView *autocompleterTableView;
    AutocompleterProxy* proxy;
}

@property (nonatomic, retain) Autocompleter* autocompleter;
@property (nonatomic, retain) UINib* autocompleterNib;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *autocompleterTableView;

-(void)createToolbarItems;
-(void)loadRootController;
-(void)initOrientation;
// -(void)orientationChanged:(NSNotification*)notification;

@end
