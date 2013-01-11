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

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

@class Word;
@class Review;

@interface ReviewViewController_iPhone : UIViewController<UITableViewDataSource,UITableViewDelegate,LoadDelegate>

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil page:(int)thePage;
- (void)createToolbarItems;
- (void)load;
- (void)loadMain;
- (void)loadPrev;
- (void)loadNext;
- (void)displaySelectView;
- (void)startEditingTableView;
- (void)finishEditingTableView;
- (void)updateInflection;
- (void)deleteInflectionAtRow:(int)row;

- (IBAction)dismissSelectView:(id)sender;
- (IBAction)selectPage:(id)sender;

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UIView* selectView;
@property (nonatomic, retain) IBOutlet UIButton* selectButton;
@property (nonatomic, retain) IBOutlet UITextField* selectField;
@property (nonatomic, retain) IBOutlet UILabel* selectLabel;
@property (nonatomic, retain) Review* review;
@property bool loading;
@property bool editing;
@property int editingRow;
@property int page;

@end
