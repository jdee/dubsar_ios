//
//  Sense.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "JSONKit.h"
#import "LoadDelegate.h"
#import "Sense.h"
#import "Word.h"

@implementation Sense

@synthesize _id;
@synthesize gloss;
@synthesize synonyms;
@synthesize word;
@synthesize lexname;
@synthesize marker;
@synthesize freqCnt;

+(id)senseWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(Word *)theWord
{
    return [[self alloc]initWithId:theId gloss:theGloss synonyms:theSynonyms word:theWord];
}

-(id)initWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(Word *)theWord
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = [theGloss copy];
        synonyms = [theSynonyms retain];
        _url = [[NSString stringWithFormat:@"%@/senses/%d.json", DubsarBaseUrl, _id]retain];
        word = [theWord retain];
        marker = nil;
    }
    return self;
}

-(NSString*)synonymsAsString
{
    NSString* synonymList = [NSString string];
    for(int j=0; j<synonyms.count; ++j) {
        Word* synonym = [synonyms objectAtIndex:j];
        synonymList = [synonymList stringByAppendingString:synonym.name];
        if (j<synonyms.count-1) {
            synonymList = [synonymList stringByAppendingString:@", "];
        }
    }
    
    return synonymList;
}

-(void)parseData
{
    NSArray* response = [decoder objectWithData:data];
    lexname = [[response objectAtIndex:3] retain];
    NSLog(@"lexname: \"%@\"", lexname);

    NSObject* _marker = [response objectAtIndex:4];
    if (_marker != NSNull.null) {
        marker = [_marker retain];
    }
    
    NSNumber* fc = [response objectAtIndex:5];
    freqCnt = fc.intValue;
}

@end
