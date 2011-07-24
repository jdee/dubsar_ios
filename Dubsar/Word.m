//
//  Word.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
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
    return [[self alloc] initWithId:theId name:theName partOfSpeech:thePartOfSpeech];
}

+(id)wordWithId:(int)theId name:(NSString *)theName posString:(NSString *)posString
{
    return [[self alloc] initWithId:theId name:theName posString:posString];
}

-(id)initWithId:(int)theId name:(NSString *)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        name = [[theName copy]retain];
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
        name = [[theName copy]retain];
        
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
    [decoder release];
    [connection release];
    [_url release];
    [data release];
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
    return [[NSString alloc]initWithFormat:@"%@ (%@.)", name, self.pos];
}

-(void)parseData
{
    NSArray* response = [decoder objectWithData:data];
    
    inflections = [[response objectAtIndex:3]retain];

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
        [senses insertObject:sense atIndex:j];
    }
    NSNumber* _freqCnt = [response objectAtIndex:5];
    freqCnt = _freqCnt.intValue;
}

-(void)initUrl
{
    _url = [[NSString stringWithFormat:@"%@/words/%d.json", DubsarBaseUrl, _id] retain];
}
@end
