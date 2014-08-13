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
@import Foundation;

#define DUBSAR_PRODUCTION_ROOT_URL @"https://s.dubsar-dictionary.com"
#define DUBSAR_DEVELOPMENT_ROOT_URL @"http://192.168.2.101"

@class DatabaseManager;

#pragma mark - Delegate
@protocol DatabaseManagerDelegate <NSObject>

@optional
- (void) databaseManager:(DatabaseManager*)databaseManager encounteredError:(NSString*)errorMessage;
@optional
- (void) downloadStarted:(DatabaseManager*)databaseManager;
@optional
- (void) progressUpdated:(DatabaseManager*)databaseManager;
@optional
- (void) downloadComplete:(DatabaseManager*)databaseManager;
@optional
- (void) unzipStarted:(DatabaseManager*)databaseManager;
@optional
- (void) newDownloadAvailable:(DatabaseManager*)databaseManager name:(NSString*)downloadName zipped:(NSUInteger)zippedSize unzipped:(NSUInteger)unzippedSize;

@end

/**
 * This will move into DubsarModels.
 */
@interface DatabaseManager : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate, DubsarModelsLoadDelegate>

#pragma mark - Readonly properties

/**
 * The unzipped DB file downloaded and installed by the DatabaseManager resides in the application support directory.
 */
@property (atomic, copy, readonly) NSString* fileName;
@property (nonatomic, readonly) NSURL* fileURL;
@property (nonatomic, readonly) BOOL fileExists;
@property (nonatomic, copy, readonly) NSString* oldFileName;
@property (nonatomic, readonly) NSURL* oldFileURL;
@property (nonatomic, readonly) BOOL oldFileExists;
@property (nonatomic, copy, readonly) NSString* requiredDBVersion;
@property (atomic, readonly) DubsarModelsDownload* currentDownload;
@property (atomic, readonly) DubsarModelsDownload* oldDownload;
@property (atomic, readonly) NSInteger downloadSize;
@property (atomic, readonly) NSInteger downloadedSoFar;
@property (atomic, readonly) NSInteger unzippedSize;
@property (atomic, readonly) NSInteger unzippedSoFar;
@property (atomic, readonly) BOOL downloadInProgress;
@property (atomic, readonly) double instantaneousDownloadRate; // bytes per second
@property (atomic, readonly) NSTimeInterval estimatedDownloadTimeRemaining; // seconds
@property (atomic, readonly) NSTimeInterval elapsedDownloadTime; // seconds
@property (atomic, readonly) double instantaneousUnzipRate; // bytes per second
@property (atomic, readonly) NSTimeInterval estimatedUnzipTimeRemaining; // seconds
@property (atomic, readonly, copy) NSString* errorMessage;

#pragma mark - Configurable properties

@property (atomic, weak) id<DatabaseManagerDelegate> delegate;
@property (atomic) NSURL* rootURL;

#pragma mark - Public methods
- (void)initialize;

/*
 * These three methods can be called from any thread, and the download can occur on any thread, including in the
 * background on the main thread (by calling the first method on the main thread). In all cases, callbacks to the
 * delegate occur on the main thread.
 */

/**
 * Download in the background on the current thread. This is mainly useful when running on the main thread. Instantiates an NSURLConnection
 * whose callbacks will be returned on the same thread by [NSRunLoop currentRunLoop].
 */
- (void)download;

/**
 * Download in the current thread and block until the download completes or fails. Unlike 
 * [NSURConnection sendSynchronousRequest:returningResponse:error:], which buffers and returns the downloaded data in memory 
 * (in this case 33 MB), this method saves the data directly to the Caches directory while downloading. Since an interrupted download can be
 * resumed without repeating the previously downloaded portion, this method is more resilient in case of catastrophic failure. This method
 * should not be used on the main thread.
 */
- (void)downloadSynchronous;

/**
 * Run [self downloadSynchronous] in a background thread. The [self download] method also downloads in the background, but it does not
 * execute the run loop. You can execute the run loop separately yourself, but that method is mainly useful when the run loop is already
 * being executed elsewhere (i.e., when you are on the main thread). This method creates a thread for the sole purpose of dispatching the
 * download request and its response and content. The thread terminates when the download is complete or fails.
 */
- (void)downloadInBackground;

- (void)deleteDatabase;
- (void)cancelDownload;

- (void)checkForUpdate;
- (void)cleanOldDatabases;

// for Swift
- (void)reportError:(NSString*)errorMessage;
- (void)clearError;

@end
