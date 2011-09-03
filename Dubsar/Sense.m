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
#import "PartOfSpeechDictionary.h"
#import "Sense.h"
#import "Synset.h"
#import "Word.h"

@implementation Sense

@synthesize _id;
@synthesize name;
@synthesize partOfSpeech;
@synthesize gloss;
@synthesize synonyms;
@synthesize synset;
@synthesize word;
@synthesize lexname;
@synthesize marker;
@synthesize freqCnt;
@synthesize verbFrames;
@synthesize samples;
@synthesize pointers;

+(id)senseWithId:(int)theId name:(NSString *)theName synset:(Synset *)theSynset
{
    return [[[self alloc]initWithId:theId name:theName synset:theSynset]autorelease];
}

+(id)senseWithId:(int)theId name:(NSString *)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[[self alloc]initWithId:theId name:theName partOfSpeech:thePartOfSpeech]autorelease];
}

+(id)senseWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(Word *)theWord
{
    return [[[self alloc]initWithId:theId gloss:theGloss synonyms:theSynonyms word:theWord]autorelease];
}

+(id)senseWithId:(int)theId nameAndPos:(NSString*)nameAndPos
{
    return [[[self alloc]initWithId:theId nameAndPos:nameAndPos]autorelease];
}

-(id)initWithId:(int)theId name:(NSString *)theName synset:(Synset *)theSynset
{
    self = [super init];
    if (self) {
        _id = theId;
        name = [theName retain];
        word = nil;
        gloss = nil;
        synonyms = nil;
        synset = theSynset;
        partOfSpeech = synset.partOfSpeech;
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = true;
        weakWordLink = false;
        [self initUrl];
    }
    return self;
}

-(id)initWithId:(int)theId name:(NSString *)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        name = [theName retain];
        word = nil;
        gloss = nil;
        synonyms = nil;
        synset = nil;
        partOfSpeech = thePartOfSpeech;
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakWordLink = weakSynsetLink = false;
        [self initUrl];
    }
    return self;
   
}

-(id)initWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(Word *)theWord
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = [theGloss retain];
        synonyms = [theSynonyms retain];
        word = theWord;
        partOfSpeech = word.partOfSpeech;
        name = [word.name retain];
        synset = nil;
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = false;
        weakWordLink = true;
        [self initUrl];
    }
    return self;
}

-(id)initWithId:(int)theId nameAndPos:(NSString*)nameAndPos
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = nil;
        synonyms = nil;
        word = nil;
        synset = nil;
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = false;
        weakWordLink = false;
        [self initUrl];
        [self parseNameAndPos:nameAndPos];
    }
    return self;
}

-(void)dealloc
{
    [name release];
    [pointers release];
    [samples release];
    [verbFrames release];
    [gloss release];
    [synonyms release];
    if (!weakSynsetLink) [synset release];
    if (!weakWordLink) [word release];
    [lexname release];
    [marker release];
    [super dealloc];
}

