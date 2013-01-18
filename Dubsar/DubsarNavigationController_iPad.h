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
#import "ForwardStack.h"
#import "LoadDelegate.h"

@class Autocompleter;

@interface DubsarNavigationController_iPad : UINavigationController <LoadDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, UIPopoverControllerDelegate> {
    UIToolbar *searchToolbar;
    UISearchBar *searchBar;
    UIBarButtonItem *titleLabel;
    UIBarButtonItem* backBarButtonItem;
    UIBarButtonItem* fwdBarButtonItem;
    UINib* nib;
    UIPopoverController* popoverController;
    bool editing;
    UITableView* autocompleterTableView;
    bool popoverWasVisible;
    CGRect originalFrame;
}

@property (nonatomic, retain) UIPopoverController* popoverController;
@property (nonatomic, retain) Autocompleter* autocompleter;
@property (nonatomic, retain) NSString* _searchText;
@property (nonatomic, retain) ForwardStack* forwardStack;
@property (nonatomic, retain) IBOutlet UIToolbar *searchToolbar;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* titleLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* backBarButtonItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* fwdBarButtonItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* wotdBarButtonItem;
@property (assign) Autocompleter* executingAutocompleter;

- (void)addToolbar:(UIViewController*)viewController;
- (IBAction)forward:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)home:(id)sender;

- (IBAction) viewWotd:(id)sender;

- (void) addWotdButton;

- (void)addGestureRecognizerToView:(UIView*)view;

- (void)handlePanGesture:(UIPanGestureRecognizer*)sender;

@end
