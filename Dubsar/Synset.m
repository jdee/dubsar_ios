//
//  Synset.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "JSONKit.h"
#import "Sense.h"
#import "Synset.h"


@implementation Synset

@synthesize _id;
@synthesize gloss;
@synthesize partOfSpeech;
@synthesize lexname;
@synthesize freqCnt;
@synthesize samples;
@synthesize senses;

+ (id)synsetWithId:(int)theId gloss:(NSString *)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[self alloc]initWithId:theId gloss:theGloss partOfSpeech:thePartOfSpeech];
}

- (id)initWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = [[theGloss copy]retain];
        partOfSpeech = thePartOfSpeech;
        lexname = nil;
        samples = nil;
        senses = nil;
        _url = [[NSString stringWithFormat:@"%@/synsets/%d.json", DubsarBaseUrl, _id]retain];
    }
    return self;
}

- (void)dealloc
{
    [senses release];
    [samples release];
    [lexname release];
    [gloss release];
    [super dealloc];
}

- (void)parseData
{
    NSArray* response = [decoder objectWithData:data];
    lexname = [[response objectAtIndex:2] retain];
    samples = [[response objectAtIndex:4] retain];
    NSArray* _senses = [response objectAtIndex:5];
    NSLog(@"found %u senses", _senses.count);
    senses = [[NSMutableArray arrayWithCapacity:_senses.count]retain];
    for (int j=0; j<_senses.count; ++j) {
        NSArray* _sense = [_senses objectAtIndex:j];
        NSNumber* _senseId = [_sense objectAtIndex:0];
        Sense* sense = [Sense senseWithId:_senseId.intValue name:[_sense objectAtIndex:1] synset:self];
        [senses insertObject:sense atIndex:j];
    }
    NSNumber* _freqCnt = [response objectAtIndex:6];
    freqCnt = _freqCnt.intValue;
}

@end
