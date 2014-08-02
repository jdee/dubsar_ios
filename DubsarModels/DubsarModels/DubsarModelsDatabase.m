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

#import "DubsarModelsDatabase.h"
#import "DubsarModelsDatabaseWrapper.h"

@implementation DubsarModelsDatabase

+ (DubsarModelsDatabase *)instance
{
    static DubsarModelsDatabase* _instance = nil;
    if (!_instance) {
        _instance = [[self alloc] init];
    }
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _database = [[DubsarModelsDatabaseWrapper alloc] init];
        [_database openDBName:_databaseURL];
    }
    return self;
}

- (void)setDatabaseURL:(NSURL*)databaseURL
{
    _databaseURL = databaseURL;
    [_database closeDB];
    [_database openDBName:_databaseURL];
}

- (void)closeDB
{
    [_database closeDB];
}

@end
