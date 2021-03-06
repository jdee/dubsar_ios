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

@import DubsarModels;
@import SystemConfiguration;

#include <sys/stat.h>
#include <sys/time.h>

#include "unzip.h"

#import "DatabaseManager.h"
#import "NSString+Varargs.h"
#import "UIApplication+NetworkRefCount.h"

#define DUBSAR_CURRENT_DOWNLOAD_KEY @"DubsarCurrentDownload"
#define DUBSAR_CURRENT_DOWNLOAD_MTIME_KEY @"DubsarCurrentDownloadMtime"
#define DUBSAR_CURRENT_DOWNLOAD_ETAG_KEY @"DubsarCurrentDownloadEtag"
#define DUBSAR_CURRENT_DOWNLOAD_SIZE_KEY @"DubsarCurrentDownloadSize"
#define DUBSAR_REQUIRED_DB_VERSION @"dubsar-wn3.1-3"
#define DUBSAR_UNZIP_INTERVAL_SECONDS 0.200
#define DUBSAR_MAX_PER_CYCLE 0.5

@interface DatabaseManager()
#pragma mark - Internal properties
// Many of these atomic props are readonly in the public interface
@property (atomic) NSInteger downloadSize, downloadedSoFar, unzippedSize, unzippedSoFar, downloadedAtLastStatsUpdate, unzippedAtLastStatsUpdate;
@property (atomic) BOOL downloadInProgress, updateCheckInProgress;
@property (atomic) struct timeval downloadStart, lastDownloadStatsUpdate;
@property (atomic) NSTimeInterval estimatedDownloadTimeRemaining;
@property (atomic) double instantaneousDownloadRate;
@property (atomic) struct timeval unzipStart, lastUnzipRead;
@property (atomic) NSTimeInterval estimatedUnzipTimeRemaining, elapsedDownloadTime;
@property (atomic) double instantaneousUnzipRate;
@property (atomic, copy) NSString* errorMessage;
@property (atomic) BOOL databaseUpdated;

@property (atomic, weak) NSURLConnection* connection;
@property (nonatomic, copy) NSString* etag;
@property (nonatomic) NSInteger start;
@property (nonatomic) NSInteger totalSize;
@property (nonatomic) NSURL* zipURL;
@property (nonatomic, copy) NSString* zipName;

@property (nonatomic) DubsarModelsDownloadList* downloadList;
@property (nonatomic, readonly) NSTimeInterval retryInterval;

- (void)connectivityChanged:(SCNetworkReachabilityFlags)flags;

@end

static void reachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    DatabaseManager* databaseManager = (__bridge DatabaseManager*)info;

    [databaseManager connectivityChanged:flags];
}

@implementation DatabaseManager {
    FILE* fp, *outfile;
    unzFile* uf;
    NSInteger lastUpdateSize;
    NSUInteger sequenceNumber;
    NSTimer* unzipTimer;
    BOOL updateRequired, singleThread;
    NSURL* _rootURL;
    SCNetworkReachabilityRef downloadHost;
    NSTimeInterval nextRetry;
}

@dynamic fileExists, fileURL, zipURL;

#pragma mark - Object lifecycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        fp = NULL;
        uf = NULL;
        outfile = NULL;

        _downloadedSoFar = _downloadSize = _unzippedSize = _unzippedSoFar = 0;
        _downloadInProgress = _updateCheckInProgress = NO;

        _start = _totalSize = 0;

        downloadHost = NULL;

        sequenceNumber = 0;

        nextRetry = 8.0;

        updateRequired = singleThread = _databaseUpdated = NO;
        _requiredDBVersion = DUBSAR_REQUIRED_DB_VERSION;

        memset(&_downloadStart, 0, sizeof(_downloadStart));
        memset(&_lastDownloadStatsUpdate, 0, sizeof(_lastDownloadStatsUpdate));
        memset(&_unzipStart, 0, sizeof(_unzipStart));
        memset(&_lastUnzipRead, 0, sizeof(_lastUnzipRead));

        _downloadList = [[DubsarModelsDownloadList alloc] init];
        _downloadList.delegate = self;
        _downloadList.callsDelegateOnMainThread = NO;
    }
    return self;
}

- (void)dealloc
{
    if (fp) {
        fclose(fp);
    }

    if (downloadHost) {
        CFRelease(downloadHost);
    }
}

#pragma mark - Dynamic properties (file management)
- (BOOL)fileExists
{
    if (!self.fileURL) return NO;

    struct stat sb;
    int rc = stat(self.fileURL.path.UTF8String, &sb);
    if (rc != 0) {
        int error = errno;
        if (error != ENOENT) {
            char errbuf[256];
            strerror_r(error, errbuf, 255);
            DMERROR(@"stat(%@): error %d (%s)", self.fileURL.path, error, errbuf);
        }
        return NO;
    }

    return !_currentDownload || _currentDownload.unzippedSize == 0 || _currentDownload.unzippedSize == sb.st_size;
}

- (NSURL*)fileURL
{
    if (!_fileName) return nil;

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];

    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    DMTRACE(@"App support directory: %@", url.path);

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:url.path isDirectory:&isDir];
    DMTRACE(@"directory %@ and is%@ a directory", (exists ? @"exists" : @"doesn't exist"), (isDir ? @"" : @" not"));

    if (!exists) {
        NSError* error;
        if (![fileManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
            DMERROR(@"Could not create directory %@: %@", url.path, error.localizedDescription);
            return nil;
        }
        else {
            DMINFO(@"Created directory %@", url.path);
        }
    }
    else if (!isDir) {
        DMERROR(@"%@ exists and is not a directory", url.path);
        return nil;
    }

    return [url URLByAppendingPathComponent:_fileName];
}

- (BOOL)oldFileExists
{
    if (!self.oldFileURL) {
        return NO;
    }

    return [[NSFileManager defaultManager] fileExistsAtPath:self.oldFileURL.path];
}

