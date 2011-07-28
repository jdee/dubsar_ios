/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

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
