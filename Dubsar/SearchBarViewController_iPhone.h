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

@protocol AutocompleteDelegate
- (void)autocompleterFinished:(Autocompleter*)theAutocompleter;
@end

@interface AutocompleterProxy : NSObject<LoadDelegate> {
    
}
@property (nonatomic, assign) id<AutocompleteDelegate> delegate;
@end

@interface SearchBarViewController_iPhone : UIViewController <LoadDelegate, UISearchBarDelegate, AutocompleteDelegate> {
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

@end
