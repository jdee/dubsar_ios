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

#import "Model.h"
#import "ModalViewControllerDelegate.h"
#import "SearchBarViewController_iPhone.h"

@class InflectionsViewController_iPhone;
@class Word;

@interface WordViewController_iPhone : SearchBarViewController_iPhone<ModalViewControllerDelegate,LoadDelegate> {
    
    UITableView *tableView;
    UITextView *bannerTextView;
    InflectionsViewController_iPhone* inflectionsViewController;
    bool inflectionsShowing;
    bool customTitle;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UITextView *bannerTextView;

@property (nonatomic, retain) Word* word;
@property (nonatomic, assign) Model* parentDataSource;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord title:(NSString*)theTitle;

- (void)adjustBanner;
- (void)setTableViewFrame;
- (void)editInflections;
- (void)toggleInflections;
- (void)showInflections;
- (void)dismissInflections;

@end
