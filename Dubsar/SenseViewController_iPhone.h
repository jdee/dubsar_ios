//
//  SenseViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "SearchBarViewController_iPhone.h"

@class Sense;


@interface SenseViewController_iPhone : SearchBarViewController_iPhone 
{
    UILabel *bannerLabel;
    UIScrollView *glossScrollView;
    UILabel *glossLabel;
    UITableView *tableView;
    NSMutableArray* tableSections;
}

@property (nonatomic, retain) Sense* sense;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UIScrollView *glossScrollView;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense;

-(void)adjustBannerLabel;
-(void)loadSynsetView;
-(void)loadWordView;

- (void)setupTableSections;

@end
