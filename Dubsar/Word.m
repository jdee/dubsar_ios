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
        
        if ([posString compare:@"adj"] == NSOrderedSame) {
            partOfSpeech = POSAdjective;
            
        } else if ([posString compare:@"adv"] == NSOrderedSame) {
            partOfSpeech = POSAdverb;
        } else if ([posString compare:@"conj"] == NSOrderedSame) {
            partOfSpeech = POSConjunction;
        } else if ([posString compare:@"interj"] == NSOrderedSame) {
            partOfSpeech = POSInterjection;
        } else if ([posString compare:@"n"] == NSOrderedSame) {
            partOfSpeech = POSNoun;
        } else if ([posString compare:@"prep"] == NSOrderedSame) {
            partOfSpeech = POSPreposition;
        } else if ([posString compare:@"pron"] == NSOrderedSame) {
            partOfSpeech = POSPronoun;
        } else if ([posString compare:@"v"] == NSOrderedSame) {
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
            // DEBT: Should throw an exception
            return nil;
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
}

-(void)initUrl
{
    _url = [[NSString stringWithFormat:@"%@/words/%d.json", DubsarBaseUrl, _id] retain];
}
@end
