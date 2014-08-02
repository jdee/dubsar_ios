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
@property (atomic) struct timeval downloadStart, lastDownloadStatsUpdate;
@property (atomic) NSTimeInterval estimatedDownloadTimeRemaining;
@property (atomic) double instantaneousDownloadRate;
@property (atomic) struct timeval unzipStart, lastUnzipRead;
@property (atomic) NSTimeInterval estimatedUnzipTimeRemaining, elapsedDownloadTime;
@property (atomic) double instantaneousUnzipRate;
@property (atomic, copy) NSString* errorMessage;

@property (atomic, weak) NSURLConnection* connection;
@property (nonatomic, copy) NSString* etag;
@property (nonatomic) NSInteger start;
@property (nonatomic) NSInteger totalSize;
@property (nonatomic) NSURL* zipURL;
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

        _start = _totalSize = 0;

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

    // NSLog(@"App support directory: %@", url.path);

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

    return [url URLByAppendingPathComponent:DUBSAR_ZIP_NAME];
}

- (void)initialize
{
    if (self.fileExists) {
        [DubsarModelsDatabase instance].databaseURL = self.fileURL;
    }
}

- (void)cancelDownload
{
    if (!self.downloadInProgress || !self.connection) {
        return;
    }

    assert(self.connection);
    [self.connection cancel];

    [AppDelegate setOfflineSetting:NO];

    self.downloadInProgress = NO;
    [[UIApplication sharedApplication] stopUsingNetwork];

    NSLog(@"Download canceled");
    // [self deleteDatabase]; // cleans up the zip too
}

- (void)download
{
    self.errorMessage = nil;

    struct stat sb;
    int rc = stat(self.zipURL.path.UTF8String, &sb);
    if (rc < 0) {
        int error = errno;
        if (error != ENOENT) {
            char errbuf[256];
            strerror_r(error, errbuf, 255);
            [self notifyDelegateOfError:@"Error %d (%s) from stat(%@)", error, errbuf, self.zipURL.path];
            return;
        }
        // not present. just download
        _etag = nil;
    }
    else if (_etag) {
        _start = (NSInteger)sb.st_size;
    }
    else {
        NSError* error;
        if (![[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:&error]) {
            [self notifyDelegateOfError:@"Error removing zip file: %@", error.localizedDescription];
            return;
        }
    }

    fp = fopen(self.zipURL.path.UTF8String, "a");
    if (!fp) {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        [self notifyDelegateOfError: @"Error %d (%s) opening %@", error, errbuf, self.zipURL.path];
        return;
    }

    NSLog(@"Successfully opened/created %@ for write", self.zipURL.path);
    [self excludeFromBackup:self.zipURL];

    self.downloadSize = self.downloadedSoFar = self.unzippedSoFar = self.unzippedSize = 0;
    self.downloadInProgress = YES;

    struct timeval now;
    gettimeofday(&now, NULL);

    self.downloadStart = now;
    self.lastDownloadStatsUpdate = self.downloadStart;
    self.downloadedAtLastStatsUpdate = 0;
    self.elapsedDownloadTime = 0;

    // NSLog(@"Download start: %ld.%06d. Last download read: %ld.%06d", self.downloadStart.tv_sec, self.downloadStart.tv_usec, self.lastDownloadStatsUpdate.tv_sec, self.lastDownloadStatsUpdate.tv_usec);

    memset(&now, 0, sizeof(now));
    self.unzipStart = now;

    NSLog(@"Downloading %@", DUBSAR_DATABASE_URL);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:DUBSAR_DATABASE_URL]];

    if (_etag && _start > 0 && _start == _totalSize) {
        [request addValue:_etag forHTTPHeaderField:@"If-None-Match"];
    }
    else if (_etag && _start > 0 && _start < _totalSize) {
        [request addValue:_etag forHTTPHeaderField:@"If-Range"];
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-%ld", (long)_start, (long)_totalSize-1] forHTTPHeaderField:@"Range"];
    }

    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [self.connection start];
    [[UIApplication sharedApplication] startUsingNetwork];
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
    if ([[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:NULL]) {
        NSLog(@"Deleted %@", self.zipURL.path);
    }
}

- (void)updateElapsedDownloadTime
{
    struct timeval now;
    gettimeofday(&now, NULL);
    self.elapsedDownloadTime = now.tv_sec - self.downloadStart.tv_sec + 1.0e-6 * (now.tv_usec - self.downloadStart.tv_usec);
}

