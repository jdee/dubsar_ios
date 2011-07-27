//
//  SynsetPopoverViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoadDelegate.h"

@class Synset;

@interface SynsetPopoverViewController_iPad : UIViewController<LoadDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    UITableView *tableView;
    UILabel *bannerLabel;
    UILabel *glossLabel;
    UILabel *detailLabel;
    UIView *detailView;
    UILabel *headerLabel;
    NSMutableArray* tableSections;
    UINib *detailNib;
}

@property (nonatomic, retain) Synset* synset;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;
@property (nonatomic, retain) IBOutlet UILabel *detailLabel;
@property (nonatomic, retain) IBOutlet UIView *detailView;
@property (nonatomic, retain) IBOutlet UILabel *headerLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil synset:(Synset*)theSynset;

- (void)adjustTitle;
- (void)adjustGlossLabel;
- (void)adjustBannerLabel;
- (void)setupTableSections;

- (void)displayPopup:(NSString*)text;
- (IBAction)dismissPopup:(id)sender;

- (void)followTableLink:(NSIndexPath*)indexPath;

@end
