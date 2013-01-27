/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
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

#import "Dubsar.h"
#import "DubsarAppDelegate.h"
#import "JSONKit.h"
#import "LoadDelegate.h"
#import "Model.h"

@implementation Model

@synthesize decoder;
@synthesize data;
@synthesize _url;
@synthesize complete;
@synthesize error;
@synthesize errorMessage;
@synthesize delegate;
@synthesize url;
@synthesize preview;
@synthesize appDelegate;

-(id)init
{
    self = [super init];
    if (self) {
        data = [[NSMutableData dataWithLength:0] retain];
        decoder = [[JSONDecoder decoder] retain];
        _url = nil;
        connection = nil;
        complete = false;
        error = false;
        errorMessage = nil;
        preview = false;
        appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;
    }
    return self;
}

-(void)dealloc
{
    [errorMessage release];
    [url release];
    [decoder release];
    [connection release];
    [_url release];
    [data release];
    [super dealloc];
}

- (void)load
{
    complete = error = false;
    errorMessage = nil;
    [self loadResults:appDelegate];
    complete = true;
    error = errorMessage != nil;
    
    if (delegate != nil) [delegate loadComplete:self withError:errorMessage];
}

- (void)databaseThread:(id)theAppDelegate
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];
    complete = error = false;
    errorMessage = nil;
    [self loadResults:(DubsarAppDelegate*)theAppDelegate];
    complete = true;
    error = errorMessage != nil;
    
    if (delegate != nil) {
        if ([NSThread currentThread] != [NSThread mainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate loadComplete:self withError:errorMessage];
            });
        }
        else {
            [delegate loadComplete:self withError:errorMessage];
        }
    }
    [pool release];
}

+(NSString*)incrementString:(NSString*)string
{
    NSString* first = [string substringToIndex:[string length]-1];
    unichar last = [string characterAtIndex:[string length]-1];
    return [NSString stringWithFormat:@"%@%c", first, ++last];
}

-(void)loadFromServer
{
    url = [[NSString stringWithFormat:@"%@%@", DubsarBaseUrl, _url]retain];
    NSURL* nsurl = [NSURL URLWithString:url];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsurl];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    connection = [[NSURLConnection connectionWithRequest:request delegate:self]retain];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSLog(@"requesting %@", url);
}

/* 
 * TODO: Migrate several methods to DailyWord class.
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    
    NSLog(@"GET request for URL %@ returned HTTP status code %d", url, httpResponse.statusCode);
    
    NSDictionary* headers = [httpResponse allHeaderFields];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* value = (NSString*)obj;
        NSLog(@"%@: \"%@\"", key, value);
    }];
    
    if (httpResponse.statusCode >= 400) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        NSString* errMsg = @"The Dubsar server did not return the data properly.";
        
        [delegate loadComplete:self withError:errMsg];
        [Model displayNetworkAlert:errMsg];
        error = true;
    }
    
    NSLog(@"received response");
    [data setLength:0];
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)theData
{
    [data appendData:theData];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)theError
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSString* errMsg = [theError localizedDescription];
    NSLog(@"error requesting %@: %@", url, errMsg);
    
    [self setComplete:true];
    [self setError:true];
    [self setErrorMessage:errMsg];
    [[self delegate] loadComplete:self withError:errMsg];
    
    NSLog(@"load processing finished");
    
    [Model displayNetworkAlert:errMsg];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    
    // BUG: Why does jsonData show up as (null) in the iPod log?
    NSString* jsonData = [NSString stringWithCString:(const char*)[data bytes] encoding:NSUTF8StringEncoding];
    NSLog(@"JSON response from URL %@:", url);
    NSLog(@"%@", jsonData);

    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc]init];
    [self parseData];
    [pool release];

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
