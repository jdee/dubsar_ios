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

@class Search;
@class WordViewController_iPad;

@interface SearchViewController_iPad : ForegroundViewController<LoadDelegate,UITableViewDataSource,UITableViewDelegate> {
    
    UITableView *tableView;
    UIPageControl *pageControl;
    bool previewShowing;
    WordViewController_iPad* previewViewController;
    UIColor* originalColor;
}

@property (nonatomic, retain) Search* search;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIPageControl *pageControl;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *previewButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString*)text matchCase:(BOOL)matchCase;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil wildcard:(NSString*)wildcard title:(NSString*)title;

- (IBAction)pageChanged:(id)sender;

- (void)setTableViewHeight;
- (void)setSearchTitle:(NSString*)title;
- (void)load;

- (IBAction)togglePreview:(id)sender;

- (void)adjustPreview;

- (void)straightenAllTheShitOut;

@end
