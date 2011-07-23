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


@interface SenseViewController_iPhone : UIViewController <UISearchBarDelegate, LoadDelegate> {
    
    UISearchBar *searchBar;
    UILabel *bannerLabel;
    UILabel *glossLabel;
    UILabel *synonymsLabel;
    UILabel *synonymsTextLabel;
}

@property (nonatomic, retain) Sense* sense;
@property (nonatomic, retain) SearchBarManager_iPhone* searchBarManager;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;
@property (nonatomic, retain) IBOutlet UILabel *synonymsLabel;
@property (nonatomic, retain) IBOutlet UILabel *synonymsTextLabel;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense;

-(void)adjustBannerLabel;
-(void)loadSynsetView;

- (void)createToolbarItems;
- (void)loadRootController;

@end
