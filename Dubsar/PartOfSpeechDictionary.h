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

#import <Foundation/Foundation.h>

#import "Dubsar.h"

@interface PartOfSpeechDictionary : NSObject {
    NSMutableDictionary* dictionary;
    NSMutableDictionary* verboseDictionary;
}

@property (nonatomic, strong) NSDictionary* dictionary;

- (PartOfSpeech)partOfSpeechFromPOS:(NSString*)pos;
- (PartOfSpeech)partOfSpeechFrom_part_of_speech:(char const*)part_of_speech;
- (NSString*)posFromPartOfSpeech:(PartOfSpeech)partOfSpeech;
- (void)setupDictionary;
- (void)setValue:(PartOfSpeech)partOfSpeech forKey:(NSString*)pos;
- (void)setVerboseValue:(PartOfSpeech)partOfSpeech forKey:(NSString*)part_of_speech;
+ (PartOfSpeechDictionary*)instance;
+ (PartOfSpeech)partOfSpeechFromPOS:(NSString*)pos;
+ (NSString*)posFromPartOfSpeech:(PartOfSpeech)partOfSpeech;
+ (PartOfSpeech)partOfSpeechFrom_part_of_speech:(char const*)part_of_speech;

@end
