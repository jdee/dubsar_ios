/*
 Dubsar Dictionary Project
 Copyright (C) 2010-15 Jimmy Dee
 
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

#import <SystemConfiguration/SystemConfiguration.h>
#import "DubsarModelsDatabase.h"
#import "DubsarModelsDatabaseWrapper.h"
#import "DubsarModels.h"
#import "DubsarModelsLoadDelegate.h"
#import "DubsarModelsModel.h"

const NSString* DubsarBaseUrl = @"https://dubsar.info";

@interface DubsarModelsModel()
@property (nonatomic) NSURLConnection* connection;
@property (nonatomic, readonly) SCNetworkReachabilityRef reachabilityRef;
@property (nonatomic, readonly) SCNetworkReachabilityFlags currentReachability;
@property (nonatomic, readonly) NSTimeInterval retryInterval;

- (void)connectivityChanged:(SCNetworkReachabilityFlags)flags;
@end

static void reachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
    DubsarModelsModel* model = (__bridge DubsarModelsModel*)info;
    [model connectivityChanged:flags];
}

@implementation DubsarModelsModel {
    SCNetworkReachabilityRef _reachabilityRef;
    NSTimeInterval nextRetry;
}

@synthesize data;
@synthesize _url;
@synthesize complete;
@synthesize error;
@synthesize errorMessage;
@synthesize delegate;
@synthesize url;
@synthesize preview;
@synthesize connection;

@dynamic reachabilityRef, database;

+ (BOOL)canRetryError:(NSError *)error
{
    if (error.domain != NSURLErrorDomain) return NO;

    /*
     * Most network errors can be retried, given that we change networks and so on.
     */
    switch (error.code) {
        case NSURLErrorBadURL:
        case NSURLErrorUnsupportedURL:
            return NO;
        default:
            return YES;
    }
}

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
        _loading = false;
        _callsDelegateOnMainThread = YES;
        _retriesWhenAvailable = NO;
        _reachabilityRef = NULL;
        nextRetry = 8.0;
    }
    return self;
}

- (void)dealloc
{
    if (_reachabilityRef) {
        CFRelease(_reachabilityRef);
    }
}

- (void)load
{
    if (self.loading) return;

    self.loading = true;

    [self performSelectorInBackground:@selector(loadSynchronous) withObject:nil];
}

- (void)loadSynchronous
{
    [self databaseThread];
}

- (void)cancel:(BOOL)notifyClient
{
    complete = true;

    // DEBT: What if we started a network DL, but the setting changed, and now dbptr is not NULL?
    if (!self.database.dbptr) {
        [self stopMonitoringHost];

        if (_loading) {
            [self.connection cancel];
            _loading = NO;
            if (notifyClient) {
                [self callDelegateSelectorOnMainThread:@selector(networkLoadFinished:) withError:nil];
            }
        }
    }
    // else // do something like what happens in the AC, with an aborted flag?
}

- (DubsarModelsDatabaseWrapper *)database
{
    return [DubsarModelsDatabase instance].database;
}

- (void)databaseThread
{
    @autoreleasepool {
        DubsarModelsDatabaseWrapper* database = [DubsarModelsDatabase instance].database;

        complete = error = false;
        errorMessage = nil;

        if (database.dbptr) {
            DMTRACE(@"Loading from the DB");
            @autoreleasepool {
                [self loadResults:database];
            }

            complete = true;
            error = errorMessage != nil;

            self.loading = false;
            [self callDelegateSelectorOnMainThread:@selector(loadComplete:withError:) withError:errorMessage];
        }
        else {
            // load synchronously in this thread
            DMTRACE(@"Loading from the server");
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
    nextRetry = 8.0;

    DMDEBUG(@"requesting %@", url);

    [self callDelegateSelectorOnMainThread:@selector(networkLoadStarted:) withError:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    
#ifdef DEBUG
    DMDEBUG(@"GET request for URL %@ returned HTTP status code %ld", url, (long)httpResponse.statusCode);

    NSDictionary* headers = [httpResponse allHeaderFields];
    [headers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* value = (NSString*)obj;
        DMTRACE(@"%@: \"%@\"", key, value);
    }];
#endif // DEBUG
    
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
    
    [self setError:true];
    [self setErrorMessage:errMsg];

    [self callDelegateSelectorOnMainThread:@selector(networkLoadFinished:) withError:nil];

    if (_retriesWhenAvailable && [self.class canRetryError:theError]) {
        // check current reachability
        SCNetworkReachabilityFlags flags = self.currentReachability;
        if (flags & kSCNetworkReachabilityFlagsReachable) {
            /*
             * Can still reach the host. Retry with a capped exponential backoff.
             */
            NSTimer* timer = [NSTimer timerWithTimeInterval:self.retryInterval target:self selector:@selector(loadFromServer) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        }
        else {
            [self startMonitoringHost];
        }
        [self callDelegateSelectorOnMainThread:@selector(retryWithModel:error:) withError:errMsg];
    }
    else {
        complete = true;
        DMDEBUG(@"load processing finished");
    }
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
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself callDelegateSelector:action withError:loadError];
        });
    }
}

- (void)callDelegateSelector:(SEL)action withError:(NSString*)loadError
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (action == @selector(loadComplete:withError:) || action == @selector(retryWithModel:error:)) {
        [delegate performSelector:action withObject:self withObject:loadError];
    }
    else {
        [delegate performSelector:action withObject:self];
    }
#pragma clan diagnostic pop
}

- (NSTimeInterval)retryInterval
{
    NSTimeInterval interval = nextRetry;

    nextRetry *= 2.0;
    if (nextRetry > 120.0) nextRetry = 120.0;

    return interval;
}

#pragma mark - Reachability shit

- (SCNetworkReachabilityFlags)currentReachability
{
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityRef reachabilityRef = self.reachabilityRef;
    if (!reachabilityRef) {
        return 0;
    }

    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        DMERROR(@"Unabled to determine reachability for %@", DubsarBaseUrl);
        return flags;
    }
    return 0;
}

- (SCNetworkReachabilityRef)reachabilityRef
{
    /*
     * If this is loading from the DB, the URL may be nil. There's a check in [self cancel],
     * but there can be races where the DB has been closed since this was created.
     */
    if (!_reachabilityRef && self.url) {
        const char* host = [NSURL URLWithString:self.url].host.UTF8String;
        _reachabilityRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, host);
        assert(_reachabilityRef);

        SCNetworkReachabilityContext ctx;
        memset(&ctx, 0, sizeof(ctx));
        ctx.info = (__bridge void*)self;
        SCNetworkReachabilitySetCallback(_reachabilityRef, reachabilityChanged, &ctx);
    }

    return _reachabilityRef;
}

- (void)startMonitoringHost
{
    SCNetworkReachabilityRef reachabilityRef = self.reachabilityRef;
    if (reachabilityRef) {
        SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

/*
 * Needs to be called from the thread that called monitorHost.
 */
- (void)stopMonitoringHost
{
    SCNetworkReachabilityRef reachabilityRef = self.reachabilityRef;
    if (reachabilityRef) {
        SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    }
}

- (void)connectivityChanged:(SCNetworkReachabilityFlags)flags
{
    /*
     * Called on the same thread that called monitorHost.
     */
    if ((flags & kSCNetworkReachabilityFlagsReachable) && _retriesWhenAvailable) {
        [self loadFromServer];
        [self stopMonitoringHost];
    }
}

@end
