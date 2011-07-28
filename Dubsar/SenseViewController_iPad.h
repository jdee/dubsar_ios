//
//  SenseViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LoadDelegate.h"

@class Sense;

@interface SenseViewController_iPad : UIViewController <UITableViewDataSource, UITableViewDelegate, LoadDelegate> {
    NSMutableArray* tableSections;    
    UITableView *tableView;
    UILabel *bannerLabel;
    UILabel *glossLabel;
    UILabel *detailLabel;
    UIView *detailView;
    UIToolbar *senseToolbar;
    UIButton *moreButton;
    UIView *mainView;
    UINib *detailNib;
    UIPopoverController* popoverController;
}

@property (nonatomic, retain) Sense* sense;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;
@property (nonatomic, retain) IBOutlet UILabel *detailLabel;
@property (nonatomic, retain) IBOutlet UIView *detailView;
@property (nonatomic, retain) IBOutlet UIToolbar *senseToolbar;
@property (nonatomic, retain) IBOutlet UIButton *moreButton;
@property (nonatomic, retain) IBOutlet UIView *mainView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense;
- (void)loadRootController;

- (void)setupTableSections;
- (IBAction)showWordView:(id)sender;
- (IBAction)showSynsetView:(id)sender;
- (IBAction)morePopover:(id)sender;

-(void)followTableLink:(NSIndexPath*)indexPath;

- (void)displayPopup:(NSString*)text;
- (IBAction)dismissPopup:(id)sender;

@end
