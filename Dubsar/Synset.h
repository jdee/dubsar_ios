/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
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


@interface Synset : Model {
    
}

@property int _id;
@property (nonatomic, retain) NSString* gloss;
@property PartOfSpeech partOfSpeech;
@property (nonatomic, retain) NSString* lexname;
@property int freqCnt;
@property (nonatomic, retain) NSMutableArray* samples;
@property (nonatomic, retain) NSMutableArray* senses;
@property (nonatomic, retain) NSMutableDictionary* pointers;


+(id)synsetWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech;
+(id)synsetWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(id)initWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(id)initWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(void)parseData;
-(void)parsePointers:(NSArray*)response;

-(NSString*)synonymsAsString;

@end
