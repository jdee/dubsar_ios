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
    UIBarButtonItem *synsetButton;
    UIBarButtonItem *wordButton;
    UINib *detailNib;
}

@property (nonatomic, retain) Sense* sense;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;
@property (nonatomic, retain) IBOutlet UILabel *detailLabel;
@property (nonatomic, retain) IBOutlet UIView *detailView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *synsetButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *wordButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense;
- (void)loadRootController;

- (void)setupTableSections;
- (IBAction)showWordPopover:(id)sender;
- (IBAction)showSynsetPopover:(id)sender;

- (void)displayPopoverWithViewController:(UIViewController*)viewController button:(UIBarButtonItem*)button;

-(void)followTableLink:(NSIndexPath*)indexPath;

- (void)displayPopup:(NSString*)text;
- (IBAction)dismissPopup:(id)sender;

@end
