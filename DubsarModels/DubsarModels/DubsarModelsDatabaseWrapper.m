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

#import "DubsarModels.h"
#import "DubsarModelsDatabaseWrapper.h"

@implementation DubsarModelsDatabaseWrapper

- (instancetype)init
{
    self = [super init];
    if (self) {
        _databaseReady = NO;
        _dbptr = NULL;
        _exactAutocompleterStmt = _autocompleterStmt = _autocompleterStmtWithoutExact = _synsetAutocompleterStmt = NULL;
    }
    return self;
}

- (void)dealloc
{
    [self closeDB];
}

- (void)openDBName:(NSURL *)srcURL
{
    DMTRACE(@"In openDBName:");
    @autoreleasepool {
        [self closeDB];

        if (!srcURL) {
            return;
        }

        int rc;
        if ((rc=sqlite3_open_v2(srcURL.path.UTF8String, &_dbptr, SQLITE_OPEN_FULLMUTEX|SQLITE_OPEN_READONLY, NULL)) != SQLITE_OK) {
            DMERROR(@"error opening database %@, %d", srcURL.path, rc);
            _dbptr = NULL;
            return;
        }

        DMDEBUG(@"successfully opened database %@", srcURL.path);
        NSString* sql;


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

        DMDEBUG(@"preparing statement \"%@\"", sql);
        if ((rc=sqlite3_prepare_v2(_dbptr, sql.UTF8String, -1, &_exactAutocompleterStmt, NULL)) != SQLITE_OK) {
            DMERROR(@"error preparing exact match statement, error %d", rc);
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

        DMDEBUG(@"preparing statement \"%@\"", sql);
        if ((rc=sqlite3_prepare_v2(_dbptr, sql.UTF8String, -1, &_autocompleterStmt, NULL)) != SQLITE_OK) {
            DMERROR(@"error preparing match statement, error %d", rc);
            return;
        }

        /* FTS search when no exact match */
        sql = @"SELECT DISTINCT name "
        @"FROM inflections_fts "
        @"WHERE name MATCH ? "
        @"ORDER BY name ASC "
        @"LIMIT ?";

        DMDEBUG(@"preparing statement \"%@\"", sql);
        if ((rc=sqlite3_prepare_v2(_dbptr, sql.UTF8String, -1, &_autocompleterStmtWithoutExact, NULL)) != SQLITE_OK) {
            DMERROR(@"error preparing match statement, error %d", rc);
            return;
        }

        sql = @"SELECT DISTINCT suggestion "
        "FROM synset_suggestions "
        "WHERE suggestion MATCH ? "
        "ORDER BY synset_id ASC "
        "LIMIT ?";

        DMDEBUG(@"preparing statement \"%@\"", sql);
        if ((rc=sqlite3_prepare_v2(_dbptr, sql.UTF8String, -1, &_synsetAutocompleterStmt, NULL)) != SQLITE_OK) {
            DMERROR(@"error preparing synset match statement, error %d", rc);
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
    sqlite3_finalize(_autocompleterStmtWithoutExact);
    sqlite3_finalize(_synsetAutocompleterStmt);
    sqlite3_close(_dbptr);

    _autocompleterStmt = _exactAutocompleterStmt = _autocompleterStmtWithoutExact = _synsetAutocompleterStmt = NULL;
    _dbptr = NULL;
}

@end
