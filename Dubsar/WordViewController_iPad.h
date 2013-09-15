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

@class InflectionsViewController_iPad;
@class SenseViewController_iPad;
@class Word;

@interface WordViewController_iPad : ForegroundViewController<LoadDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    UILabel *bannerLabel;
    bool inflectionsShowing;
    InflectionsViewController_iPad* inflectionsViewController;
    SenseViewController_iPad* previewViewController;
    bool customTitle;
    bool previewShowing;
    UIColor* originalColor;
}

@property (nonatomic, strong) Word* word;
@property (nonatomic, strong) IBOutlet UILabel *bannerLabel;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIToolbar* toolbar;
@property (nonatomic, weak) UINavigationController* actualNavigationController;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* previewButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* inflectionsButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord title:(NSString*)theTitle;
- (void)adjustBanner;
- (void)loadRootController;
- (void)load;
- (void)setTableViewHeight;
- (void)adjustInflectionsView;

- (IBAction)toggleInflections:(id)sender;
- (void)showInflections;
- (void)dismissInflections;

- (IBAction)togglePreview:(id)sender;
- (void)adjustPreview;

- (void)reload;
- (void)reset;

- (void)setActualNavigationController:(UINavigationController *)theActualNavigationController;

- (void)straightenAllTheShitOut;

@end
