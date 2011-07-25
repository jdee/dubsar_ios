//
//  Synset.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

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
@synthesize pointers;

+ (id)synsetWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[self alloc]initWithId:theId partOfSpeech:thePartOfSpeech];
}

+ (id)synsetWithId:(int)theId gloss:(NSString *)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[self alloc]initWithId:theId gloss:theGloss partOfSpeech:thePartOfSpeech];
}

- (id)initWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = nil;
        partOfSpeech = thePartOfSpeech;
        lexname = nil;
        samples = nil;
        senses = nil;
        _url = [[NSString stringWithFormat:@"/synsets/%d.json", _id]retain];
    }
    return self;

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
        _url = [[NSString stringWithFormat:@"/synsets/%d.json", _id]retain];
    }
    return self;
}

- (void)dealloc
{
    [pointers release];
    [senses release];
    [samples release];
    [lexname release];
    [gloss release];
    [super dealloc];
}

- (void)parseData
{
    NSArray* response = [decoder objectWithData:data];
    partOfSpeech = partOfSpeechFromPos([response objectAtIndex:1]);
    lexname = [[response objectAtIndex:2] retain];
    NSLog(@"lexname: \"%@\"", lexname);
    if (!gloss) {
        gloss = [[response objectAtIndex:3] retain];
    }
    samples = [[response objectAtIndex:4] retain];
    NSNumber* _freqCnt;
    NSArray* _senses = [response objectAtIndex:5];
    NSLog(@"found %u senses", _senses.count);
    senses = [[NSMutableArray arrayWithCapacity:_senses.count]retain];
    for (int j=0; j<_senses.count; ++j) {
        NSArray* _sense = [_senses objectAtIndex:j];
        NSNumber* _senseId = [_sense objectAtIndex:0];
        Sense* sense = [Sense senseWithId:_senseId.intValue name:[_sense objectAtIndex:1] synset:self];
        id marker = [_sense objectAtIndex:2];
        _freqCnt = [_sense objectAtIndex:3];
        sense.lexname = lexname;
        sense.freqCnt = _freqCnt.intValue;
        if (marker != NSNull.null) {
            sense.marker = marker;
        }
        [senses insertObject:sense atIndex:j];
    }
    [senses sortUsingSelector:@selector(compareFreqCnt:)];
    
    _freqCnt = [response objectAtIndex:6];
    freqCnt = _freqCnt.intValue;
    
    [self parsePointers:response];
}

- (void)parsePointers:(NSArray*)response
{    
    pointers = [[NSMutableDictionary dictionary]retain];
    NSArray* _pointers = [response objectAtIndex:7];
    for (int j=0; j<_pointers.count; ++j) {
        NSArray* _pointer = [_pointers objectAtIndex:j];
        
        NSString* ptype = [_pointer objectAtIndex:0];
        NSString* targetType = [_pointer objectAtIndex:1];
        NSNumber* targetId = [_pointer objectAtIndex:2];
        NSString* targetText = [_pointer objectAtIndex:3];
        NSString* targetGloss = [_pointer objectAtIndex:4];
        
        NSMutableArray* _pointersByType = [pointers valueForKey:ptype];
        if (_pointersByType == nil) {
            _pointersByType = [NSMutableArray array];
            [pointers setValue:_pointersByType forKey:ptype];
        }
        
        NSMutableArray* _ptr = [NSMutableArray array];
        [_ptr addObject:targetType];
        [_ptr addObject:targetId];
        [_ptr addObject:targetText];
        [_ptr addObject:targetGloss];
        
        [_pointersByType addObject:_ptr];
        [pointers setValue:_pointersByType forKey:ptype];
    }
}

@end