- (NSURL*)oldFileURL
{
    if (!_oldFileName) {
        return nil;
    }

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];

    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    DMTRACE(@"App support directory: %@", url.path);

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:url.path isDirectory:&isDir];
    DMTRACE(@"directory %@ and is%@ a directory", (exists ? @"exists" : @"doesn't exist"), (isDir ? @"" : @" not"));

    if (!exists) {
        NSError* error;
        if (![fileManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
            DMERROR(@"Could not create directory %@: %@", url.path, error.localizedDescription);
            return nil;
        }
        else {
            DMINFO(@"Created directory %@", url.path);
        }
    }
    else if (!isDir) {
        DMERROR(@"%@ exists and is not a directory", url.path);
        return nil;
    }

    return [url URLByAppendingPathComponent:_oldFileName];
}

- (NSURL *)zipURL
{
    if (!_zipName) return nil;

    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    NSURL* url = [urls objectAtIndex:0];

    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    DMTRACE(@"Caches directory: %@", url.path);

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:url.path isDirectory:&isDir];
    DMTRACE(@"directory %@ and is%@ a directory", (exists ? @"exists" : @"doesn't exist"), (isDir ? @"" : @" not"));

    if (!exists) {
        NSError* error;
        if (![fileManager createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
            DMERROR(@"Could not create directory %@: %@", url.path, error.localizedDescription);
            return nil;
        }
        else {
            DMINFO(@"Created directory %@", url.path);
        }
    }
    else if (!isDir) {
        DMERROR(@"%@ exists and is not a directory", url.path);
        return nil;
    }

    return [url URLByAppendingPathComponent:_zipName];
}

#pragma mark - Public interface
- (void)open
{
    DMTRACE(@"Initializing DB mgr");
    DMTRACE(@"Looking for %@", self.fileURL.path);
    if (self.fileExists) {
        DMTRACE(@"Found %@, opening", self.fileURL.path);
        [DubsarModelsDatabase instance].databaseURL = self.fileURL;
        assert([DubsarModelsDatabase instance].database);
    }
}

- (void)cancelDownload
{
    if (!self.downloadInProgress || !self.connection) {
        return;
    }

    assert(self.connection);
    [self.connection cancel];
    [_downloadList cancel:YES];

    [self stopMonitoringDownloadHost];

    self.errorMessage = @"Canceled";
    if (self.downloadInProgress) {
        [[UIApplication sharedApplication] stopUsingNetwork];
        self.downloadInProgress = NO;
    }

    [self restoreOldFileOnFailure];

    DMINFO(@"Download canceled");
    // [self deleteDatabase]; // cleans up the zip too
}

- (void)rejectDownload
{
    DMINFO(@"Download %@ rejected", _currentDownload.name);
    [self restoreOldFileOnFailure];
}

- (void)download
{
    self.databaseUpdated = NO;

    if (!_fileName || !_zipName) {
        DMWARN(@"Nothing to download. Checking for available downloads.");
        [self checkForUpdate];
        return;
    }

    self.errorMessage = nil;

    // @@@@@ Begin existing zip evaluation/validation
    struct stat sb;
    int rc = stat(self.zipURL.path.UTF8String, &sb);
    if (rc < 0) {
        int error = errno;
        if (error != ENOENT) {
            char errbuf[256];
            strerror_r(error, errbuf, 255);

            // Storage access error. This might mean we have the wrong folder or something.
            // Should this be an assertion?
            [self notifyDelegateOfError:@"Error %d (%s) from stat(%@)", error, errbuf, self.zipURL.path];
            return;
        }

        // not present. just download
        _etag = nil;
        _totalSize = 0;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DUBSAR_CURRENT_DOWNLOAD_ETAG_KEY];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:DUBSAR_CURRENT_DOWNLOAD_SIZE_KEY];
    }
    else if (_etag) {
        _start = (NSInteger)sb.st_size;
    }
    else {
        // We don't have an eTag for the existing zip, so we can't validate it. DEBT: An MD5/SHA1 hash for validation
        // could help.

        // Just remove the file and download fresh.
        NSError* error;
        if (![[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:&error]) {
            /*
             * Failed to remove the existing zip file when we don't have an eTag to validate it with the server.
             * We could just try fopen(..., "w") instead of "a". This is an unlikely corner case.
             */
            [self notifyDelegateOfError:@"Error removing zip file: %@", error.localizedDescription];
            return;
        }
    }
    // @@@@@ End existing zip evaluation/validation

    // open the file for append.
    fp = fopen(self.zipURL.path.UTF8String, "a");
    if (!fp) {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);

        // Full house? The write would probably fail, but not the open.
        // Should this be an assertion?
        [self notifyDelegateOfError: @"Error %d (%s) opening %@", error, errbuf, self.zipURL.path];
        return;
    }

    DMDEBUG(@"Successfully opened/created %@ for write", self.zipURL.path);
    [self excludeFromBackup:self.zipURL];

    // Initialize download stats
    self.downloadSize = self.downloadedSoFar = self.unzippedSoFar = self.unzippedSize = 0;
    self.downloadInProgress = YES;

    self.lastDownloadStatsUpdate = self.downloadStart;
    self.downloadedAtLastStatsUpdate = 0;
    self.elapsedDownloadTime = 0;

    DMTRACE(@"Download start: %ld.%06d. Last download read: %ld.%06d", self.downloadStart.tv_sec, self.downloadStart.tv_usec, self.lastDownloadStatsUpdate.tv_sec, self.lastDownloadStatsUpdate.tv_usec);

    struct timeval now;
    memset(&now, 0, sizeof(now));
    self.unzipStart = now;
    self.downloadStart = now;

    // Set up the DL URL
    NSURL* url = [self.rootURL URLByAppendingPathComponent:_zipName];
    DMINFO(@"Downloading %@", url);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];

    // Add headers in case of a partial DL or validation of a complete DL
    if (_etag && _start > 0 && _start == _totalSize) {
        [request addValue:_etag forHTTPHeaderField:@"If-None-Match"];
        DMDEBUG(@"Added If-None-Match:%@", _etag);
    }
    else if (_etag && _start > 0 && _start < _totalSize) {
        [request addValue:_etag forHTTPHeaderField:@"If-Range"];
        DMDEBUG(@"Added If-Range:%@", _etag);
        [request addValue:[NSString stringWithFormat:@"bytes=%ld-", (long)_start] forHTTPHeaderField:@"Range"];
        DMDEBUG(@"Added Range:bytes=%ld-", (long)_start);
    }

    // Make the request
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [self.connection start];
    [[UIApplication sharedApplication] startUsingNetwork];
}

