/*
 Dubsar Dictionary Project
 Copyright (C) 2010-14 Jimmy Dee
 
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

#import "DubsarModels/DubsarModelsPartOfSpeechDictionary.h"
#import "DubsarModels/DubsarModelsModel.h"

@interface DubsarModelsWord : DubsarModelsModel {
}

@property (nonatomic) NSUInteger _id;
@property (nonatomic, copy) NSString* name;
@property (nonatomic) DubsarModelsPartOfSpeech partOfSpeech;
@property (nonatomic) NSUInteger freqCnt;

@property (nonatomic, strong) NSMutableArray* inflections;
@property (nonatomic, strong) NSMutableArray* senses;

+(instancetype)wordWithId:(NSUInteger)theId name:(NSString*)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech;
+(instancetype)wordWithId:(NSUInteger)theId name:(NSString*)theName posString:(NSString*)posString;
-(instancetype)initWithId:(NSUInteger)theId name:(NSString*)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithId:(NSUInteger)theId name:(NSString*)theName posString:(NSString*)posString NS_DESIGNATED_INITIALIZER;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *pos;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *nameAndPos;
@property (nonatomic, readonly, copy) NSString* otherForms;

-(void)parseData;
-(void)initUrl;
-(void)addInflection:(NSString*)inflection;

- (NSComparisonResult)compareFreqCnt:(DubsarModelsWord*)word;

@end
