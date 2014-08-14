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

@interface DubsarModelsModel()
@property (nonatomic) NSURLConnection* connection;
@end

@implementation DubsarModelsModel

@synthesize data;
@synthesize _url;
@synthesize complete;
@synthesize error;
@synthesize errorMessage;
@synthesize delegate;
@synthesize url;
@synthesize preview;
@synthesize connection;

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
        _callsDelegateOnMainThread = YES;
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

            complete = true;
            error = errorMessage != nil;

            self.loading = false;
            [self callDelegateSelectorOnMainThread:@selector(loadComplete:withError:) withError:errorMessage];
        }
        else {
            // load synchronously in this thread
            // DMLOG(@"Loading from the server");
            [self loadFromServer];
            while (!self.complete &&
                   [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]]);
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

    error = true;

    DMDEBUG(@"requesting %@", url);

    [self callDelegateSelectorOnMainThread:@selector(networkLoadStarted:) withError:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    
    DMDEBUG(@"GET request for URL %@ returned HTTP status code %ld", url, (long)httpResponse.statusCode);
    
    NSDictionary* headers = [httpResponse allHeaderFields];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* value = (NSString*)obj;
        DMTRACE(@"%@: \"%@\"", key, value);
    }];
    
    if (httpResponse.statusCode >= 400) {
        self.errorMessage = @"The Dubsar server did not return the data properly.";
        error = true;

        // [self callDelegateSelectorOnMainThread:@selector(networkLoadFinished:) withError:nil];
    }

    DMDEBUG(@"received response");
    data = [NSMutableData data];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)theData
{
    if (self.errorMessage) return;

    DMTRACE(@"Received %lu bytes", (unsigned long)theData.length);
    [data appendData:theData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)theError
{
    NSString* errMsg = [theError localizedDescription];
    DMERROR(@"error requesting %@: %@", url, errMsg);
    
    [self setComplete:true];
    [self setError:true];
    [self setErrorMessage:errMsg];

    [self callDelegateSelectorOnMainThread:@selector(networkLoadFinished:) withError:nil];

    DMDEBUG(@"load processing finished");
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (!self.errorMessage) {
        assert(data);
        assert(data.bytes);

        char* cbytes = malloc(data.length+1);
        memcpy(cbytes, data.bytes, data.length);
        cbytes[data.length] = '\0';

        DMTRACE(@"Raw response (%lu): \"%s\"", (unsigned long)data.length, cbytes);

        NSString* jsonData = @(cbytes);
        free(cbytes);
        assert(jsonData);
        DMDEBUG(@"JSON response from URL %@:", url);
        DMDEBUG(@"%@", jsonData);
        
        @autoreleasepool {
            [self parseData];
        }
    }

    [self setComplete:true];

    [self callDelegateSelectorOnMainThread:@selector(networkLoadFinished:) withError:nil];

    error = errorMessage != nil;

    self.loading = false;
    [self callDelegateSelectorOnMainThread:@selector(loadComplete:withError:) withError:errorMessage];

    DMDEBUG(@"load processing finished");
}

- (void)callDelegateSelectorOnMainThread:(SEL)action withError:(NSString*)loadError
{
    if (![delegate respondsToSelector:action]) return;

    if (!_callsDelegateOnMainThread || [NSThread currentThread] == [NSThread mainThread]) {
        [self callDelegateSelector:action withError:loadError];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self callDelegateSelector:action withError:loadError];
        });
    }
}

- (void)callDelegateSelector:(SEL)action withError:(NSString*)loadError
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (action == @selector(loadComplete:withError:)) {
        [delegate performSelector:action withObject:self withObject:loadError];
    }
    else {
        [delegate performSelector:action withObject:self];
    }
#pragma clan diagnostic pop
}

@end