- (void)downloadSynchronous
{
    [self download];

    while (self.downloadInProgress &&
           [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow:0.2]]) ;
    assert(!self.downloadInProgress);
    DMDEBUG(@"Finished dispatching download");
}

- (void)downloadInBackground
{
    [self performSelectorInBackground:@selector(downloadSynchronous) withObject:nil];
}

- (void)updateSynchronous
{
    singleThread = YES;
    [self checkForUpdate];

    // dispatch the request made by the model base class under _downloadList via NSURLConnection until
    // the response is finished
    while (self.updateCheckInProgress &&
           [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]]) ;
    assert(!self.updateCheckInProgress);
    DMDEBUG(@"Update check complete");

    /*
     * Since singleThread is YES, download was called under runMode:beforeDate: above, and downloadInProgress will already be
     * YES if a new download is available, and we should block until that finishes. If no new download was available,
     * downloadInProgress will be NO, and we'll exit right away.
     */
    while (self.downloadInProgress &&
           [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.2]]) ;
    assert(!self.downloadInProgress);
    DMDEBUG(@"Finished dispatching download");
}

- (void)deleteDatabase
{
    [[DubsarModelsDatabase instance] closeDB];

    NSError* error;
    NSURL* fileURL = self.fileURL;
    if (fileURL && ![[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error]) {
        DMERROR(@"Error deleting DB %@: %@", self.fileURL.path, error.localizedDescription);
    }
    else if (fileURL) {
        DMINFO(@"Deleted %@", fileURL.path);
    }

    // might not be there any more. don't care if this fails.
    NSURL* zipURL = self.zipURL;
    if (zipURL && [[NSFileManager defaultManager] removeItemAtURL:zipURL error:NULL]) {
        DMINFO(@"Deleted %@", zipURL.path);
    }

    [self cleanOldDatabases];
}

- (void)reportError:(NSString *)errorMessage
{
    [self notifyDelegateOfError:errorMessage];
}

- (void)notifyDelegateOfError:(NSString*)format, ...
{
    va_list args;
    va_start(args, format);

    [self notifyDelegateOfError:format args:args];
    va_end(args);
}

- (void)clearError
{
    self.errorMessage = nil; // readonly to the outside
}

- (void)checkForUpdate
{
    _downloadList.complete = false;
    self.updateCheckInProgress = YES;
    self.databaseUpdated = NO;
    [_downloadList load];
}

- (void)cleanOldDatabases
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL* url = urls[0];
    url = [url URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];

    NSError* error;
    NSArray* files = [fileManager contentsOfDirectoryAtPath:url.path error:&error];
    if (!files) {
        DMERROR(@"Reading %@: %@", url.path, error.localizedDescription);
        return;
    }

    DMINFO(@"Cleaning old DBS. Current is %@", self.fileName);

    for (NSString* file in files) {
        if (![file hasPrefix:DUBSAR_DOWNLOAD_PREFIX]) continue;

        if (![_fileName isEqualToString:file] && ![_oldFileName isEqualToString:file]) {
            NSURL* fileURL = [url URLByAppendingPathComponent:file];
            DMINFO(@"Removing %@", fileURL);
            if (![fileManager removeItemAtURL:fileURL error:&error]) {
                DMERROR(@"Error removing %@: %@", fileURL.path, error.localizedDescription);
            }
        }
        else {
            DMINFO(@"Keeping %@", file);
        }
    }

    urls = [fileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    url = [urls[0] URLByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier];

    files = [fileManager contentsOfDirectoryAtPath:url.path error:&error];
    if (!files) {
        DMERROR(@"Reading %@: %@", url.path, error.localizedDescription);
        return;
    }

    for (NSString* file in files) {
        if (![file hasPrefix:DUBSAR_DOWNLOAD_PREFIX]) continue;

        if (![_zipName isEqualToString:file]) {
            NSURL* fileURL = [url URLByAppendingPathComponent:file];
            DMINFO(@"Removing %@", fileURL);
            if (![fileManager removeItemAtURL:fileURL error:&error]) {
                DMERROR(@"Error removing %@: %@", fileURL.path, error.localizedDescription);
            }
        }
        else {
            DMINFO(@"Keeping %@", file); // to resume the download later
        }
    }
}

- (void)checkCurrentDownloadVersion
{
    int requiredNumericVersion = [DubsarModelsDownload versionFromDownloadName:_requiredDBVersion];

    [[NSUserDefaults standardUserDefaults] synchronize];

    _etag = [[NSUserDefaults standardUserDefaults] valueForKey:DUBSAR_CURRENT_DOWNLOAD_ETAG_KEY];
    _totalSize = [[NSUserDefaults standardUserDefaults] integerForKey:DUBSAR_CURRENT_DOWNLOAD_SIZE_KEY];

    NSString* download = [[NSUserDefaults standardUserDefaults] valueForKey:DUBSAR_CURRENT_DOWNLOAD_KEY];
    NSString* mtime = [[NSUserDefaults standardUserDefaults] valueForKey:DUBSAR_CURRENT_DOWNLOAD_MTIME_KEY];
    if (download) {
        int currentNumericVersion = [DubsarModelsDownload versionFromDownloadName:download];

        if (currentNumericVersion >= requiredNumericVersion) {
            _fileName = [download stringByAppendingString:@".sqlite3"];
            _zipName = [download stringByAppendingString:@".zip"];
            if (self.fileExists) {
                DMINFO(@"Application requires %@. Compatible version %@ installed.", _requiredDBVersion, download);

                if (mtime) {
                    _currentDownload = [[DubsarModelsDownload alloc]init];
                    _currentDownload.name = download;
                    _currentDownload.properties = [NSDictionary dictionaryWithObject:mtime forKey:@"mtime"];
                }
            }
            else {
                DMINFO(@"No database installed.");
            }
        }
        else {
            updateRequired = self.fileExists;
            DMWARN(@"Application requires %@. Removing %@.", _requiredDBVersion, download);
            // It'll check for updates as soon as the app foregrounds.
            [self cleanOldDatabases];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:DUBSAR_CURRENT_DOWNLOAD_KEY];
        }
    }
    else {
        /*
         * In case the user default ever vanished for any reason, but the required DB was actually
         * there. DEBT: If the user default vanished, there could be a compatible later version installed,
         * and this check would delete it. Instead of checking if _fileName exists, it should iterate
         * through everything in the app support directory that matches the pattern to see what version(s)
         * might be there.
         */
        _fileName = [_requiredDBVersion stringByAppendingString:@".sqlite3"];
        if (self.fileExists) {
            DMINFO(@"Required database %@ already installed", self.requiredDBVersion);
            [[NSUserDefaults standardUserDefaults] setValue:_requiredDBVersion forKey:DUBSAR_CURRENT_DOWNLOAD_KEY];
            _currentDownload = [[DubsarModelsDownload alloc] init];
            _currentDownload.name = _requiredDBVersion;
            _currentDownload.properties = @{};
        }
        else {
            DMWARN(@"Application requires %@. Removing any older databases.", _requiredDBVersion);
            _fileName = nil;
        }
        [self cleanOldDatabases]; // cleans everything but _fileName, or everything if _fileName is nil
    }
}

