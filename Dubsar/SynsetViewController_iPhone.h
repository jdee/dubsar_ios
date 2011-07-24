//
//  SynsetViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoadDelegate;
@class SearchBarManager_iPHone;
@class Synset;


@interface SynsetViewController_iPhone : UIViewController <LoadDelegate> {
    
    UISearchBar *searchBar;
    UILabel *lexnameLabel;
    UITableView *tableView;
    NSMutableArray* tableSections;
}

@property (nonatomic, retain) Synset* synset;
@property (nonatomic, retain) SearchBarManager_iPHone* searchBarManager;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil synset:(Synset*)theSynset;

- (void)createToolbarItems;
- (void)loadRootController;
- (void)adjustBannerLabel;
- (void)setupTableSections;

@end
