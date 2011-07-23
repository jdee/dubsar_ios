//
//  SearchBarManager.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/21/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SearchViewController;

@interface SearchBarManager : NSObject <UISearchBarDelegate> {
}
@property (nonatomic, retain) UINavigationController* navigationController;
@property (nonatomic, retain) UISearchBar *searchBar;

+ (id)managerWithSearchBar:(UISearchBar*)theSearchBar navigationController:(UINavigationController*)theNavigationController;
- (id)initWithSearchBar:(UISearchBar*)theSearchBar navigationController:(UINavigationController*)theNavigationController;

@end