#pragma mark - NSURLConnectionDelegate and NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self updateElapsedDownloadTime];
    if (fp) {
        fclose(fp);
        fp = NULL;
    }
    [[UIApplication sharedApplication] stopUsingNetwork];

    DMERROR(@"Error %@: %ld (%@)", error.domain, (long)error.code, error.localizedDescription);

    if ([DubsarModelsModel canRetryError:error]) {
        if (!downloadHost) {
            downloadHost = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, self.rootURL.host.UTF8String);
        }

        SCNetworkReachabilityFlags reachabilityFlags;
        if (SCNetworkReachabilityGetFlags(downloadHost, &reachabilityFlags)) {
            if (reachabilityFlags & kSCNetworkReachabilityFlagsReachable) {
                NSTimeInterval retry = self.retryInterval;

                /*
                 * Insistent download: If, like me, you have poor Internet, your downloads may regularly time out due to said shit toobs.
                 * Also, being a phone, your device may change networks. If the download fails here, it's usually an indication
                 * of one of these conditions: a lost connection or timed out HTTP request. Calling download here just effectively resumes in
                 * this thread. It will use an If-Range header to avoid downloading the first part of the file again. It creates a new
                 * NSURLConnection executing on the current thread. If this is the main thread, control will return to the main run loop.
                 * If executing in downloadSynchronous in a background thread, as long as downloadInProgress is never allowed to become
                 * false, that run loop will continue until the download stops (success or failure).
                 */
                DMINFO(@"Download failed: %@ (error %ld). Host %@ reachable. Restarting download in %f s.", error.localizedDescription, (long)error.code, self.rootURL.host, retry);

                // In this event, use a capped exponential backoff, taking more and more time before retrying each time. The backoff is reset whenever
                // we lose and regain connectivity or complete the download.
                NSTimer* timer = [NSTimer timerWithTimeInterval:retry target:self selector:@selector(download) userInfo:nil repeats:NO];
                assert(timer);
                [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];

                return;
            }

            // if not reachable:

            // arrange to be called back on this thread when the host becomes available.
            [self monitorDownloadHost];

            // DEBT: AND?? Not giving up on the DL. If in the BG, we don't need to do anything, but we might consider setting an errorMessage.
            // If in the FG, should we notify the delegate? So far we've only notified of fatal errors. If we haven't given up, we may need
            // to change some things to generate errors.
            return;
        }
        else {
            DMWARN(@"Could not determine network reachability for %@", self.rootURL.host);
        }
    }

    [self restoreOldFileOnFailure];

    self.downloadInProgress = NO;
    [self notifyDelegateOfError: error.localizedDescription];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!fp) return; // still called after a 404

    self.downloadedSoFar += data.length;
    [self updateDownloadStats];

    ssize_t nr = fwrite(data.bytes, 1, data.length, fp);

    if (nr == data.length) {
        DMTRACE(@"Wrote %d bytes to %@", data.length, _zipName);
    }
    else {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        DMERROR(@"Failed to write %lu bytes to %@. Wrote %zd. Error %d (%s)", (unsigned long)data.length, self.zipURL.path, nr, error, errbuf);
        return;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    struct timeval now;
    gettimeofday(&now, NULL);

    self.downloadStart = now;

    NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;

    DMINFO(@"response status code from %@: %ld", httpResp.URL.host, (long)httpResp.statusCode);
    if (httpResp.statusCode >= 400) {
        [self notifyDelegateOfError:@"Status code %ld from %@", (long)httpResp.statusCode, httpResp.URL.host];
        [[UIApplication sharedApplication] stopUsingNetwork];
        self.downloadInProgress = NO;
        if (fp) {
            fclose(fp);
            fp = NULL;
        }

        [self restoreOldFileOnFailure];
        return;
    }
    else if (_etag && httpResp.statusCode == 304) {
        DMINFO(@"304 Not Modified: verified copy of %@ in Caches (ETag: \"%@\")", _zipName, _etag);

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
    /* The Content-Lenght field doesn't seem to be consistent. Maybe an nginx update will fix it.
    if (self.downloadSize != _currentDownload.zippedSize - _start) {
        DMERROR(@"Download is wrong size. Expected %lu, got %lu", _currentDownload.zippedSize - _start, self.downloadSize);
        [self notifyDelegateOfError:@"Failed to validate download"];
        [[UIApplication sharedApplication] stopUsingNetwork];
        self.downloadInProgress = NO;
        if (fp) {
            fclose(fp);
            fp = NULL;
        }

        [self restoreOldFileOnFailure];
        return;
    }
    // */

    NSString* newETag = (NSString*)httpResp.allHeaderFields[@"ETag"];
    if (_etag && ![_etag isEqualToString:newETag]) {
        _totalSize = 0;
        _start = 0;
        fp = freopen(self.zipURL.path.UTF8String, "w", fp); // truncate rather than append
    }

    self.downloadedSoFar += _start;
    self.downloadSize += _start;

    _etag = newETag;
    if (_etag) {
        DMDEBUG(@"ETag for %@ is %@", [self.rootURL URLByAppendingPathComponent:_zipName], _etag);
    }
    _totalSize = self.downloadSize;

    [[NSUserDefaults standardUserDefaults] setValue:_etag forKey:DUBSAR_CURRENT_DOWNLOAD_ETAG_KEY];
    [[NSUserDefaults standardUserDefaults] setInteger:_totalSize forKey:DUBSAR_CURRENT_DOWNLOAD_SIZE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // This may be a long-running background job on something other than the main thread. But the app may be in the foreground with the
    // SynsetViewController as a delegate.
    if ([self.delegate respondsToSelector:@selector(downloadStarted:)]) {
        if ([NSThread currentThread] == [NSThread mainThread]) {
            [self.delegate downloadStarted:self];
        }
        else {
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate downloadStarted:weakself];
            });
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DMINFO(@"Finished downloading %@", _zipName);
    [self updateElapsedDownloadTime];
    [self startUnzip];
}

#pragma mark - DubsarModelsLoadDelegate

// These are called with model == _downloadList

- (void)retryWithModel:(DubsarModelsModel *)model error:(NSString *)error
{
    DMDEBUG(@"Failed to load download list: %@. Retrying.", error);
}

- (void)loadComplete:(DubsarModelsModel *)model withError:(NSString *)error
{
    self.updateCheckInProgress = NO;
    if (error) {
        [self notifyDelegateOfError:@"%@", error];
        [self noUpdateAvailable];
        return;
    }

    DubsarModelsDownloadList* downloadList = (DubsarModelsDownloadList*)model;
    DubsarModelsDownload* newDownload = [self findCorrectDownload:downloadList];
    if (!newDownload) {
        _currentDownload = nil;
        // this indicates a serious server configuration error. the app cannot download anything if the user requests it.
        [self notifyDelegateOfError:@"No acceptable download available."];
        [self noUpdateAvailable];
        return;
    }

    if ([newDownload isEqual:_currentDownload]) {
        DMINFO(@"No new download available. %@ is current.", _currentDownload.name);

        // if there were previously bad data from the server, make sure they don't get stuck.
        _currentDownload = newDownload;

        // We may never have successfully downloaded it though. Validate any files present before reporting nothing to do.
        if (self.fileExists) {
            // self.fileExists validates the file size.
            // ordinarily, there should be no zip. don't really care if the
            // zip is still here, but delete it in case.

            [[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:NULL];

            // All is well. Nothing to see here. Move along.
            [self noUpdateAvailable];
        }
        else {
            // this could be a partially unzipped file, if the app crashed during the unzip.
            /*
             * In that case, we ought to go back and check for an existing zip file and download/resume/validate as
             * appropriate. Then we should unzip that from scratch. The download process will detect/validate a partial
             * zip. We could delete the DB, but once we call download, attention shifts to the zip. Once that's downloaded
             * and validated, the existing DB will be overwritten.
             */

            // needs a download.
            [self promptUserOrDownload:_currentDownload];

            // download validates any existing zip. if complete, an If-None-Match header is sent, and if a 304 Not Modified is returned,
            // tries to unzip the file. if incomplete, If-Range and Range headers are added, and the interrupted DL is resumed.
        }

        return;
    }

    // New download available. This is presumably something after _currentDownload that we've never before tried to DL.

#ifdef DEBUG
    NSUInteger zipped = newDownload.zippedSize;
    NSUInteger unzipped = newDownload.unzippedSize;

    DMINFO(@"new download: %@. zipped: %lu, unzipped: %lu", newDownload.name, (unsigned long)zipped, (unsigned long)unzipped);
#endif // DEBUG

    _oldFileName = _fileName;
    _oldDownload = _currentDownload;

    // in cleanOldDBS, retain oldFileURL, but nothing else. remove all zips and anything except the old DB,
    // which is currently open.
    _zipName = _fileName = nil;
    [self cleanOldDatabases];

    // These values will be rolled back in case the DL/unzip fails (as long as the app keeps running and detects
    // the failure).
    // DEBT: Q. What if the app dies while downloading/unzipping a new DL?
    // A. That event can't be detected. This only really occurs in case of an optional update, not a required one. If the app dies
    // while downloading an optional update, it will no longer be possible to revert to the previous update. In essence, after a
    // crash, the download is no longer optional, since the previous one is no longer viable. This isn't all that hard to fix, but
    // also not all that important.

    _currentDownload = newDownload;
    _zipName = [_currentDownload.name stringByAppendingString:@".zip"];
    _fileName = [_currentDownload.name stringByAppendingString:@".sqlite3"];

    [[NSUserDefaults standardUserDefaults] setValue:_currentDownload.name forKey:DUBSAR_CURRENT_DOWNLOAD_KEY];
    [[NSUserDefaults standardUserDefaults] setValue:_currentDownload.properties[@"mtime"] forKey:DUBSAR_CURRENT_DOWNLOAD_MTIME_KEY];

    [self promptUserOrDownload:_currentDownload];
}

- (void)networkLoadFinished:(DubsarModelsModel *)model
{
    [[UIApplication sharedApplication] stopUsingNetwork];
}

- (void)networkLoadStarted:(DubsarModelsModel *)model
{
    [[UIApplication sharedApplication] startUsingNetwork];
}

#pragma mark - Internal convenience methods

- (void)notifyDelegateOfError:(NSString*)format args:(va_list)args
{
    if (self.downloadInProgress) {
        self.errorMessage = [NSString stringWithFormat:format args:args];
    }

    if (outfile) {
        fclose(outfile);
        outfile = NULL;
    }
    if (uf) {
        unzClose(uf);
        uf = NULL;
    }

    self.downloadInProgress = NO;

    if (![self.delegate respondsToSelector:@selector(databaseManager:encounteredError:)]) return;

    if ([NSThread currentThread] != [NSThread mainThread]) {
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            // [self deleteDatabase];
            [weakself.delegate databaseManager:weakself encounteredError:weakself.errorMessage];
        });
    }
    else {
        // [self deleteDatabase];
        [self.delegate databaseManager:self encounteredError:self.errorMessage];
    }
}

