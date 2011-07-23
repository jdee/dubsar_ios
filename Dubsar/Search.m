//
//  Search.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "Search.h"
#import "LoadDelegate.h"
#import "JSONKit.h"
#import "Word.h"

@implementation Search

@synthesize complete;
@synthesize delegate;
@synthesize results;
@synthesize term;


+(id)searchWithTerm:(id)theTerm
{
    return [[self alloc]initWithTerm:theTerm];
}

-(id)initWithTerm:(NSString *)theTerm
{
    NSLog(@"constructing search for \"%@\"", theTerm);
    
    self = [super init];
    if (self) {   
        decoder = [[JSONDecoder decoder]retain];
        delegate = nil;
        term = [[theTerm copy] retain];
        complete = false;
        results = nil;
        _url = [[NSString stringWithFormat:@"%@/.json?term=%@", DubsarBaseUrl, term]retain];
        data = [[NSMutableData dataWithLength:0]retain];

    }
    return self;
}

-(void)dealloc
{    
    [connection release];
    [data release];
    [decoder release];
    [_url release];
    [term release];
    [results release];

    [super dealloc];
}

-(void)load
{    
    NSURL* url = [NSURL URLWithString:_url];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)parseData
{        
    NSArray* response = [decoder objectWithData:data];
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"received response");
    [data setLength:0];
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

@end
