//
//  Sense.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "Sense.h"


@implementation Sense

@synthesize _id;
@synthesize gloss;
@synthesize synonyms;

+(id)senseWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms
{
    return [[self alloc]initWithId:theId gloss:theGloss synonyms:theSynonyms];
}

-(id)initWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = [theGloss copy];
        synonyms = [theSynonyms retain];
        _url = [[NSString stringWithFormat:@"%@/senses/%d.json", DubsarBaseUrl, _id]retain];
    }
    return self;
}

@end
