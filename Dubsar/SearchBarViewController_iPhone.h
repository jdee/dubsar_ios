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

#import <UIKit/UIKit.h>

#import "AutocompleterProxy.h"

@interface SearchBarViewController_iPhone : UIViewController <LoadDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, AutocompleterDelegate> {
    UISearchBar *searchBar;
    UITableView *autocompleterTableView;
    AutocompleterProxy* proxy;
    bool editing;
}

@property (nonatomic, retain) Autocompleter* autocompleter;
@property (nonatomic, retain) UINib* autocompleterNib;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UITableView *autocompleterTableView;
@property (nonatomic, retain) NSString* preEditText;
@property (nonatomic, assign) UIGestureRecognizer* navigationGestureRecognizer;
@property bool loading;
@property (assign) Autocompleter* executingAutocompleter;

-(void)createToolbarItems;
-(void)loadRootController;
-(void)initOrientation;
-(bool)loadedSuccessfully;
-(void)load;
-(void)addGestureRecognizers;

@end
