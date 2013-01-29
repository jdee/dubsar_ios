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

#import <sqlite3.h>

#import <UIKit/UIKit.h>

#import "UAPush.h"

#define PRODUCTION_DB_NAME @"production.sqlite3"

@interface DubsarAppDelegate : NSObject <UIApplicationDelegate,UAPushNotificationDelegate,UARegistrationObserver> {
    UIColor* dubsarTintColor;
}

@property (nonatomic, retain) UIColor* dubsarTintColor;
@property (nonatomic, retain) NSString* dubsarFontFamily;
@property (nonatomic, retain) UIFont* dubsarNormalFont;
@property (nonatomic, retain) UIFont* dubsarSmallFont;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic) sqlite3* database;
@property (nonatomic) sqlite3_stmt* exactAutocompleterStmt;
@property (nonatomic) sqlite3_stmt* autocompleterStmt;
@property bool databaseReady;
@property (nonatomic, retain) NSString* authToken;
@property (nonatomic, retain) NSString* wotdUrl;
@property bool wotdUnread;

- (void)prepareDatabase:(bool)recreateFTSTables;
- (void)prepareDatabase:(bool)recreateFTSTables name:(NSString*)dbName;
- (void)closeDB;
- (id)initForTest;
- (void)addWotdButton;
- (void)updateWotdByUrl:(NSString*)url expiration:(id)expiration;

@end
