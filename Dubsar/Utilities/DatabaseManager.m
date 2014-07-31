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

#include <sys/stat.h>

#import "Dubsar-Swift.h"
#import "DatabaseManager.h"

@implementation DatabaseManager {
    FILE* fp;
}

@dynamic fileExists, fileURL, zipURL;

- (instancetype)init
{
    self = [super init];
    if (self) {
        fp = NULL;
    }
    return self;
}

- (void)dealloc
{
    if (fp) {
        fclose(fp);
    }
}

- (BOOL)fileExists
{
    return [[NSFileManager defaultManager] fileExistsAtPath:self.fileURL.path];
}

- (NSURL *)fileURL
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];

    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    // NSLog(@"Downloads directory: %@", url.path);

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:url.path isDirectory:&isDir];
    // NSLog(@"directory %@ and is%@ a directory", (exists ? @"exists" : @"doesn't exist"), (isDir ? @"" : @" not"));
    assert(exists && isDir);

    return [url URLByAppendingPathComponent:DUBSAR_FILE_NAME];
}

- (NSURL*)zipURL
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];

    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    // NSLog(@"Downloads directory: %@", url.path);

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:url.path isDirectory:&isDir];
    // NSLog(@"directory %@ and is%@ a directory", (exists ? @"exists" : @"doesn't exist"), (isDir ? @"" : @" not"));
    assert(exists && isDir);

    return [url URLByAppendingPathComponent:DUBSAR_ZIP_NAME];
}

- (void)checkOfflineSetting
{
    BOOL offlineSetting = [AppDelegate offlineSetting];
    if ([AppDelegate offlineHasChanged]) {
        if (offlineSetting == [self fileExists]) {
            return;
        }
    }

    if (offlineSetting == [self fileExists]) {
        NSLog(@"Offline setting changed, but no change required.");
        return;
    }

    NSString* message;
    NSString* okTitle;
    if (offlineSetting) {
        message = @"Download and install the database? It's 35 to 40 MB compressed and about 100 MB on the device.";
        okTitle = @"Download";
    }
    else {
        message = @"Delete the database for good?";
        okTitle = @"Delete";
    }

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Confirm Offline setting change" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:okTitle, nil];
    [alert show];
}

- (void)download
{
    fp = fopen(self.zipURL.path.UTF8String, "w");
    if (!fp) {
        char errbuf[256];
        strerror_r(errno, errbuf, 255);
        NSLog(@"Error %d (%s) opening %@", errno, errbuf, self.fileURL.path);
        return;
    }
    else {
        NSLog(@"Successfully opened/created %@ for write", self.fileURL.path);
    }

    NSLog(@"Downloading %@", DUBSAR_DATABASE_URL);
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:DUBSAR_DATABASE_URL]];
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [connection start];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)deleteDatabase
{
    NSError* error;
    if (![[NSFileManager defaultManager] removeItemAtURL:self.fileURL error:&error]) {
        NSLog(@"Error deleting DB %@: %@", self.fileURL.path, error.localizedDescription);
    }
    else {
        NSLog(@"Deleted %@", self.fileURL.path);
    }

    if (![[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:&error]) {
        NSLog(@"Error deleting DB %@: %@", self.fileURL.path, error.localizedDescription);
    }
    else {
        NSLog(@"Deleted %@", self.zipURL.path);
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [AppDelegate setOfflineSetting:![AppDelegate offlineSetting]];

        BaseViewController* viewController = (BaseViewController*)[[AppDelegate instance] navigationController].topViewController;
        [viewController adjustLayout];
        return;
    }

    if ([AppDelegate offlineSetting]) {
        [self download];
    }
    else {
        [self deleteDatabase];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed with error: %@", error.localizedDescription);

    if (fp) {
        fclose(fp);
        fp = NULL;
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    ssize_t nr = fwrite(data.bytes, 1, data.length, fp);

    if (nr == data.length) {
        // NSLog(@"Wrote %d bytes to %@", data.length, DUBSAR_FILE_NAME);
    }
    else {
        NSLog(@"Failed to write %d bytes. Wrote %zd. Error %d", data.length, nr, errno);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
    NSLog(@"response status code from %@: %ld", httpResp.URL.host, (long)httpResp.statusCode);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Finished downloading %@", DUBSAR_DATABASE_URL);

    if (fp) {
        fclose(fp);
        fp = NULL;
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    struct stat sb;
    int rc = stat(self.zipURL.path.UTF8String, &sb);
    if (rc == 0) {
        NSLog(@"Downloaded file %@ is %lld bytes", DUBSAR_ZIP_NAME, sb.st_size);
    }
    else {
        NSLog(@"Error %d from stat(%@)", errno, self.fileURL.path);
    }
}

@end
