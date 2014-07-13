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

#import "Dubsar.h"
#import "Model.h"

@class Pointer;
@class Synset;
@class Word;

@interface Sense : Model {
    bool weakSynsetLink, weakWordLink;
    sqlite3_stmt* pointerQuery;
    sqlite3_stmt* lexicalQuery;
    sqlite3_stmt* semanticQuery;
}

@property (nonatomic) int _id;
@property (nonatomic, copy) NSString* name;
@property (nonatomic) PartOfSpeech partOfSpeech;
@property (nonatomic, copy) NSString* gloss;
@property (nonatomic, strong) NSMutableArray* synonyms;

@property (nonatomic, strong) Synset* synset;
@property (nonatomic, strong) Word* word;

@property (nonatomic, copy) NSString* lexname;
@property (nonatomic) int freqCnt;
@property (nonatomic, copy) NSString* marker;

@property (nonatomic, strong) NSMutableArray* verbFrames;
@property (nonatomic, strong) NSMutableArray* samples;
@property (nonatomic, strong) NSMutableDictionary* pointers;

@property (nonatomic) int numberOfSections;
@property (nonatomic, strong) NSMutableArray* sections;

+(instancetype)senseWithId:(int)theId name:(NSString*)theName synset:(Synset*)theSynset;
+(instancetype)senseWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
+(instancetype)senseWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(Word*)theWord;
+(instancetype)senseWithId:(int)theId nameAndPos:(NSString*)nameAndPos;
-(instancetype)initWithId:(int)theId name:(NSString*)theName synset:(Synset*)theSynset;
-(instancetype)initWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(instancetype)initWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(Word*)theWord;
-(instancetype)initWithId:(int)theId nameAndPos:(NSString*)nameAndPos;

-(NSString*)pos;
-(NSString*)nameAndPos;
-(void)initUrl;
-(void)parsePointers:(NSArray*)response;

-(NSComparisonResult)compareFreqCnt:(Sense*)sense;

-(NSString*)synonymsAsString;
-(void)parseNameAndPos:(NSString*)nameAndPos;

// -(void)loadPointers:(AppDelegate*)appDelegate;
// -(void)countPointers:(AppDelegate*)appDelegate;

-(void)prepareStatements;
-(void)destroyStatements;
-(Pointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath;

@end
