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

#import "JSONKit.h"
#import "Sense.h"
#import "Word.h"

@implementation Word

@synthesize _id;
@synthesize name;
@synthesize partOfSpeech;
@synthesize freqCnt;

@synthesize inflections;
@synthesize senses;

+(id)wordWithId:(int)theId name:(id)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[[self alloc] initWithId:theId name:theName partOfSpeech:thePartOfSpeech]autorelease];
}

+(id)wordWithId:(int)theId name:(NSString *)theName posString:(NSString *)posString
{
    return [[[self alloc] initWithId:theId name:theName posString:posString]autorelease];
}

-(id)initWithId:(int)theId name:(NSString *)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        name = [theName retain];
        partOfSpeech = thePartOfSpeech;
        [self initUrl];
    }
    return self;
}

-(id)initWithId:(int)theId name:(NSString *)theName posString:(NSString *)posString
{
    self = [super init];
    if (self) {
        _id = theId;
        name = [theName retain];
        
        if ([posString isEqualToString:@"adj"]) {
            partOfSpeech = POSAdjective;
            
        } else if ([posString isEqualToString:@"adv"]) {
            partOfSpeech = POSAdverb;
        } else if ([posString isEqualToString:@"conj"]) {
            partOfSpeech = POSConjunction;
        } else if ([posString isEqualToString:@"interj"]) {
            partOfSpeech = POSInterjection;
        } else if ([posString isEqualToString:@"n"]) {
            partOfSpeech = POSNoun;
        } else if ([posString isEqualToString:@"prep"]) {
            partOfSpeech = POSPreposition;
        } else if ([posString isEqualToString:@"pron"]) {
            partOfSpeech = POSPronoun;
        } else if ([posString isEqualToString:@"v"]) {
            partOfSpeech = POSVerb;
        }
        [self initUrl];
    }
    return self;
}

-(void)dealloc
{
    [senses release];
    [inflections release];
    [name release];
    [super dealloc];
}

-(NSString*)pos
{
    switch (partOfSpeech) {
        case POSAdjective:
            return @"adj";
        case POSAdverb:
            return @"adv";
        case POSConjunction:
            return @"conj";
        case POSInterjection:
            return @"interj";
        case POSNoun:
            return @"n";
        case POSPreposition:
            return @"prep";
        case POSPronoun:
            return @"pron";
        case POSVerb:
            return @"v";
        default:
            return @"..";
    }
}

-(NSString *)nameAndPos
{
    return [NSString stringWithFormat:@"%@ (%@.)", name, self.pos];
}

-(void)parseData
{
    NSArray* response =[[self decoder] objectWithData:[self data]];
    
    inflections = [[response objectAtIndex:3]retain];

    NSNumber* _freqCnt;
    NSArray* _senses = [response objectAtIndex:4];
    senses = [[NSMutableArray arrayWithCapacity:_senses.count]retain];
    for (int j=0; j<_senses.count; ++j) {
        NSArray* _sense = [_senses objectAtIndex:j];
        NSArray* _synonyms = [_sense objectAtIndex:1];
        NSNumber* numericId = nil;
        NSMutableArray* synonyms = [NSMutableArray arrayWithCapacity:_synonyms.count];
        for (int k=0; k<_synonyms.count; ++k) {
            NSArray* _synonym = [_synonyms objectAtIndex:k];
            numericId = [_synonym objectAtIndex:0];
            Sense* sense = [Sense senseWithId:numericId.intValue name:[_synonym objectAtIndex:1] partOfSpeech:partOfSpeech];
            [synonyms insertObject:sense atIndex:k];
        }
        
        numericId = [_sense objectAtIndex:0];
        Sense* sense = [Sense senseWithId:numericId.intValue gloss:[_sense objectAtIndex:2] synonyms:synonyms word:self];
        NSString* lexname = [_sense objectAtIndex:3];
        id marker = [_sense objectAtIndex:4];
        _freqCnt = [_sense objectAtIndex:5];
        sense.lexname = lexname;
        if (marker != NSNull.null) {
            sense.marker = marker;
        }
        sense.freqCnt = _freqCnt.intValue;
        
        [senses insertObject:sense atIndex:j];
    }
    [senses sortUsingSelector:@selector(compareFreqCnt:)];
    _freqCnt = [response objectAtIndex:5];
    freqCnt = _freqCnt.intValue;
}

-(void)initUrl
{
    [self set_url: [NSString stringWithFormat:@"/words/%d", _id]];
}

- (NSComparisonResult)compareFreqCnt:(Word*)word
{
    return freqCnt < word.freqCnt ? NSOrderedDescending : 
        freqCnt > word.freqCnt ? NSOrderedAscending : 
        NSOrderedSame;
}

@end
