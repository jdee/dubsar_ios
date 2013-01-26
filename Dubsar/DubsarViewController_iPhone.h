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

@property (nonatomic, retain) DailyWord* dailyWord;
@property (nonatomic, retain) IBOutlet UIButton *wotdButton;
@property (nonatomic, retain) IBOutlet UIView* loginView;
@property (nonatomic, retain) IBOutlet UITextField* emailTextField;
@property (nonatomic, retain) IBOutlet UITextField* passwordTextField;
@property (nonatomic, retain) AuguryViewController_iPhone* auguryViewController;
@property (nonatomic, retain) IBOutlet UIView* auguryIntroView;
@property (nonatomic, retain) IBOutlet UIWebView* auguryIntroWebView;

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
- (void)handleWotd;

- (NSString*)htmlForAuguryIntro;
- (void)hideAuguryIntro;
- (void)hideAuguryIntroInLandscape;

@end
