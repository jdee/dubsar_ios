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

#include <sys/stat.h>
#include <sys/time.h>

#include "unzip.h"

#import "Dubsar-Swift.h"
#import "DatabaseManager.h"

@interface DatabaseManager()
@property (atomic) NSInteger downloadSize, downloadedSoFar, unzippedSize, unzippedSoFar, downloadedAtLastStatsUpdate, unzippedAtLastStatsUpdate;
@property (atomic) BOOL downloadInProgress;
@property (nonatomic, weak) NSURLConnection* connection;
@property (atomic) struct timeval downloadStart, lastDownloadStatsUpdate;
@property (atomic) NSTimeInterval estimatedDownloadTimeRemaining;
@property (atomic) double instantaneousDownloadRate;
@property (atomic) struct timeval unzipStart, lastUnzipRead;
@property (atomic) NSTimeInterval estimatedUnzipTimeRemaining;
@property (atomic) double instantaneousUnzipRate;
@end

@implementation DatabaseManager {
    FILE* fp;
}

@dynamic fileExists, fileURL, zipURL;

- (instancetype)init
{
    self = [super init];
    if (self) {
        fp = NULL;
        _downloadedSoFar = _downloadSize = _unzippedSize = _unzippedSoFar = 0;
        _downloadInProgress = NO;

        // are these ivars actually related to the synthesized atomic props?
        memset(&_downloadStart, 0, sizeof(_downloadStart));
        memset(&_lastDownloadStatsUpdate, 0, sizeof(_lastDownloadStatsUpdate));
        memset(&_unzipStart, 0, sizeof(_unzipStart));
        memset(&_lastUnzipRead, 0, sizeof(_lastUnzipRead));
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

- (NSURL*)fileURL
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];

    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    // NSLog(@"Caches directory: %@", url.path);

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:url.path isDirectory:&isDir];
    // NSLog(@"directory %@ and is%@ a directory", (exists ? @"exists" : @"doesn't exist"), (isDir ? @"" : @" not"));

    if (!exists) {
        NSError* error;
        if (![fileManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Could not create directory %@: %@", url.path, error.localizedDescription);
        }
        else {
            NSLog(@"Created directory %@", url.path);
        }
    }
    else if (!isDir) {
        NSLog(@"%@ exists and is not a directory", url.path);
    }

    return [url URLByAppendingPathComponent:DUBSAR_FILE_NAME];
}

- (NSURL *)zipURL
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];

    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    // NSLog(@"App. support directory: %@", url.path);

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:url.path isDirectory:&isDir];
    // NSLog(@"directory %@ and is%@ a directory", (exists ? @"exists" : @"doesn't exist"), (isDir ? @"" : @" not"));

    if (!exists) {
        NSError* error;
        if (![fileManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"Could not create directory %@: %@", url.path, error.localizedDescription);
        }
        else {
            NSLog(@"Created directory %@", url.path);
        }
    }
    else if (!isDir) {
        NSLog(@"%@ exists and is not a directory", url.path);
    }

    return [url URLByAppendingPathComponent:DUBSAR_ZIP_NAME];
}

- (void)initialize
{
    if (self.fileExists) {
        [DubsarModelsDatabase instance].databaseURL = self.fileURL;
    }
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
        message = @"Download and install the database? It's about 35 MB compressed and 92 MB on the device.";
        okTitle = @"Download";
    }
    else {
        message = @"Delete the database for good?";
        okTitle = @"Delete";
    }

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Confirm Offline setting change" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:okTitle, nil];
    [alert show];
}

- (void)cancelDownload
{
    assert(_connection);
    [_connection cancel];

    self.downloadInProgress = NO;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    // [_delegate downloadComplete:self];

    NSLog(@"Download canceled");
}