-(NSString*)synonymsAsString
{
    
    NSString* synonymList = [NSString string];
    
    /* 
     * The app still sometimes crashes when this autorelease pool is used.
     */
#ifdef AUTORELEASE_POOL_FOR_SYNONYMS
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
#endif // AUTORELEASE_POOL_FOR_SYNOYMS
    
    for(int j=0; j<synonyms.count; ++j) {
        Sense* synonym = [synonyms objectAtIndex:j];
        synonymList = [synonymList stringByAppendingString:synonym.name];
        if (j<synonyms.count-1) {
            synonymList = [synonymList stringByAppendingString:@", "];
        }
    }
    
#ifdef AUTORELEASE_POOL_FOR_SYNONYMS
    [pool release];
#endif // AUTORELEASE_POOL_FOR_SYNONYMS    
    return synonymList;
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

-(void)parseNameAndPos:(NSString *)nameAndPos
{
    NSRange posStartRange = [nameAndPos rangeOfString:@" ("];
    if (posStartRange.location == NSNotFound) {
        NSLog(@"did not find \" (\"");
        return;
    }
    
    NSRange posEndRange = [nameAndPos rangeOfString:@".)" options:0 range:NSMakeRange(posStartRange.location+2, nameAndPos.length-posStartRange.location-2)];
    if (posEndRange.location == NSNotFound) {
        NSLog(@"did not find \".)\"");
        return;
    }
    
    NSRange nameRange = NSMakeRange(0, posStartRange.location);
    NSRange posRange = NSMakeRange(posStartRange.location+2, posEndRange.location-posStartRange.location-2);
    
    name = [[nameAndPos substringWithRange:nameRange] retain];
    partOfSpeech = [PartOfSpeechDictionary partofSpeechFromPOS:[nameAndPos substringWithRange:posRange]];
}

-(void)parseData
{
    NSLog(@"parsing Sense response for %@, %u bytes", self.nameAndPos, [self data].length);
    
    NSArray* response = [[self decoder] objectWithData:[self data]];
    NSLog(@"sense response array has %u entries", response.count);
    
    NSArray* _word = [response objectAtIndex:1];
    NSNumber* _wordId = [_word objectAtIndex:0];
    NSArray* _synset = [response objectAtIndex:2];
    NSNumber* _synsetId = [_synset objectAtIndex:0];
    
    partOfSpeech = [PartOfSpeechDictionary partofSpeechFromPOS:[_word objectAtIndex:2]];
    
    if (!word) {
        word = [[Word wordWithId:_wordId.intValue name:[_word objectAtIndex:1] partOfSpeech:partOfSpeech]retain];
    }

    if (!gloss) {
        gloss = [[_synset objectAtIndex:1]retain];
    }
   
    if (!synset) {
        synset = [[Synset synsetWithId:_synsetId.intValue gloss:[_synset objectAtIndex:1] partOfSpeech:partOfSpeech] retain];
    }
    
    lexname = [[response objectAtIndex:3] retain];
    NSLog(@"lexname: \"%@\"", lexname);
    
    synset.lexname = lexname;

    NSObject* _marker = [response objectAtIndex:4];
    if (_marker != NSNull.null) {
        marker = [_marker retain];
    }
    
    NSNumber* fc = [response objectAtIndex:5];
    freqCnt = fc.intValue;
    
    NSLog(@"freq. cnt.: %d", freqCnt);
    
    NSArray* _synonyms = [response objectAtIndex:6];
    NSLog(@"found %u synonyms", [_synonyms count]);
    synonyms = [[NSMutableArray arrayWithCapacity:_synonyms.count] retain];
    for (int j=0; j< _synonyms.count; ++j) {
        NSArray* _synonym = [_synonyms objectAtIndex:j];
        NSNumber* _senseId = [_synonym objectAtIndex:0];
        Sense* sense = [Sense senseWithId:_senseId.intValue name:[_synonym objectAtIndex:1] synset:synset];
        _marker = [_synonym objectAtIndex:2];
        if (_marker != NSNull.null) {
            sense.marker = [_synonym objectAtIndex:2];
        }
        fc = [_synonym objectAtIndex:3];
        sense.freqCnt = fc.intValue;
        NSLog(@" found %@, ID %d, freq. cnt. %d", sense.nameAndPos, sense._id, sense.freqCnt);
        [synonyms insertObject:sense atIndex:j];
    }
    [synonyms sortUsingSelector:@selector(compareFreqCnt:)];
    
    NSArray* _verbFrames = [response objectAtIndex:7];
    NSLog(@"found %u verb frames", _verbFrames.count);
    verbFrames = [[NSMutableArray arrayWithCapacity:_verbFrames.count]retain];
    for (int j=0; j<_verbFrames.count; ++j) {
        NSString* frame = [_verbFrames objectAtIndex:j];
        NSString* format = [frame stringByReplacingOccurrencesOfString:@"%s" withString:@"%@"];
        NSLog(@" %@", format);
        [verbFrames insertObject:[NSString stringWithFormat:format, name] atIndex:j];
    }
    samples = [[response objectAtIndex:8]retain];
    
    NSLog(@"found %u verb frames and %u sample sentences", [verbFrames count], [samples count]);
    
    [self parsePointers:response];
}

- (void)parsePointers:(NSArray*)response
{    
    pointers = [[NSMutableDictionary dictionary]retain];
    NSArray* _pointers = [response objectAtIndex:9];
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

- (void)initUrl
{
    [self set_url: [NSString stringWithFormat:@"/senses/%d", _id]];
}

- (NSComparisonResult)compareFreqCnt:(Sense*)sense
{
    return freqCnt < sense.freqCnt ? NSOrderedDescending : 
        freqCnt > sense.freqCnt ? NSOrderedAscending : 
        NSOrderedSame;
}

@end
