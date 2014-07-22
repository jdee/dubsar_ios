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

#import "DubsarModelsDatabaseWrapper.h"

#define PRODUCTION_DB_NAME @"production.sqlite3"

@implementation DubsarModelsDatabaseWrapper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _databaseReady = NO;
        _dbptr = NULL;
        _exactAutocompleterStmt = _autocompleterStmt = NULL;
    }
    return self;
}

- (void)dealloc
{
    [self closeDB];
}

- (void)openDBName:(NSString *)dbName
{
    [self openDBName:dbName recreateFTSTables:NO];
}

- (void)openDBName:(NSString*)dbName recreateFTSTables:(BOOL)recreateFTSTables
{
    @autoreleasepool {
        NSURL* resourceURL = [[NSBundle mainBundle] resourceURL];

        NSURL* srcURL = nil;
        if (dbName) {
            srcURL = [resourceURL URLByAppendingPathComponent:dbName];
        }
        else {
            srcURL = [resourceURL URLByAppendingPathComponent:PRODUCTION_DB_NAME];
        }

#ifdef DUBSAR_EDITORIAL_BUILD
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSArray* urls = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSURL* url = [urls objectAtIndex:0];
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSURL* appDataDir = [[url URLByAppendingPathComponent:appBundleID]
                             URLByAppendingPathComponent:@"Data"];
        NSString* installedDBPath = nil;
        if (dbName) {
            installedDBPath = [[appDataDir path] stringByAppendingPathComponent:dbName];
        } else {
            installedDBPath = [[appDataDir path] stringByAppendingPathComponent:PRODUCTION_DB_NAME];
        }

        if (![fileManager fileExistsAtPath:[appDataDir path]]) {
            NSError* error;
            if (![fileManager createDirectoryAtURL:appDataDir withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"creating app data dir: %@", error.localizedDescription);
                return;
            }
        }

        if (![fileManager fileExistsAtPath:installedDBPath]) {
            NSError* error;
            if (![fileManager copyItemAtURL:srcURL toURL:[NSURL fileURLWithPath:installedDBPath] error:&error]) {
                NSLog(@"copying DB: %@", error.localizedDescription);
                return;
            }
            NSLog(@"Copied DB to application data directory");
        }

        [self closeDB];

        int rc;
        if ((rc=sqlite3_open_v2(installedDBPath.UTF8String, &database, SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_READWRITE, NULL)) != SQLITE_OK) {
            NSLog(@"error opening database %@, %d", installedDBPath, rc);
            database = NULL;
            return;
        }
#else
        [self closeDB];

        int rc;
        if ((rc=sqlite3_open_v2(srcURL.path.UTF8String, &_dbptr, SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_READONLY, NULL)) != SQLITE_OK) {
            NSLog(@"error opening database %@, %d", srcURL.path, rc);
            _dbptr = NULL;
            return;
        }
#endif // DUBSAR_EDITORIAL_BUILD

        NSLog(@"successfully opened database %@", dbName);
        NSString* sql;

#ifdef DUBSAR_EDITORIAL_BUILD
        if (recreateFTSTables) {
            sqlite3_stmt* statement;
            if ((rc=sqlite3_prepare_v2(database,
                                       "DELETE FROM inflections", -1, &statement, NULL)) != SQLITE_OK) {
                NSLog(@"sqlite3 error %d", rc);
                return;
            }
            sqlite3_step(statement);
            sqlite3_finalize(statement);

            if ((rc=sqlite3_prepare_v2(database,
                                       "DROP TABLE IF EXISTS inflections_fts", -1, &statement, NULL)) != SQLITE_OK) {
                NSLog(@"sqlite3 error %d", rc);
                return;
            }
            sqlite3_step(statement);
            sqlite3_finalize(statement);

            if ((rc=sqlite3_prepare_v2(database,
                                       "DROP TABLE IF EXISTS inflections_fts_content", -1, &statement, NULL)) != SQLITE_OK) {
                NSLog(@"sqlite3 error %d", rc);
                return;
            }
            sqlite3_step(statement);
            sqlite3_finalize(statement);

            if ((rc=sqlite3_prepare_v2(database,
                                       "DROP TABLE IF EXISTS inflections_fts_segdir", -1, &statement, NULL)) != SQLITE_OK) {
                NSLog(@"sqlite3 error %d", rc);
                return;
            }
            sqlite3_step(statement);
            sqlite3_finalize(statement);

            if ((rc=sqlite3_prepare_v2(database,
                                       "DROP TABLE IF EXISTS inflections_fts_segments", -1, &statement, NULL)) != SQLITE_OK) {
                NSLog(@"sqlite3 error %d", rc);
                return;
            }
            sqlite3_step(statement);
            sqlite3_finalize(statement);

            if ((rc=sqlite3_prepare_v2(database,
                                       "CREATE VIRTUAL TABLE inflections_fts USING fts3(id, name, word_id)", -1, &statement, NULL)) != SQLITE_OK) {
                NSLog(@"sqlite3 error %d", rc);
                return;
            }
            sqlite3_step(statement);
            sqlite3_finalize(statement);
        }
#endif // DUBSAR_EDITORIAL_BUILD

        /*
         * Prepared statements for the Autocompleter
         */

        /*
         * Exact match first. By using >= here, we get back "treatment" when the user types "treatm" as an
         * exact match, filtered to the top. This makes the app seem to anticipate the typing.
         */
        sql = @"SELECT name "
        @"FROM inflections "
        @"WHERE name >= ? "
        @"ORDER BY name ASC "
        @"LIMIT 1";

        NSLog(@"preparing statement \"%@\"", sql);
        if ((rc=sqlite3_prepare_v2(_dbptr, sql.UTF8String, -1, &_exactAutocompleterStmt, NULL)) != SQLITE_OK) {
            NSLog(@"error preparing exact match statement, error %d", rc);
            return;
        }

        /*
         * This next step needs work. The idea is to remove any duplication from the AC results by removing any
         * inflection if the root word is in the results. This doesn't exactly accomplish that. It's possible for
         * FTS matches to have inflections included, but they are usually phrases that don't have inflections.
         * To do this right, you'd need a words_fts table and something like NOT w.name MATCH ? in the WHERE
         * clause, with ? bound to term*, like the i.name MATCH clause above it.
         *
         * The w.name != ? condition is enough to filter out "teammates" when the user types "teamm."
         */

        /* FTS search */
        sql = @"SELECT DISTINCT i.name "
        @"FROM inflections_fts i "
        @"JOIN words w ON w.id = i.word_id "
        @"WHERE i.name MATCH ? AND i.name != ? "
        @"AND w.name != ? " // filter out inflections of the exact match
        @"ORDER BY i.name ASC "
        @"LIMIT ?";

        NSLog(@"preparing statement \"%@\"", sql);
        if ((rc=sqlite3_prepare_v2(_dbptr, sql.UTF8String, -1, &_autocompleterStmt, NULL)) != SQLITE_OK) {
            NSLog(@"error preparing match statement, error %d", rc);
            return;
        }
        
        self.databaseReady = YES;
        
    }
}

- (void)closeDB
{
    if (!_dbptr) return;

    sqlite3_finalize(_autocompleterStmt);
    sqlite3_finalize(_exactAutocompleterStmt);
    sqlite3_close(_dbptr);

    _autocompleterStmt = _exactAutocompleterStmt = NULL;
    _dbptr = NULL;
}

@end
