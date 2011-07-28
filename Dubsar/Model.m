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

@synthesize decoder;
@synthesize data;
@synthesize _url;
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
    [url release];
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
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsurl];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    connection = [[NSURLConnection connectionWithRequest:request delegate:self]retain];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSLog(@"requesting %@", url);
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

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSString* errMsg = [error localizedDescription];
    NSLog(@"error requesting %@: %@", url, errMsg);
    
    [self setComplete:true];
    [[self delegate] loadComplete:self withError:errMsg];
    
    NSLog(@"load processing finished");
    
    [Model displayNetworkAlert:errMsg];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    NSString* jsonData = [NSString stringWithCString:(const char*)[data bytes] encoding:NSUTF8StringEncoding];
    NSLog(@"JSON response from URL %@:", url);
    NSLog(@"%@", jsonData);

    [self parseData];

    [self setComplete:true];
    [[self delegate] loadComplete:self withError:nil];

    NSLog(@"load processing finished");
}

+(void)displayNetworkAlert:(NSString *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
    
    UIAlertView* alertView = [[[UIAlertView alloc]initWithTitle:@"Network Error" message:error delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease];
    [alertView show];   
}

@end
