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

@import UIKit;

#define DUBSAR_DATABASE_URL @"https://s.dubsar-dictionary.com/dubsar-wn3.1-1.zip"
#define DUBSAR_FILE_NAME @"dubsar-wn3.1-1.sqlite3"
#define DUBSAR_ZIP_NAME @"dubsar-wn3.1-1.zip"

@class DatabaseManager;
@protocol DownloadProgressDelegate <NSObject>

- (void) progressUpdated:(DatabaseManager*)databaseManager;
- (void) downloadComplete:(DatabaseManager*)databaseManager;

@end

@interface DatabaseManager : NSObject<UIAlertViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, readonly) BOOL fileExists;

/**
 * The DB file downloaded by the DatabaseManager needs to reside somewhere other than Caches, where it may be
 * deleted by the OS.
 */
@property (nonatomic, readonly) NSURL* fileURL;

/**
 * The zip file is downloaded to this directory, under Caches. Files there may be automatically deleted by iOS.
 * The zip is automatically deleted by the DatabaseManager when the unzip operation succeeds or when the user
 * opts to delete the local DB. DEBT: Should also clean this up on failure, especially if the failure occurs
 * during download.
 */
@property (nonatomic, readonly) NSURL* zipURL;

@property (atomic, readonly) NSInteger downloadSize;
@property (atomic, readonly) NSInteger downloadedSoFar;
@property (atomic, readonly) NSInteger unzippedSize;
@property (atomic, readonly) NSInteger unzippedSoFar;

@property (atomic, readonly) BOOL downloadInProgress;

@property (nonatomic, weak) id<DownloadProgressDelegate> delegate;

- (void)initialize;

- (void)checkOfflineSetting;

- (void)download;
- (void)deleteDatabase;
- (void)cancelDownload;

@end