- (void)updateDownloadStats
{
    [self updateElapsedDownloadTime];

    NSInteger size = self.downloadedSoFar - self.downloadedAtLastStatsUpdate;
    struct timeval now;
    gettimeofday(&now, NULL);

    double delta = (double)(now.tv_sec - self.lastDownloadStatsUpdate.tv_sec) + (double)(now.tv_usec - self.lastDownloadStatsUpdate.tv_usec) * 1.0e-6;
    // NSLog(@"%f s since last read: %lu bytes", delta, (unsigned long)size);

    if (size < 128 * 1024 && delta < 5.0) {
        // even it out by only checking every so often
        return;
    }

    // NSLog(@"On receipt of data, last read time %ld.%06d", self.lastDownloadRead.tv_sec, self.lastDownloadRead.tv_usec);

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

    // This may be a long-running background job on something other than the main thread. But the app may be in the foreground with the
    // SynsetViewController as a delegate.
    if (self.delegate) {
        if ([NSThread currentThread] == [NSThread mainThread]) {
            [self.delegate progressUpdated:self];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate progressUpdated:self];
            });
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (fp) {
        fclose(fp);
        fp = NULL;
    }
    [[UIApplication sharedApplication] stopUsingNetwork];
    self.downloadInProgress = NO;
    [self updateElapsedDownloadTime];
    [self notifyDelegateOfError: error.localizedDescription];
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
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        NSLog(@"Failed to write %d bytes. Wrote %zd. Error %d (%s)", data.length, nr, error, errbuf);
        return;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self updateElapsedDownloadTime];

    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;

    NSLog(@"response status code from %@: %ld", httpResp.URL.host, (long)httpResp.statusCode);
    if (httpResp.statusCode >= 400) {
        [self notifyDelegateOfError:@"Status code %ld from %@", (long)httpResp.statusCode, httpResp.URL.host];
        [[UIApplication sharedApplication] stopUsingNetwork];
        self.downloadInProgress = NO;
        if (fp) {
            fclose(fp);
            fp = NULL;
        }
        return;
    }
    else if (_etag && httpResp.statusCode == 304) {
        NSLog(@"304 Not Modified: verified copy of %@ in Caches (ETag: \"%@\")", DUBSAR_ZIP_NAME, _etag);

        // see [self download].
        // We used If-None-Match: _etag.
        // we have the complete zip, and it hasn't changed

        /*
         * This helps in a scenario like: Successfully downloaded the zip and began unzipping, but ran out
         * of room on the device. Freed up some space. Now try again, reusing the same zip without
         * downloading again.
         */

        // totalSize has to be positive to get here.
        self.downloadSize = _totalSize;
        self.downloadedSoFar = _totalSize;
        [self startUnzip];
        return;
    }

    self.downloadSize = ((NSNumber*)httpResp.allHeaderFields[@"Content-Length"]).integerValue;

    NSString* newETag = (NSString*)httpResp.allHeaderFields[@"ETag"];
    if (_etag && ![_etag isEqualToString:newETag]) {
        _totalSize = 0;
        _start = 0;
        fp = freopen(self.zipURL.path.UTF8String, "w", fp); // truncate rather than append
    }
    assert(_totalSize == 0 || self.downloadSize == _totalSize - _start);

    self.downloadedSoFar += _start;
    self.downloadSize += _start;

    _etag = newETag;
    if (_etag) {
        NSLog(@"ETag for %@ is %@", DUBSAR_DATABASE_URL, _etag);
    }
    _totalSize = self.downloadSize;

    // This may be a long-running background job on something other than the main thread. But the app may be in the foreground with the
    // SynsetViewController as a delegate.
    if (self.delegate) {
        if ([NSThread currentThread] == [NSThread mainThread]) {
            [self.delegate downloadStarted:self];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate downloadStarted:self];
            });
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"Finished downloading %@", DUBSAR_DATABASE_URL);
    [self updateElapsedDownloadTime];
    [self startUnzip];
}

- (void)startUnzip
{
    fclose(fp);
    fp = NULL;
    [[UIApplication sharedApplication] stopUsingNetwork];

    // This may be a long-running background job on something other than the main thread. But the app may be in the foreground with the
    // SynsetViewController as a delegate.
    if (self.delegate) {
        if ([NSThread currentThread] == [NSThread mainThread]) {
            [self.delegate unzipStarted:self];
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate unzipStarted:self];
            });
        }
    }

    [self performSelector:@selector(unzip) withObject:nil];
}

- (void)notifyDelegateOfError:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);
    char buffer[512];

    vsnprintf(buffer, 511, format.UTF8String, args);
    va_end(args);

    self.errorMessage = @(buffer);
    self.downloadInProgress = NO;

    if (!self.delegate) return;

    if ([NSThread currentThread] != [NSThread mainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // [self deleteDatabase];
            [self.delegate databaseManager:self encounteredError:self.errorMessage];
        });
    }
    else {
        // [self deleteDatabase];
        [self.delegate databaseManager:self encounteredError:self.errorMessage];
    }
}

