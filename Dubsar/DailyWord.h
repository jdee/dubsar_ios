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

#import "LoadDelegate.h"
#import "Model.h"

@class Word;

@interface DailyWord : Model<LoadDelegate>
@property (nonatomic, strong) Word* word;
@property bool fresh;
@property time_t expiration;

+ (id)dailyWord;
+ (void)updateWotdId:(int)wotdId expiration:(time_t)expiration;
+ (void)resetWotd;

- (bool)loadFromUserDefaults;
- (void)saveToUserDefaults;

@end