- (void)noUpdateAvailable
{
    if ([_delegate respondsToSelector:@selector(noUpdateAvailable:)]) {
        if ([NSThread mainThread] == [NSThread currentThread]) {
            [_delegate noUpdateAvailable:self];
        }
        else {
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate noUpdateAvailable:weakself];
            });
        }
    }
}

- (void)promptUserOrDownload:(DubsarModelsDownload*)download
{
    /*
     * This is mainly here because of the opacity of the AppConfiguration struct from Swift. Also, leaving app
     * configuration out of this class will make it a bit easier to stuff it into the model framework. The
     * newDownload:Blah: method will simply call download if autoupdate is set. Otherwise, it prompts the
     * user.
     */
    if (self.delegate && [self.delegate respondsToSelector:@selector(newDownloadAvailable:download:required:)]) {
        if (singleThread || [NSThread currentThread] == [NSThread mainThread]) {
            [self.delegate newDownloadAvailable:self download:download required:updateRequired];
        }
        else {
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate newDownloadAvailable:weakself download:download required:updateRequired];
            });
        }
    }
}

- (NSTimeInterval)retryInterval
{
    NSTimeInterval interval = nextRetry;

    nextRetry *= 2.0;
    if (nextRetry > 120.0) nextRetry = 120.0;

    return interval;
}