- (void)finishDownload
{
    self.downloadInProgress = NO;
    if ([NSThread currentThread] != [NSThread mainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reopenAndNotify];
        });
    }
    else {
        [self reopenAndNotify];
    }
}

- (void)reopenAndNotify
{
    [DubsarModelsDatabase instance].databaseURL = self.fileURL; // reopen the DB that was just downloaded
    [self.delegate downloadComplete:self];
}

- (void)unzip
{
    struct stat sb;
    int rc = stat(self.zipURL.path.UTF8String, &sb);
    if (rc == 0) {
        NSLog(@"Downloaded file %@ is %lld bytes", DUBSAR_ZIP_NAME, sb.st_size);
    }
    else {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        [self notifyDelegateOfError: @"Error %d (%s) from stat(%@)", error, errbuf, self.fileURL.path];
        return;
    }
    
    unzFile* uf = unzOpen(self.zipURL.path.UTF8String);
    if (!uf) {
        [self notifyDelegateOfError: @"unzOpen(%@) failed", self.zipURL.path];
        return;
    }
    // NSLog(@"Opened zip file");

    rc = unzLocateFile(uf, DUBSAR_FILE_NAME.UTF8String, 1);
    if (rc != UNZ_OK) {
        [self notifyDelegateOfError: @"failed to locate %@ in zip %@", DUBSAR_FILE_NAME, DUBSAR_ZIP_NAME];
        unzClose(uf);
        return;
    }
    // NSLog(@"Located %@ in zip file", DUBSAR_FILE_NAME);

    rc = unzOpenCurrentFile(uf);
    if (rc != UNZ_OK) {
        [self notifyDelegateOfError: @"Failed to open %@ in zip %@", DUBSAR_FILE_NAME, DUBSAR_ZIP_NAME];
        unzClose(uf);
        return;
    }
    // NSLog(@"Opened %@ in zip file", DUBSAR_FILE_NAME);

    unz_file_info fileInfo;
    rc = unzGetCurrentFileInfo(uf, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
    if (rc != UNZ_OK) {
        [self notifyDelegateOfError: @"Failed to get current file info from zip"];
        unzClose(uf);
        return;
    }

    self.unzippedSize = fileInfo.uncompressed_size;
    NSLog(@"Unzipped file will be %lu bytes", (long)_unzippedSize);

    FILE* outfile = fopen(self.fileURL.path.UTF8String, "w");
    if (!outfile) {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        [self notifyDelegateOfError: @"Error %d (%s) opening %@ for write", error, errbuf, self.fileURL.path];
        unzClose(uf);
        return;
    }
    // NSLog(@"Opened %@ for write", DUBSAR_FILE_NAME);

    [self excludeFromBackup:self.fileURL];

    unsigned char buffer[32768];
    int nr;

    struct timeval now;
    gettimeofday(&now, NULL);
    self.lastUnzipRead = self.unzipStart = now;

    int lastUpdateSize = 0;

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
            int error = errno;
            char errbuf[256];
            strerror_r(error, errbuf, 255);
            [self notifyDelegateOfError: @"Failed to write %d bytes to %@. Wrote %zd instead. Error %d (%s)", nr, DUBSAR_FILE_NAME, nw, error, errbuf];
            fclose(outfile);
            unzClose(uf);
            return;
        }

        if (self.unzippedSoFar - lastUpdateSize < 8 * 1024 * 1024) {
            continue;
        }

        lastUpdateSize = self.unzippedSoFar;
        if (self.delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate progressUpdated:self];
            });
        }
    }

    fclose(outfile);
    unzClose(uf);

    if (nr < 0) {
        [self notifyDelegateOfError: @"unzReadCurrentFile returned %d", nr];
        return;
    }

    rc = stat(self.fileURL.path.UTF8String, &sb);
    if (rc != 0) {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        [self notifyDelegateOfError: @"Error %d (%s) from stat(%@)", error, errbuf, self.fileURL.path];
        [self finishDownload];
        return;
    }
    NSLog(@"Unzipped file %@ is %lld bytes", DUBSAR_FILE_NAME, sb.st_size);

    NSError* error;

    if (![[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:&error]) {
        NSLog(@"Error removing %@: %@", self.zipURL.path, error.localizedDescription);
    }

    [self finishDownload];
}

- (void)excludeFromBackup:(NSURL*)url {
    NSError* error;
    if (![url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        NSLog(@"Failed to set %@ attribute for file: %@", NSURLIsExcludedFromBackupKey, error.localizedDescription);
    }
}

@end
