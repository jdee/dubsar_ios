/*
 Dubsar Dictionary Project
 Copyright (C) 2010-14 Jimmy Dee
 
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

#import "DubsarModelsDatabase.h"
#import "DubsarModelsDatabaseWrapper.h"
#import "DubsarModels.h"
#import "DubsarModelsLoadDelegate.h"
#import "DubsarModelsModel.h"

const NSString* DubsarBaseUrl = @"https://dubsar-dictionary.com";

@implementation DubsarModelsModel

@synthesize data;
@synthesize _url;
@synthesize complete;
@synthesize error;
@synthesize errorMessage;
@synthesize delegate;
@synthesize url;
@synthesize preview;

-(instancetype)init
{
    self = [super init];
    if (self) {
        data = [NSMutableData dataWithLength:0];
        _url = nil;
        connection = nil;
        complete = false;
        error = false;
        errorMessage = nil;
        preview = false;
        _database = [DubsarModelsDatabase instance].database;
        _loading = false;
    }
    return self;
}

- (void)load
{
    if (self.loading) return;

    self.loading = true;

    [self performSelectorInBackground:@selector(loadSynchronous) withObject:nil];
}

- (void)loadSynchronous
{
    [self databaseThread:_database];
}

- (void)databaseThread:(id)wrapper
{
    @autoreleasepool {
        DubsarModelsDatabaseWrapper* database = (DubsarModelsDatabaseWrapper*)wrapper;
        if (!database) {
            database = _database;
        }

        complete = error = false;
        errorMessage = nil;

        if (database.dbptr) {
            // DMLOG(@"Loading from the DB");
            [self loadResults:database];
        }
        else {
            // load synchronously in this thread
            // DMLOG(@"Loading from the server");
            [self loadFromServer];
            while (!self.complete &&
                   [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]]);
        }

        complete = true;
        error = errorMessage != nil;

        self.loading = false;

        if (delegate != nil) {
            // DMLOG(@"Dispatching callback to router");
            if ([NSThread currentThread] != [NSThread mainThread]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate loadComplete:self withError:errorMessage];
                });
            }
            else {
                [delegate loadComplete:self withError:errorMessage];
            }
        }
        else {
            // DMLOG(@"No delegate (weak ref.)");
        }
    }
}

+(NSString*)incrementString:(NSString*)string
{
    NSString* first = [string substringToIndex:[string length]-1];
    unichar last = [string characterAtIndex:[string length]-1];
    return [NSString stringWithFormat:@"%@%c", first, ++last];
}

-(void)loadFromServer
{
    url = [NSString stringWithFormat:@"%@%@", DubsarBaseUrl, _url];
    NSURL* nsurl = [NSURL URLWithString:url];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsurl];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    connection = [NSURLConnection connectionWithRequest:request delegate:self];

    if ([delegate respondsToSelector:@selector(networkLoadStarted:)]) {
        if ([NSThread mainThread] == [NSThread currentThread]) {
            [delegate networkLoadStarted:self];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate networkLoadStarted:self];
            });
        }
    }

    DMLOG(@"requesting %@", url);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    
    DMLOG(@"GET request for URL %@ returned HTTP status code %ld", url, (long)httpResponse.statusCode);
    
    NSDictionary* headers = [httpResponse allHeaderFields];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* value = (NSString*)obj;
        DMLOG(@"%@: \"%@\"", key, value);
    }];
    
    if (httpResponse.statusCode >= 400) {
        self.errorMessage = @"The Dubsar server did not return the data properly.";

        if ([delegate respondsToSelector:@selector(networkLoadFinished:)]) {
            if ([NSThread mainThread] == [NSThread currentThread]) {
                [delegate networkLoadFinished:self];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate networkLoadFinished:self];
                });
            }
        }
        error = true;
    }
    
    DMLOG(@"%@", @"received response");
    [data setLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)theData
{
    [data appendData:theData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)theError
{
    NSString* errMsg = [theError localizedDescription];
    DMLOG(@"error requesting %@: %@", url, errMsg);
    
    [self setComplete:true];
    [self setError:true];
    [self setErrorMessage:errMsg];

    if ([delegate respondsToSelector:@selector(networkLoadFinished:)]) {
        if ([NSThread mainThread] == [NSThread currentThread]) {
            [delegate networkLoadFinished:self];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate networkLoadFinished:self];
            });
        }
    }

    DMLOG(@"%@", @"load processing finished");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // BUG: Why does jsonData show up as (null) in the iPod log?
    NSString* jsonData = @((const char*)[data bytes]);
    DMLOG(@"JSON response from URL %@:", url);
    DMLOG(@"%@", jsonData);

    @autoreleasepool {
        [self parseData];
    }

    [self setComplete:true];
    if ([delegate respondsToSelector:@selector(networkLoadFinished:)]) {
        if ([NSThread mainThread] == [NSThread currentThread]) {
            [delegate networkLoadFinished:self];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate networkLoadFinished:self];
            });
        }
    }

    DMLOG(@"%@", @"load processing finished");
}

@end
