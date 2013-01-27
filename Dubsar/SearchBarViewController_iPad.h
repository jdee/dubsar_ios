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

@class Autocompleter;
@class DailyWord;
@class DubsarNavigationController_iPad;

@interface SearchBarViewController_iPad : UIViewController <LoadDelegate, UISearchBarDelegate, UISplitViewControllerDelegate, UIPopoverControllerDelegate> {
    
    bool editing;
    UISearchBar *searchBar;
    UIPopoverController* popoverController;
    UIPopoverController* introPopoverController;
    UITableView *autocompleterTableView;
    UIButton *wotdButton;
    UIButton *abButton;
    UIButton *cdButton;
    UIButton *efButton;
    UIButton *ghButton;
    UIButton *ijButton;
    UIButton *klButton;
    UIButton *mnButton;
    UIButton *opButton;
    UIButton *qrButton;
    UIButton *stButton;
    UIButton *uvButton;
    UIButton *wxButton;
    UIButton *yzButton;
    UIButton *dotsButton;
    UIButton *homeButton;
    UIToolbar *toolbar;
}

@property (nonatomic, retain) UIPopoverController* wordPopoverController;
@property (nonatomic, assign) DubsarNavigationController_iPad* navigationController;
@property (nonatomic, retain) Autocompleter* autocompleter;
@property (nonatomic, retain) DailyWord* dailyWord;
@property (nonatomic, retain) NSString* searchText;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *autocompleterTableView;
@property (nonatomic, retain) IBOutlet UIButton *wotdButton;
@property (assign) Autocompleter* executingAutocompleter;

@property (nonatomic, retain) IBOutlet UIButton *abButton;
@property (nonatomic, retain) IBOutlet UIButton *cdButton;
@property (nonatomic, retain) IBOutlet UIButton *efButton;
@property (nonatomic, retain) IBOutlet UIButton *ghButton;
@property (nonatomic, retain) IBOutlet UIButton *ijButton;
@property (nonatomic, retain) IBOutlet UIButton *klButton;
@property (nonatomic, retain) IBOutlet UIButton *mnButton;
@property (nonatomic, retain) IBOutlet UIButton *opButton;
@property (nonatomic, retain) IBOutlet UIButton *qrButton;
@property (nonatomic, retain) IBOutlet UIButton *stButton;
@property (nonatomic, retain) IBOutlet UIButton *uvButton;
@property (nonatomic, retain) IBOutlet UIButton *wxButton;
@property (nonatomic, retain) IBOutlet UIButton *yzButton;
@property (nonatomic, retain) IBOutlet UIButton *dotsButton;
@property (nonatomic, retain) IBOutlet UIButton *homeButton;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* auguryButton;

- (IBAction)showWotd:(id)sender;
- (IBAction)showFAQ:(id)sender;
- (IBAction)loadRootController:(id)sender;
- (IBAction)showAboutPage:(id)sender;
- (IBAction)browseAB:(id)sender;
- (IBAction)browseCD:(id)sender;
- (IBAction)browseEF:(id)sender;
- (IBAction)browseGH:(id)sender;
- (IBAction)browseIJ:(id)sender;
- (IBAction)browseKL:(id)sender;
- (IBAction)browseMN:(id)sender;
- (IBAction)browseOP:(id)sender;
- (IBAction)browseQR:(id)sender;
- (IBAction)browseST:(id)sender;
- (IBAction)browseUV:(id)sender;
- (IBAction)browseWX:(id)sender;
- (IBAction)browseYZ:(id)sender;
- (IBAction)browseOther:(id)sender;

- (IBAction)resetWotd:(id)sender;
- (IBAction)augur:(id)sender;

- (void)autocompleterFinished:(Autocompleter*)theAutocompleter;
- (void)wotdFinished:(DailyWord*)theDailyWord;

- (void)wildcardSearch:(NSString*)regexp title:(NSString*)title;

- (void)disable;
- (void)enable;

- (void)displayIntro;

@end
