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
#import <sqlite3.h>

#import "DubsarModelsDatabase.h"
#import "DubsarModelsDatabaseWrapper.h"
#import "DubsarModelsSection.h"

@implementation DubsarModelsSection
@synthesize header;
@synthesize footer;
@synthesize linkType;
@synthesize ptype;
@synthesize numRows=_numRows;
@synthesize senseId;
@synthesize synsetId;

+ (instancetype)section
{
    return [[self alloc]init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        header = nil;
        footer = nil;
        linkType = nil;
        ptype = nil;
        _numRows = senseId = synsetId = 0;
    }
    
    return self;
}

- (NSUInteger)numRows
{
    if ([ptype isEqualToString:@"synonym"] ||
        [ptype isEqualToString:@"verb frame"] ||
        [ptype isEqualToString:@"sample sentence"]) return _numRows;

#ifdef DEBUG
    NSLog(@"counting rows");
#endif // DEBUG

    DubsarModelsDatabaseWrapper* database = [DubsarModelsDatabase instance].database;

    if (!database.dbptr) {
#ifdef DEBUG
        NSLog(@"%d rows of type %@", _numRows, ptype);
#endif // DEBUG
        return _numRows;
    }
    
    NSString* sql;
    if (senseId != 0) {
        sql = [NSString stringWithFormat:
           @"SELECT COUNT(*) FROM "
           @"(SELECT DISTINCT target_id, target_type FROM pointers WHERE "
           @"(ptype = '%@' AND ((source_id = %lu AND source_type = 'Sense') OR "
           @"(source_id = %lu AND source_type = 'Synset'))))", ptype, (unsigned long)senseId, (unsigned long)synsetId];
    }
    else {
        sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM "
               @"(SELECT DISTINCT target_id, target_type FROM pointers WHERE "
               @"ptype = '%@' AND source_id = %lu AND source_type = 'Synset')", ptype, (unsigned long)synsetId];
    }
    int rc;
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing statement", rc);
        return 0;
    }

#ifdef DEBUG
    NSLog(@"executing %@", sql);
#endif // DEBUG
    int count;
    if (sqlite3_step(statement) == SQLITE_ROW) {
        count = sqlite3_column_int(statement, 0);
#ifdef DEBUG
        NSLog(@"%d rows of type %@", count, ptype);
#endif // DEBUG
    }
    
    sqlite3_finalize(statement);
    
    return count;
}

@end
