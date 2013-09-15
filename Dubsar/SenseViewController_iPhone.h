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

#import "SearchBarViewController_iPhone.h"

@class Sense;


@interface SenseViewController_iPhone : SearchBarViewController_iPhone<UIGestureRecognizerDelegate>
{
    UITableView *tableView;
    UILabel *detailLabel;
    UIView *detailView;
    UILabel *detailBannerLabel;
    UITextView *detailGlossTextView;
    UIImageView *bannerHandle;
    UILabel *bannerLabel;
    UINib* detailNib;
    UITextView *glossTextView;
    float initialLabelPosition;
    float currentLabelPosition;
    bool hasBeenDragged;
}
@property (nonatomic, strong) IBOutlet UITextView *glossTextView;

@property (nonatomic, strong) Sense* sense;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *detailLabel;
@property (nonatomic, strong) IBOutlet UIView *detailView;
@property (nonatomic, strong) IBOutlet UILabel *detailBannerLabel;
@property (nonatomic, strong) IBOutlet UITextView *detailGlossTextView;
@property (nonatomic, strong) IBOutlet UIImageView *bannerHandle;
@property (nonatomic, strong) IBOutlet UILabel *bannerLabel;
@property (nonatomic, weak) UINavigationController* actualNavigationController;

- (void)displayPopup:(NSString*)text;
- (IBAction)dismissPopup:(id)sender;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense;

-(void)adjustBannerLabel;
-(void)loadSynsetView;
-(void)loadWordView;
-(void)adjustGlossHeight;

-(void)followTableLink:(NSIndexPath*)indexPath;

- (void)handlePanGesture:(UIPanGestureRecognizer*)sender;
- (void)handleTapGesture:(UITapGestureRecognizer*)sender;
- (void)handleTouch:(UITouch*)touch;
- (void)translateViewContents:(CGPoint)translate;

@end
