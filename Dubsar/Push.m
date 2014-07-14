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

@import DubsarModels;
#import "Push.h"

@implementation Push

+ (Push *)instance
{
    static Push* _instance = nil;
    if (!_instance) {
        _instance = [[Push alloc] init];
    }
    return _instance;
}

+ (void)postDeviceToken:(NSData *)deviceToken
{
    [[self instance] postDeviceToken:deviceToken];
}

/*
 * This is the reason for doing this in Obj-C instead of Swift. Manipulating binary data would be a headache at best.
 */
- (void)postDeviceToken:(NSData*)deviceToken
{
    /*
     * 1a. convert deviceToken to hex
     */
    unsigned char data[32];
    assert(deviceToken.length == sizeof(data));

    [deviceToken getBytes:data length:sizeof(data)];

    // data is now a buffer of 32 numeric bytes.
    // represent as hex in sdata, which will be
    // 64 bytes plus termination. Use a power of
    // 2 for the buffer.

    char sdata[128];
    memset(sdata, 0, sizeof(sdata));

    for (int j=0; j<sizeof(data); ++j) {
        sprintf(sdata+j*2, "%02x", data[j]);
    }

    NSString* token = [NSString stringWithCString:sdata encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    NSLog(@"Device token is %@", token);
#endif // DEBUG

    /*
     * 1b. Read client secret from bundle
     */
    NSError* error;
    NSString* filepath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"client_secret.txt"];
    NSString* secret = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    if (error && !secret) {
        NSLog(@"Failed to read client_secret.txt: %@", error.localizedDescription);
    }

    /*
     * 1c. Get app version
     */

    /*
     * Could also use kCFBundleVersionKey and strip the .x from the end
     */
    NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSLog(@"App version is %@", version);

    /*
     * 1d. Determine production flag from preprocessor macro
     */
    NSString* production = nil;
#ifdef DUBSAR_DEVELOPMENT
    production = @"false";
#else
    production = @"true";
#endif // DUBSAR_DEVELOPMENT

    /*
     * 2. Construct JSON payload from this info
     */
    NSString* payload = [NSString stringWithFormat:@"{\"version\":\"%@\", \"secret\":\"%@\", \"device_token\":{\"token\":\"%@\", \"production\":%@} }", version, secret, token, production];

    /*
     * 3. Execute POST
     */
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/device_tokens", DubsarBaseUrl]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];

    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [connection start];
}

#pragma mark - NSURLConnectionDelegate and so on

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"HTTPS connection failed: %@", error.localizedDescription);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;

    NSLog(@"response status code from %@: %d", httpResp.URL.host, httpResp.statusCode);

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
