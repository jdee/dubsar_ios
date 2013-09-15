/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
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

#import "ForegroundViewController.h"
#import "LoadDelegate.h"

@class Sense;

@interface SenseViewController_iPad : ForegroundViewController <UITableViewDataSource, UITableViewDelegate, LoadDelegate, UIGestureRecognizerDelegate> {
    UITableView *tableView;
    UILabel *bannerLabel;
    UILabel *detailLabel;
    UIView *detailView;
    UIToolbar *senseToolbar;
    UIButton *moreButton;
    UIView *mainView;
    UILabel *detailBannerLabel;
    UINib *detailNib;
    UIPopoverController* popoverController;
    UITextView *glossTextView;
    UIImageView *bannerHandle;
    UITextView *detailGlossTextView;
    bool popoverWasVisible;
    float currentLabelPosition;
    float initialLabelPosition;
    bool hasBeenDragged;
}
@property (nonatomic, strong) IBOutlet UITextView *detailGlossTextView;
@property (nonatomic, strong) IBOutlet UITextView *glossTextView;

@property (nonatomic, strong) IBOutlet UIImageView *bannerHandle;
@property (nonatomic, strong) Sense* sense;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *bannerLabel;
@property (nonatomic, strong) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) IBOutlet UIView *detailView;
@property (nonatomic, strong) IBOutlet UIToolbar *senseToolbar;
@property (nonatomic, strong) IBOutlet UIButton *moreButton;
@property (nonatomic, strong) IBOutlet UIView *mainView;
@property (nonatomic, strong) IBOutlet UILabel *detailBannerLabel;
@property (nonatomic, weak) UINavigationController* actualNavigationController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense;
- (void)loadRootController;
- (void)load;

- (IBAction)showWordView:(id)sender;
- (IBAction)showSynsetView:(id)sender;
- (IBAction)morePopover:(id)sender;

-(void)followTableLink:(NSIndexPath*)indexPath;

- (void)displayPopup:(NSString*)text;
- (IBAction)dismissPopup:(id)sender;

- (void)handlePanGesture:(UIPanGestureRecognizer*)sender;
- (void)translateViewContents:(CGPoint)translate;
- (void)handleTapGesture:(UITapGestureRecognizer*)sender;
- (void)handleTouch:(UITouch*)touch; 
- (void)addGestureRecognizers;
- (void)adjustGlossHeight;

@end
