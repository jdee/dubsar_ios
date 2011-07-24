//
//  SynsetViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "SearchBarViewController_iPhone.h"

@class Synset;


@interface SynsetViewController_iPhone : SearchBarViewController_iPhone {
    
    UILabel *lexnameLabel;
    UITableView *tableView;
    UILabel *glossLabel;
    NSMutableArray* tableSections;
}

@property (nonatomic, retain) Synset* synset;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil synset:(Synset*)theSynset;

- (void)adjustTitle;
- (void)adjustBannerLabel;
- (void)adjustGlossLabel;
- (void)setupTableSections;

@end