- (void)monitorDownloadHost
{
    if (!_rootURL) return;

    /*
     * There are potentially two hosts to monitor: The host that serves the download list, and the host that
     * serves the zip file. In production, the first is dubsar.info, the second s.dubsar.info.
     * However, these are the same host. The second is just a cookie-free domain for static assets. In real life,
     * this is always a single host, so we're fine here. In testing, I often download from a local machine to
     * avoid using network bandwidth. I might need to allow both hosts to be monitored here. Not sure if this
     * checks routes to the hosts or just general network availability.
     */

    if (!downloadHost) {
        downloadHost = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, self.rootURL.host.UTF8String);
        if (!downloadHost) {
            DMERROR(@"Could not create reachability ref for %@", self.rootURL.host);
            return;
        }
    }

    SCNetworkReachabilityContext ctx;
    memset(&ctx, 0, sizeof(ctx));
    ctx.info = (__bridge void *)(self);
    SCNetworkReachabilitySetCallback(downloadHost, reachabilityChanged, &ctx);

    if (!SCNetworkReachabilityScheduleWithRunLoop(downloadHost, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
        DMERROR(@"Could not schedule reachability callback with current run loop");
        CFRelease(downloadHost);
        downloadHost = NULL;
        return;
    }

    DMDEBUG(@"Set up reachability callback for %@", self.rootURL.host);
}

- (void)stopMonitoringDownloadHost
{
    if (!downloadHost) return;

    SCNetworkReachabilityUnscheduleFromRunLoop(downloadHost, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

- (void)connectivityChanged:(SCNetworkReachabilityFlags)flags
{
    DMDEBUG(@"Connectivity to %@ changed: %ld", _rootURL.host, (long)flags);

    assert(flags != 0);

    if (flags & kSCNetworkReachabilityFlagsReachable) {
        DMDEBUG(@"Host is reachable.");
    }
    if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
        DMDEBUG(@"Host is reachable by mobile network.");
    }

    if (!(flags & kSCNetworkReachabilityFlagsReachable)) {
        return;
    }

    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive && (flags & kSCNetworkReachabilityFlagsIsWWAN)) {
        DMDEBUG(@"Not downloading in the background over WWAN");
        return;
    }

    nextRetry = 8.0;
    [self stopMonitoringDownloadHost];
    [self download];
}

- (DubsarModelsDownload*)findCorrectDownload:(DubsarModelsDownloadList*)list
{
    DubsarModelsDownload* download = list.downloads.firstObject;
    if (![self acceptableDownload:download]) {
        DMDEBUG(@"First download %@ not acceptable. Looking for others.", download.name);
        int latest = 0;
        download = nil;
        for (DubsarModelsDownload* dl in list.downloads) {
            if (![self acceptableDownload:dl]) continue;

            int version = dl.version;
            if (version > latest) {
                latest = version;
                download = dl;
            }
        }
    }

    return download;
}

- (BOOL)acceptableDownload:(DubsarModelsDownload*)download
{
    int required = [DubsarModelsDownload versionFromDownloadName:_requiredDBVersion];
    int current = download.version;

    if (current < required) {
        DMDEBUG(@"Download %@ does not meet this app's requirement of %@", download.name, _requiredDBVersion);
        return NO;
    }

    NSString* minVersion = download.properties[@"min_ios_version"];
    NSString* maxVersion = download.properties[@"max_ios_version"];

    NSString* appVersion = [NSBundle mainBundle].infoDictionary[(__bridge NSString*)kCFBundleVersionKey];
    assert(appVersion);

    if (minVersion && [self version:appVersion isLessThanVersion:minVersion]) {
        DMDEBUG(@"App version %@ below download min version %@", appVersion, minVersion);
        return NO;
    }

    if (maxVersion && [self version:maxVersion isLessThanVersion:appVersion]) {
        DMDEBUG(@"App version %@ above download max version %@", appVersion, maxVersion);
        return NO;
    }

    return YES;
}