- (void)download
{
    fp = fopen(self.zipURL.path.UTF8String, "w");
    if (!fp) {
        char errbuf[256];
        strerror_r(errno, errbuf, 255);
        NSLog(@"Error %d (%s) opening %@", errno, errbuf, self.zipURL.path);
        return;
    }
    else {
        NSLog(@"Successfully opened/created %@ for write", self.zipURL.path);
    }

    self.downloadSize = self.downloadedSoFar = self.unzippedSoFar = self.unzippedSize = 0;
    self.downloadInProgress = YES;

    struct timeval now;
    gettimeofday(&now, NULL);

    self.downloadStart = now;
    self.lastDownloadStatsUpdate = self.downloadStart;
    self.downloadedAtLastStatsUpdate = 0;

    NSLog(@"Download start: %ld.%06d. Last download read: %ld.%06d", self.downloadStart.tv_sec, self.downloadStart.tv_usec, self.lastDownloadStatsUpdate.tv_sec, self.lastDownloadStatsUpdate.tv_usec);

    memset(&now, 0, sizeof(now));
    self.unzipStart = now;

    NSLog(@"Downloading %@", DUBSAR_DATABASE_URL);
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:DUBSAR_DATABASE_URL]];
    _connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [_connection start];
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

    // might not be there any more. don't care if this fails.
    [[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:NULL];
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
        BaseViewController* viewController = (BaseViewController*)[[AppDelegate instance] navigationController].topViewController;
        [viewController adjustLayout];
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
    self.downloadInProgress = NO;
    [_delegate downloadComplete:self];
}

- (void)updateDownloadStats
{
    NSInteger size = self.downloadedSoFar - self.downloadedAtLastStatsUpdate;

    if (size < 1024 * 1024) {
        // even it out by only checking every so often
        return;
    }

    // NSLog(@"On receipt of data, last read time %ld.%06d", self.lastDownloadRead.tv_sec, self.lastDownloadRead.tv_usec);

    struct timeval now;
    gettimeofday(&now, NULL);

    double delta = (double)(now.tv_sec - self.lastDownloadStatsUpdate.tv_sec) + (double)(now.tv_usec - self.lastDownloadStatsUpdate.tv_usec) * 1.0e-6;
    // NSLog(@"%f s since last read: %lu bytes", delta, (unsigned long)data.length);

    if (delta > 0.0) {
        self.instantaneousDownloadRate = ((double)size) / delta;
        // NSLog(@"%f B/s instantaneous rate", self.instantaneousDownloadRate);
    }

    if (self.instantaneousDownloadRate > 0) {
        self.estimatedDownloadTimeRemaining = (double)(self.downloadSize - self.downloadedSoFar) / self.instantaneousDownloadRate;
        // NSLog(@"%f s remaining", self.estimatedDownloadTimeRemaining);
    }

    self.downloadedAtLastStatsUpdate = self.downloadedSoFar;
    self.lastDownloadStatsUpdate = now;

    [_delegate progressUpdated:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    self.downloadedSoFar += data.length;
    [self updateDownloadStats];

    ssize_t nr = fwrite(data.bytes, 1, data.length, fp);

    if (nr == data.length) {
        // NSLog(@"Wrote %d bytes to %@", data.length, DUBSAR_FILE_NAME);
    }
    else {
        NSLog(@"Failed to write %d bytes. Wrote %zd. Error %d", data.length, nr, errno);
        return;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
    self.downloadSize = ((NSNumber*)httpResp.allHeaderFields[@"Content-Length"]).integerValue;

    NSLog(@"response status code from %@: %ld (Content-Length: %ld)", httpResp.URL.host, (long)httpResp.statusCode, (long)_downloadSize);
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
        return;
    }

    [self performSelectorInBackground:@selector(unzip) withObject:nil];
}

- (void)finishDownload
{
    [DubsarModelsDatabase instance].databaseURL = self.fileURL; // reopen the DB that was just downloaded

    self.downloadInProgress = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate downloadComplete:self];
    });
}

