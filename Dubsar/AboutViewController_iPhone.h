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

@interface AboutViewController_iPhone : ForegroundViewController<UIWebViewDelegate> {
    
    UILabel *versionLabel;
    UILabel *copyrightLabel;
    UIToolbar *aboutToolbar;
    UIToolbar *licenseToolbar;
    UIView *licenseView;
    UIView *aboutView;
    UIScrollView *aboutScrollView;
    UIButton *appStoreButton;
}

@property (nonatomic, strong) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) IBOutlet UILabel *copyrightLabel;
@property (nonatomic, strong) IBOutlet UIToolbar *aboutToolbar;
@property (nonatomic, strong) IBOutlet UIToolbar *licenseToolbar;
@property (nonatomic, weak) UIViewController* mainViewController;
@property (nonatomic, strong) IBOutlet UIView *licenseView;
@property (nonatomic, strong) IBOutlet UIWebView *licenseText;
@property (nonatomic, strong) IBOutlet UIView *aboutText;
@property (nonatomic, strong) IBOutlet UIButton *appStoreButton;
@property (nonatomic, strong) IBOutlet UIScrollView *aboutScrollView;

- (IBAction)showLicense:(id)sender;
- (IBAction)dismiss:(id)sender;
- (IBAction)showAbout:(id)sender;
- (IBAction)viewInAppStore:(id)sender;

- (NSString*)licenseHtml;

@end