- (void)restoreOldFileOnFailure
{
    if (!self.oldFileExists) return;

    _fileName = _oldFileName;
    _currentDownload = _oldDownload;

    [[NSUserDefaults standardUserDefaults] setValue:_currentDownload.name forKey:DUBSAR_CURRENT_DOWNLOAD_KEY];
    [[NSUserDefaults standardUserDefaults] setValue:_currentDownload.properties[@"mtime"] forKey:DUBSAR_CURRENT_DOWNLOAD_MTIME_KEY];

    _oldFileName = nil;
    _oldDownload = nil;
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
    DMTRACE(@"%f s since last read: %lu bytes", delta, (unsigned long)size);

    if (size < 1024 * 1024 && delta < 5.0) {
        // even it out by only checking every so often
        return;
    }

    DMTRACE(@"On receipt of data, last read time %ld.%06d", self.lastDownloadStatsUpdate.tv_sec, self.lastDownloadStatsUpdate.tv_usec);

    if (delta > 0.0) {
        self.instantaneousDownloadRate = ((double)size) / delta;
        DMTRACE(@"%f B/s instantaneous rate", self.instantaneousDownloadRate);
    }

    if (self.instantaneousDownloadRate > 0) {
        self.estimatedDownloadTimeRemaining = (double)(self.downloadSize - self.downloadedSoFar) / self.instantaneousDownloadRate;
        DMTRACE(@"%f s remaining", self.estimatedDownloadTimeRemaining);
    }

    self.downloadedAtLastStatsUpdate = self.downloadedSoFar;
    self.lastDownloadStatsUpdate = now;

    // This may be a long-running background job on something other than the main thread. But the app may be in the foreground with the
    // SynsetViewController as a delegate.
    if ([self.delegate respondsToSelector:@selector(progressUpdated:)]) {
        if ([NSThread currentThread] == [NSThread mainThread]) {
            [self.delegate progressUpdated:self];
        }
        else {
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate progressUpdated:weakself];
            });
        }
    }
}

- (void)startUnzip
{
    fclose(fp);
    fp = NULL;
    [[UIApplication sharedApplication] stopUsingNetwork];

    // This may be a long-running background job on something other than the main thread. But the app may be in the foreground with the
    // SynsetViewController as a delegate.
    if ([self.delegate respondsToSelector:@selector(unzipStarted:)]) {
        if ([NSThread currentThread] == [NSThread mainThread]) {
            [self.delegate unzipStarted:self];
        }
        else {
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate unzipStarted:weakself];
            });
        }
    }

    [self unzip];
}

- (void)finishDownload
{
    [unzipTimer invalidate];
    unzipTimer = nil;

    if (outfile) {
        fclose(outfile);
        outfile = NULL;
    }
    if (uf) {
        unzClose(uf);
        uf = NULL;
    }

    struct stat sb;
    int rc = stat(self.fileURL.path.UTF8String, &sb);
    if (rc != 0) {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        [self notifyDelegateOfError: @"Error %d (%s) from stat(%@)", error, errbuf, self.fileURL.path];
        return;
    }
    DMDEBUG(@"Unzipped file %@ is %lld bytes", _fileName, sb.st_size);
    if (self.unzippedSize != sb.st_size) {
        DMERROR(@"Unzip file header: %ld. File size is %lld", self.unzippedSize, sb.st_size);
        [self notifyDelegateOfError:@"Failed to validate download"];
        [self deleteDatabase];
        [self restoreOldFileOnFailure];
        return;
    }
    if (_currentDownload.unzippedSize != sb.st_size) {
        DMERROR(@"Advertised database size: %lu. File size is %lld", _currentDownload.unzippedSize, sb.st_size);
        [self notifyDelegateOfError:@"Failed to validate download"];
        [self deleteDatabase];
        [self restoreOldFileOnFailure];
        return;
    }

    NSError* error;

    if (![[NSFileManager defaultManager] removeItemAtURL:self.zipURL error:&error]) {
        DMERROR(@"Error removing %@: %@", self.zipURL.path, error.localizedDescription);
    }

    updateRequired = NO;
    _oldFileName = nil;
    _oldDownload = nil;

    self.downloadInProgress = NO;
    NSURL* fileURL = self.fileURL;
    DMTRACE(@"reopening %@", fileURL);
    [DubsarModelsDatabase instance].databaseURL = fileURL; // reopen the DB that was just downloaded

    if ([NSThread currentThread] != [NSThread mainThread]) {
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself reopenAndNotify];
        });
    }
    else {
        [self reopenAndNotify];
    }
}

- (void)reopenAndNotify
{
    self.databaseUpdated = YES;
    [self cleanOldDatabases];
    if ([self.delegate respondsToSelector:@selector(downloadComplete:)]) {
        [self.delegate downloadComplete:self];
    }
}

- (void)unzipFailedWithError:(NSString*)format,...
{
    va_list args;
    va_start(args, format);

    [self notifyDelegateOfError:format args:args];

    va_end(args);

    unzClose(uf);
    uf = NULL;

    /*
     * In general, if I fail to unzip the file, I should probably delete it, since subsequent attempts are likely to
     * produce the same result, and the bad file will essentially get stuck.
     */

    // removes any zips and all DBS except oldFileURL.
    [self deleteDatabase];

    // then reverts to oldFileURL
    [self restoreOldFileOnFailure];
}

