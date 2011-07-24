//
//  SearchBarViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/24/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoadDelegate.h"

@interface SearchBarViewController_iPhone : UIViewController <LoadDelegate, UISearchBarDelegate> {
    UISearchBar *searchBar;
    
}

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

-(void)createToolbarItems;
-(void)loadRootController;


@end
