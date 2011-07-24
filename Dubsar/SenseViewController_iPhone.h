//
//  SenseViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

@class SearchBarManager_iPhone;
@class Sense;


@interface SenseViewController_iPhone : UIViewController <UISearchBarDelegate, LoadDelegate> 
{
    UISearchBar *searchBar;
    UILabel *bannerLabel;
    UILabel *glossLabel;
    UITableView *tableView;
    NSMutableArray* tableSections;
}

@property (nonatomic, retain) Sense* sense;
@property (nonatomic, retain) SearchBarManager_iPhone* searchBarManager;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense;

-(void)adjustBannerLabel;
-(void)loadSynsetView;
-(void)loadWordView;

- (void)createToolbarItems;
- (void)loadRootController;
- (void)displayLicense;

- (void)setupTableSections;

@end