- (void)unzip
{
    struct stat sb;
    int rc = stat(self.zipURL.path.UTF8String, &sb);
    if (rc == 0) {
        DMDEBUG(@"Downloaded file %@ is %lld bytes", _zipName, sb.st_size);
    }
    else {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        [self unzipFailedWithError:@"Error %d (%s) from stat(%@)", error, errbuf, self.fileURL.path];
        return;
    }

    if (sb.st_size != self.downloadSize) {
        DMWARN(@"Content-Length = %ld. File size is %lld.", (long)self.downloadSize, sb.st_size);
    }
    if (sb.st_size != _currentDownload.zippedSize) {
        DMWARN(@"Advertised download size %lu. File size is %lld.", (unsigned long)_currentDownload.zippedSize, sb.st_size);
    }
    
    uf = unzOpen(self.zipURL.path.UTF8String);
    if (!uf) {
        [self unzipFailedWithError: @"unzOpen(%@) failed", self.zipURL.path];
        return;
    }
    DMTRACE(@"Opened zip file");

    rc = unzLocateFile(uf, _fileName.UTF8String, NULL);
    if (rc != UNZ_OK) {
        [self unzipFailedWithError: @"failed to locate %@ in zip %@", _fileName, _zipName];
        return;
    }
    DMTRACE(@"Located %@ in zip file", _fileName);

    rc = unzOpenCurrentFile(uf);
    if (rc != UNZ_OK) {
        [self unzipFailedWithError: @"Failed to open %@ in zip %@", _fileName, _zipName];
        return;
    }
    DMTRACE(@"Opened %@ in zip file", _fileName);

    unz_file_info fileInfo;
    rc = unzGetCurrentFileInfo(uf, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
    if (rc != UNZ_OK) {
        [self unzipFailedWithError: @"Failed to get current file info from zip"];
        return;
    }

    self.unzippedSize = fileInfo.uncompressed_size;
    DMDEBUG(@"Unzipped file will be %ld bytes", (long)_unzippedSize);
    if (_currentDownload.unzippedSize != self.unzippedSize) {
        DMERROR(@"Unzipped file is wrong size: expected %lu, got %lu", _currentDownload.unzippedSize, self.unzippedSize);
        [self unzipFailedWithError:@"Failed to validate download"];
        return;
    }

    outfile = fopen(self.fileURL.path.UTF8String, "w");
    if (!outfile) {
        int error = errno;
        char errbuf[256];
        strerror_r(error, errbuf, 255);
        [self unzipFailedWithError: @"Error %d (%s) opening %@ for write", error, errbuf, self.fileURL.path];
        return;
    }
    DMTRACE(@"Opened %@ for write", _fileName);

    [self excludeFromBackup:self.fileURL];

    unzipTimer = [NSTimer timerWithTimeInterval:DUBSAR_UNZIP_INTERVAL_SECONDS target:self selector:@selector(unzipRead) userInfo:nil repeats:YES];

    [[NSRunLoop currentRunLoop] addTimer:unzipTimer forMode:NSDefaultRunLoopMode];
}

- (void)unzipRead
{
    DMTRACE(@"Reading zip file");

    unsigned char buffer[32768];
    int numberRead = 0;
    struct timeval start, now;
    gettimeofday(&start, NULL);

    double delta = 0.0;

    // DUBSAR_MAX_PER_CYCLE has to be greater than 0 and less than 1. This usually executes on the main thread, which it has to share with other
    // tasks. This is the proportion of the run loop's time that is devoted to the unzip task.
    while (delta < DUBSAR_UNZIP_INTERVAL_SECONDS * DUBSAR_MAX_PER_CYCLE) {
        int nr = unzReadCurrentFile(uf, buffer, sizeof(buffer) * sizeof(unsigned char));

        if (nr <= 0) {
            if (nr < 0) {
                // read error
                [self unzipFailedWithError:@"unzReadCurrentFile returned %d", nr];
                return;
            }

            /*
             * Success. unzReadCurrentFile returned 0.
             */
            [self finishDownload];
            return;
        }

        numberRead += nr;
        self.unzippedSoFar += nr;

        // write the unzipped data to storage
        ssize_t nw = fwrite(buffer, 1, nr, outfile);
        if (nw != nr) {
            int error = errno;
            char errbuf[256];
            strerror_r(error, errbuf, 255);

            // call unzipFailedWithError? That will delete the zip, assuming it's not unzippable. This can very well just mean a full device.
            // DEBT: Check the error code.
            [self notifyDelegateOfError: @"Write failed. Free up space and try again.", nr, _fileName, nw, error, errbuf];
            unzClose(uf);
            uf = NULL;
            return;
        }

        gettimeofday(&now, NULL);
        delta = (double)(now.tv_sec - start.tv_sec) + (double)(now.tv_usec - start.tv_usec) * 1.0e-6;
    }

    lastUpdateSize = self.unzippedSoFar;

    delta = (double)(now.tv_sec - self.lastUnzipRead.tv_sec) + (double)(now.tv_usec - self.lastUnzipRead.tv_usec) * 1.0e-6;

    if (delta > 0.0) {
        self.instantaneousUnzipRate = ((double)numberRead)/ delta;
    }

    if (self.instantaneousUnzipRate > 0.0) {
        self.estimatedUnzipTimeRemaining = ((double)(self.unzippedSize - self.unzippedSoFar)) / self.instantaneousUnzipRate;
    }
    self.lastUnzipRead = now;

    if ([self.delegate respondsToSelector:@selector(progressUpdated:)]) {
        if ([NSThread mainThread] != [NSThread currentThread]) {
            __weak typeof(self) weakself = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.delegate progressUpdated:weakself];
            });
        }
        else {
            [self.delegate progressUpdated:self];
        }
    }

    DMTRACE(@"Unzipped %ld so far. Next read queued", (long)self.unzippedSoFar);
}

- (void)excludeFromBackup:(NSURL*)url {
    NSError* error;
    if (![url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error]) {
        DMERROR(@"Failed to set %@ attribute for file: %@", NSURLIsExcludedFromBackupKey, error.localizedDescription);
    }
}

- (BOOL)version:(NSString*)versionA isLessThanVersion:(NSString*)versionB
{
    NSArray* componentsA = [versionA componentsSeparatedByString:@"."];
    NSArray* componentsB = [versionB componentsSeparatedByString:@"."];

    int j;
    for (j=0; j<componentsA.count && j<componentsB.count; ++j) {
        int componentA = ((NSString*)componentsA[j]).intValue;
        int componentB = ((NSString*)componentsB[j]).intValue;

        if (componentA < componentB) return YES;
        if (componentA > componentB) return NO;
    }

    return componentsA.count < componentsB.count;
}

@end
