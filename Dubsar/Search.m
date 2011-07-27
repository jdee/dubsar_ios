//
//  Search.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Search.h"
#import "JSONKit.h"
#import "URLEncoding.h"
#import "Word.h"

@implementation Search

@synthesize results;
@synthesize term;
@synthesize matchCase;


+(id)searchWithTerm:(id)theTerm matchCase:(BOOL)mustMatchCase
{
    return [[[self alloc]initWithTerm:theTerm matchCase:mustMatchCase]autorelease];
}

-(id)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase
{
    NSLog(@"constructing search for \"%@\"", theTerm);
    
    self = [super init];
    if (self) {   
        matchCase = mustMatchCase;
        term = [theTerm retain];
        results = nil;
        if (matchCase) {
            [self set_url: [NSString stringWithFormat:@"/.json?term=%@&match=case", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
           
        }
        else {
            [self set_url: [NSString stringWithFormat:@"/.json?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
        }
    }
    return self;
}

-(void)dealloc
{    
    [term release];
    [results release];

    [super dealloc];
}

- (void)parseData
{        
    NSArray* response = [[self decoder] objectWithData:[self data]];
    NSArray* list = [response objectAtIndex:1];
    
    results = [[NSMutableArray arrayWithCapacity:list.count]retain];
    NSLog(@"request for \"%@\" returned %d results", [response objectAtIndex:0], list.count);
    int j;
    for (j=0; j<list.count; ++j) {
        NSArray* entry = [list objectAtIndex:j];
        
        NSNumber* numericId = [entry objectAtIndex:0];
        NSString* name = [entry objectAtIndex:1];
        NSString* posString = [entry objectAtIndex:2];
        
        [results insertObject:[Word wordWithId:numericId.intValue name:name posString:posString] atIndex:j];
    }
}

@end
