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

#import "PartOfSpeechDictionary.h"
#import "Model.h"

@class Pointer;

@interface Synset : Model {
    sqlite3_stmt* pointerQuery;
    sqlite3_stmt* semanticQuery;
}

@property (nonatomic) int _id;
@property (nonatomic, copy) NSString* gloss;
@property (nonatomic) PartOfSpeech partOfSpeech;
@property (nonatomic, copy) NSString* lexname;
@property (nonatomic) int freqCnt;
@property (nonatomic, strong) NSMutableArray* samples;
@property (nonatomic, strong) NSMutableArray* senses;
@property (nonatomic, strong) NSMutableDictionary* pointers;
@property (nonatomic, strong) NSMutableArray* sections;

+(instancetype)synsetWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech;
+(instancetype)synsetWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(instancetype)initWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(instancetype)initWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(void)parseData;
-(void)parsePointers:(NSArray*)response;

-(NSString*)synonymsAsString;

-(void)prepareStatements;
-(void)destroyStatements;
-(Pointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath;
-(int)numberOfSections;

@end
