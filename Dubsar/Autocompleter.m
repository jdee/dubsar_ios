//
//  Autocompleter.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/24/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Autocompleter.h"
#import "JSONKit.h"
#import "URLEncoding.h"

@implementation Autocompleter

@synthesize seqNum;
@synthesize results=_results;
@synthesize term=_term;
@synthesize matchCase;

+ (id)autocompleterWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase
{
    static NSInteger _seqNum = 0;
    return [[[self alloc]initWithTerm:theTerm seqNum:_seqNum++ matchCase:mustMatchCase]autorelease];
}

- (id)initWithTerm:(NSString *)theTerm seqNum:(NSInteger)theSeqNum matchCase:(BOOL)mustMatchCase
{
    self = [super init];
    if (self) {
        seqNum = theSeqNum;
        _term = [theTerm retain];
        _results = nil;
        matchCase = mustMatchCase;
        if (matchCase) {
            [self set_url:[NSString stringWithFormat:@"/os?term=%@&match=case", [_term urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
       }
        else {
            [self set_url:[NSString stringWithFormat:@"/os?term=%@", [_term urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
        }
    }
    return self;
}

- (void)dealloc
{
    [_term release];
    [_results release];
    [super dealloc];
}

- (void)parseData
{
    NSArray* response = [[self decoder] objectWithData:[self data]];
    
    NSMutableArray* r = [[NSMutableArray array]retain];
    NSArray* list = [response objectAtIndex:1];
    for (int j=0; j<list.count; ++j) {
        [r addObject:[list objectAtIndex:j]];
    }
    _results = r;
    
    NSLog(@"autocompleter for term \"%@\" (URL \"%@\") finished with %d results:", [response objectAtIndex:0], [self _url], _results.count);
}

@end
