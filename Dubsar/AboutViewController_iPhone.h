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

@interface AboutViewController_iPhone : ForegroundViewController {
    
    UILabel *versionLabel;
    UILabel *copyrightLabel;
    UIToolbar *aboutToolbar;
    UIToolbar *licenseToolbar;
    UIView *licenseView;
    UIScrollView *licenseScrollView;
    UIView *licenseText;
    UIView *aboutView;
    UIScrollView *aboutScrollView;
    UIButton *appStoreButton;
}

@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UILabel *copyrightLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *aboutToolbar;
@property (nonatomic, retain) IBOutlet UIToolbar *licenseToolbar;
@property (nonatomic, assign) UIViewController* mainViewController;
@property (nonatomic, retain) IBOutlet UIView *licenseView;
@property (nonatomic, retain) IBOutlet UIScrollView *licenseScrollView;
@property (nonatomic, retain) IBOutlet UIView *licenseText;
@property (nonatomic, retain) IBOutlet UIView *aboutText;
@property (nonatomic, retain) IBOutlet UIButton *appStoreButton;
@property (nonatomic, retain) IBOutlet UIScrollView *aboutScrollView;

- (IBAction)showLicense:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)showAbout:(id)sender;
- (IBAction)viewInAppStore:(id)sender;

@end
