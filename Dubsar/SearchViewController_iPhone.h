//
//  SearchViewController.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "SearchBarViewController_iPhone.h"

@class Search;

@interface SearchViewController_iPhone : SearchBarViewController_iPhone {

    UILabel *_pageLabel;
}

@property (nonatomic, retain) Search* search;
@property (nonatomic, retain) IBOutlet UILabel *pageLabel;
@property (nonatomic, retain) NSString* searchText;
@property (nonatomic, retain) UISearchDisplayController* searchDisplayController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString*)theSearchText;
- (void)adjustPageLabel;

@end
