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

#import "SearchBarViewController_iPhone.h"

@class Synset;


@interface SynsetViewController_iPhone : SearchBarViewController_iPhone {
    
    UILabel *lexnameLabel;
    UITableView *tableView;
    UILabel *glossLabel;
    UIScrollView *glossScrollView;
    UILabel *detailLabel;
    UIView *detailView;
    UINib* detailNib;
    NSMutableArray* tableSections;
}

@property (nonatomic, retain) Synset* synset;
@property (nonatomic, retain) IBOutlet UILabel *bannerLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UILabel *glossLabel;
@property (nonatomic, retain) IBOutlet UIScrollView *glossScrollView;
@property (nonatomic, retain) IBOutlet UILabel *detailLabel;
@property (nonatomic, retain) IBOutlet UIView *detailView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil synset:(Synset*)theSynset;

- (void)adjustTitle;
- (void)adjustBannerLabel;
- (void)adjustGlossLabel;
- (void)setupTableSections;
- (void)followTableLink:(NSIndexPath*)indexPath;

- (void)displayPopup:(NSString*)title;
- (IBAction)dismissPopup:(id)sender;

@end
