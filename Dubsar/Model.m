//
//  Model.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "JSONKit.h"
#import "LoadDelegate.h"
#import "Model.h"

@implementation Model

@synthesize complete;
@synthesize delegate;
@synthesize url;

-(id)init
{
    self = [super init];
    if (self) {
        data = [[NSMutableData dataWithLength:0] retain];
        decoder = [[JSONDecoder decoder] retain];
        _url = nil;
        connection = nil;
    }
    return self;
}

-(void)dealloc
{
    [decoder release];
    [connection release];
    [_url release];
    [data release];
    [super dealloc];
}

-(void)load
{   
    url = [[NSString stringWithFormat:@"%@%@", DubsarBaseUrl, _url]retain];
    NSURL* nsurl = [NSURL URLWithString:url];
    NSURLRequest* request = [NSURLRequest requestWithURL:nsurl];
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
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
    NSLog(@"load processing finished");
}

@end
