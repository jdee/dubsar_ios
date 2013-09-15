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

#import "AuguryViewController_iPhone.h"
#import "SearchBarViewController_iPhone.h"

@class DailyWord;

@interface DubsarViewController_iPhone : SearchBarViewController_iPhone<UIWebViewDelegate> {
    UIButton *wotdButton;
}

@property (nonatomic, strong) DailyWord* dailyWord;
@property (nonatomic, strong) IBOutlet UIButton *wotdButton;
@property (nonatomic, strong) IBOutlet UIView* loginView;
@property (nonatomic, strong) IBOutlet UITextField* emailTextField;
@property (nonatomic, strong) IBOutlet UITextField* passwordTextField;
@property (nonatomic, strong) AuguryViewController_iPhone* auguryViewController;
@property (nonatomic, strong) IBOutlet UIView* auguryIntroView;
@property (nonatomic, strong) IBOutlet UIWebView* auguryIntroWebView;

- (void)displayFAQ;
- (void)displayAbout;
- (void)displayAugury;
- (void)displayReview;
- (void)displaySync;
- (IBAction)loadWotd:(id)sender;
- (IBAction)login:(id)sender;
- (void)load;
- (void)resetWotd;
- (void)checkForCredentials;
- (NSString*)authenticateEmail:(NSString*)email password:(NSString*)password;

- (NSString*)htmlForAuguryIntro;
- (void)hideAuguryIntro;

@end
