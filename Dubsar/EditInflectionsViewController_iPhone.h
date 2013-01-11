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

#import "ModalViewControllerDelegate.h"

@class Word;

@interface EditInflectionsViewController_iPhone : UIViewController<UITableViewDataSource,UITableViewDelegate> {
    NSDictionary* editingInflection;
}

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UIView* dialogView;
@property (nonatomic, retain) IBOutlet UITextField* dialogTextField;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* editButton;
@property (nonatomic, retain) Word* word;
@property (nonatomic, retain) NSMutableArray* inflections;
@property bool editing;
@property (nonatomic, retain) id<ModalViewControllerDelegate> delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord;

- (void)load;
- (void)createInflection;
- (void)updateInflection;
- (void)deleteInflection:(int)row;

- (IBAction)close:(id)sender;
- (IBAction)edit:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)newInflection:(id)sender;

@end
