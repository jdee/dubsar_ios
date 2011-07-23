//
//  Synset.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "JSONKit.h"
#import "Synset.h"


@implementation Synset

@synthesize _id;
@synthesize gloss;
@synthesize lexname;

+ (id)synsetWithId:(int)theId gloss:(NSString *)theGloss
{
    return [[self alloc]initWithId:theId gloss:theGloss];
}

- (id)initWithId:(int)theId gloss:(NSString*)theGloss
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = [theGloss retain];
        lexname = nil;
        _url = [[NSString stringWithFormat:@"%@/synsets/%d.json", DubsarBaseUrl, _id]retain];
    }
    return self;
}

- (void)dealloc
{
    [lexname release];
    [gloss release];
    [super dealloc];
}

- (void)parseData
{
    NSArray* response = [decoder objectWithData:data];
    lexname = [[response objectAtIndex:2] retain];
}

@end