- (void)unzip
{
    unzFile* uf = unzOpen(self.zipURL.path.UTF8String);
    if (!uf) {
        NSLog(@"unzOpen(%@) failed", self.zipURL.path);
        [self finishDownload];
        return;
    }
    // NSLog(@"Opened zip file");

    int rc = unzLocateFile(uf, DUBSAR_FILE_NAME.UTF8String, 1);
    if (rc != UNZ_OK) {
        NSLog(@"failed to locate %@ in zip %@", DUBSAR_FILE_NAME, DUBSAR_ZIP_NAME);
        unzClose(uf);
        [self finishDownload];
        return;
    }
    // NSLog(@"Located %@ in zip file", DUBSAR_FILE_NAME);

    rc = unzOpenCurrentFile(uf);
    if (rc != UNZ_OK) {
        NSLog(@"Failed to open %@ in zip %@", DUBSAR_FILE_NAME, DUBSAR_ZIP_NAME);
        unzClose(uf);
        [self finishDownload];
        return;
    }
    // NSLog(@"Opened %@ in zip file", DUBSAR_FILE_NAME);

    unz_file_info fileInfo;
    rc = unzGetCurrentFileInfo(uf, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
    if (rc != UNZ_OK) {
        NSLog(@"Failed to get current file info from zip");
        unzClose(uf);
        [self finishDownload];
        return;
    }

    self.unzippedSize = fileInfo.uncompressed_size;
    NSLog(@"Unzipped file will be %lu bytes", (long)_unzippedSize);

    FILE* outfile = fopen(self.fileURL.path.UTF8String, "w");
    if (!outfile) {
        NSLog(@"Error %d opening %@ for write", errno, self.fileURL.path);
        unzClose(uf);
        [self finishDownload];
        return;
    }
    // NSLog(@"Opened %@ for write", DUBSAR_FILE_NAME);

    unsigned char buffer[32768];
    int nr;

    struct timeval now;
    gettimeofday(&now, NULL);
    self.lastUnzipRead = self.unzipStart = now;

    while ((nr=unzReadCurrentFile(uf, buffer, sizeof(buffer) * sizeof(unsigned char))) > 0) {

        self.unzippedSoFar += nr;

        gettimeofday(&now, NULL);
        double delta = (double)(now.tv_sec - self.lastUnzipRead.tv_sec) + (double)(now.tv_usec - self.lastUnzipRead.tv_usec) * 1.0e-6;

        if (delta > 0.0) {
            self.instantaneousUnzipRate = ((double)nr)/ delta;
        }

        if (self.instantaneousUnzipRate > 0.0) {
            self.estimatedUnzipTimeRemaining = ((double)(self.unzippedSize - self.unzippedSoFar)) / self.instantaneousUnzipRate;
        }
        self.lastUnzipRead = now;

        ssize_t nw = fwrite(buffer, 1, nr, outfile);
        if (nw != nr) {
            NSLog(@"Failed to write %d bytes to %@. Wrote %zd instead. Error %d", nr, DUBSAR_FILE_NAME, nw, errno);
            fclose(outfile);
            unzClose(uf);
            [self finishDownload];
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate progressUpdated:self];
        });
    }

    fclose(outfile);
    unzClose(uf);

    if (nr < 0) {
        NSLog(@"unzReadCurrentFile returned %d", nr);
        [self finishDownload];
        return;
    }

    struct stat sb;
    rc = stat(self.fileURL.path.UTF8String, &sb);
    if (rc == 0) {
        NSLog(@"Unzipped file %@ is %lld bytes", DUBSAR_FILE_NAME, sb.st_size);
    }
    else {
        NSLog(@"Error %d from stat(%@)", errno, self.fileURL.path);
        [self finishDownload];
        return;
    }

    NSError* error;

    if (![self.fileURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        NSLog(@"Failed to set %@ attribute for database file: %@", NSURLIsExcludedFromBackupKey, error.localizedDescription);
    }
    else {
        NSLog(@"Database file %@ will not be backed up", self.fileURL.path);
    }

    if (![[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:&error]) {
        NSLog(@"Error removing %@: %@", self.zipURL.path, error.localizedDescription);
    }

    [self finishDownload];
}

@end
