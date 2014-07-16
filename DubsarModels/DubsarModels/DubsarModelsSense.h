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

@import UIKit;

#import "DubsarModels/DubsarModelsPartOfSpeechDictionary.h"
#import "DubsarModels/DubsarModelsModel.h"

@class DubsarModelsPointer;
@class DubsarModelsSynset;
@class DubsarModelsWord;

@interface DubsarModelsSense : DubsarModelsModel {
    bool weakSynsetLink, weakWordLink;
}

@property (nonatomic) NSUInteger _id;
@property (nonatomic, copy) NSString* name;
@property (nonatomic) DubsarModelsPartOfSpeech partOfSpeech;
@property (nonatomic, copy) NSString* gloss;
@property (nonatomic, strong) NSMutableArray* synonyms;

@property (nonatomic, strong) DubsarModelsSynset* synset;
@property (nonatomic, strong) DubsarModelsWord* word;

@property (nonatomic, copy) NSString* lexname;
@property (nonatomic) int freqCnt;
@property (nonatomic, copy) NSString* marker;

@property (nonatomic, strong) NSMutableArray* verbFrames;
@property (nonatomic, strong) NSMutableArray* samples;
@property (nonatomic, strong) NSMutableDictionary* pointers;

@property (nonatomic) NSUInteger numberOfSections;
@property (nonatomic, strong) NSMutableArray* sections;

+(instancetype)senseWithId:(NSUInteger)theId name:(NSString*)theName synset:(DubsarModelsSynset*)theSynset;
+(instancetype)senseWithId:(NSUInteger)theId name:(NSString*)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech;
+(instancetype)senseWithId:(NSUInteger)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(DubsarModelsWord*)theWord;
+(instancetype)senseWithId:(NSUInteger)theId nameAndPos:(NSString*)nameAndPos;

-(instancetype)initWithId:(NSUInteger)theId name:(NSString*)theName synset:(DubsarModelsSynset*)theSynset NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithId:(NSUInteger)theId name:(NSString*)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithId:(NSUInteger)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(DubsarModelsWord*)theWord NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithId:(NSUInteger)theId nameAndPos:(NSString*)nameAndPos NS_DESIGNATED_INITIALIZER;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *pos;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *nameAndPos;
-(void)initUrl;
-(void)parsePointers:(NSArray*)response;

-(NSComparisonResult)compareFreqCnt:(DubsarModelsSense*)sense;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *synonymsAsString;
-(void)parseNameAndPos:(NSString*)nameAndPos;

// -(void)loadPointers:(AppDelegate*)appDelegate;
// -(void)countPointers:(AppDelegate*)appDelegate;

-(void)prepareStatements;
-(void)destroyStatements;
-(DubsarModelsPointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath;

- (void)loadWithWord;
- (void)loadWithSynset;

@end
