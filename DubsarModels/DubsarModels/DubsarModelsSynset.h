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

@class DubsarModelsPointer;

@interface DubsarModelsSynset : DubsarModelsModel

@property (nonatomic) NSUInteger _id;
@property (nonatomic, copy) NSString* gloss;
@property (nonatomic) DubsarModelsPartOfSpeech partOfSpeech;
@property (nonatomic, copy) NSString* lexname;
@property (nonatomic) int freqCnt;
@property (nonatomic, strong) NSMutableArray* samples;
@property (nonatomic, strong) NSMutableArray* senses;
@property (nonatomic, strong) NSMutableDictionary* pointers;
@property (nonatomic, strong) NSMutableArray* sections;

@property (nonatomic) BOOL includeExtraSections;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *synonymsAsString;

@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger numberOfSections;

+(instancetype)synsetWithId:(NSUInteger)theId partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech;
+(instancetype)synsetWithId:(NSUInteger)theId gloss:(NSString*)theGloss partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech;
-(instancetype)initWithId:(NSUInteger)theId partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithId:(NSUInteger)theId gloss:(NSString*)theGloss partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech NS_DESIGNATED_INITIALIZER;
-(void)parseData;
-(void)parsePointers:(NSArray*)response;

-(void)prepareStatements;
-(void)destroyStatements;
-(DubsarModelsPointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath;

@end
