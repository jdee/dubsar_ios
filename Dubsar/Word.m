//
//  Word.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "LoadDelegate.h"
#import "Word.h"

@implementation Word

@synthesize _id;
@synthesize name;
@synthesize partOfSpeech;

@synthesize complete;
@synthesize delegate;

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
        name = [theName copy];
        partOfSpeech = thePartOfSpeech;
        data = [[NSMutableData dataWithLength:0] retain];
        _url = [[NSString stringWithFormat:@"%@/words/%d", DubsarBaseUrl, _id] retain];
    }
    return self;
}

-(id)initWithId:(int)theId name:(NSString *)theName posString:(NSString *)posString
{
    self = [super init];
    if (self) {
        _id = theId;
        name = [theName copy];
        
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
    }
    return self;
}

-(void)dealloc
{
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

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)theData
{
    [data appendData:theData];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self parseData];
    [self setComplete:true];
    [[self delegate] loadComplete:self];
}

-(void)load
{
    NSURL* url = [NSURL URLWithString:_url];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    connection = [NSURLConnection connectionWithRequest:request delegate:self];   
}

-(void)parseData
{
    
}

@end
