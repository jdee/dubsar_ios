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
    return [[[self alloc]initWithId:theId partOfSpeech:thePartOfSpeech]autorelease];
}

+ (id)synsetWithId:(int)theId gloss:(NSString *)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[[self alloc]initWithId:theId gloss:theGloss partOfSpeech:thePartOfSpeech]autorelease];
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
        [self set_url: [NSString stringWithFormat:@"/synsets/%d", _id]];
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
        [self set_url: [NSString stringWithFormat:@"/synsets/%d", _id]];
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
    NSArray* response = [[self decoder] objectWithData:[self data]];
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
