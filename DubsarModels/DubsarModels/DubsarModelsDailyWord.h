/*
 Dubsar Dictionary Project
 Copyright (C) 2010-15 Jimmy Dee
 
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

#import "DubsarModels/DubsarModelsLoadDelegate.h"
#import "DubsarModels/DubsarModelsModel.h"
#import "DubsarModels/DubsarModelsPartOfSpeechDictionary.h"

@class DubsarModelsWord;

@interface DubsarModelsDailyWord : DubsarModelsModel<DubsarModelsLoadDelegate>
@property (nonatomic, strong) DubsarModelsWord* word;
@property bool fresh; // not loaded from user defaults
@property time_t expiration;

+ (instancetype)dailyWord;
+ (void)updateWotdId:(NSInteger)wotdId expiration:(time_t)expiration name:(NSString*)name partOfSpeech:(DubsarModelsPartOfSpeech)partOfSpeech;
+ (void)updateWotdWithNotificationPayload:(NSDictionary*)dubsarPayload;
+ (void)resetWotd;

@property (NS_NONATOMIC_IOSONLY, readonly) bool loadFromUserDefaults;
- (void)saveToUserDefaults;

@end
