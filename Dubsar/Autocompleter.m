/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
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

#import "Autocompleter.h"
#import "JSONKit.h"
#import "URLEncoding.h"

@implementation Autocompleter

@synthesize seqNum;
@synthesize results=_results;
@synthesize term=_term;
@synthesize matchCase;

+ (id)autocompleterWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase
{
    static NSInteger _seqNum = 0;
    return [[[self alloc]initWithTerm:theTerm seqNum:_seqNum++ matchCase:mustMatchCase]autorelease];
}

- (id)initWithTerm:(NSString *)theTerm seqNum:(NSInteger)theSeqNum matchCase:(BOOL)mustMatchCase
{
    self = [super init];
    if (self) {
        seqNum = theSeqNum;
        _term = [theTerm retain];
        _results = nil;
        matchCase = mustMatchCase;
        
        /*
        NSString* __url = [NSString stringWithFormat:@"/os?term=%@", [_term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
         */
    }
    return self;
}

- (void)dealloc
{
    [_term release];
    [_results release];
    [super dealloc];
}

/*
- (void)load
{
    [NSThread detachNewThreadSelector:@selector(databaseThread) toTarget:self withObject:nil];
}
 */

- (void)loadResults:(DubsarAppDelegate*)appDelegate
{
    NSString* sql = [NSString stringWithFormat:@"SELECT w.name "
                     @"FROM inflections i "
                     @"INNER JOIN words w "
                     @"ON w.id = i.word_id "
                     @"WHERE i.name = '%@' "
                     @"ORDER BY w.name ASC", _term];
    NSLog(@"preparing statement \"%@\"", sql);
    sqlite3_stmt* statement;
    int rc;
    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
    else {
        NSLog(@"prepared statement successfully");
    }
    
    NSString* exactMatch = nil;
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _wName = (char const*)sqlite3_column_text(statement, 0);
        char const* _iName = (char const*)sqlite3_column_text(statement, 1);
        NSLog(@"autocompleter matched WORD %s, INFLECTION %s", _wName, _iName);
        NSString* wName = [NSString stringWithCString:_wName encoding:NSUTF8StringEncoding];

        if (exactMatch == nil) exactMatch = _term;
        
        if ([wName compare:exactMatch options:NSCaseInsensitiveSearch] == NSOrderedSame &&
            [wName compare:exactMatch] == NSOrderedAscending) {
            exactMatch = wName;
        }
    }
    sqlite3_finalize(statement);
    
    if (exactMatch != nil) {
        self.results = [NSMutableArray arrayWithObject:exactMatch];
    }
    else {
        self.results = [NSMutableArray array];
    }
    
    sql = [NSString stringWithFormat:
           @"SELECT DISTINCT name "
           @"FROM words "
           @"WHERE name > '%@' AND name < '%@' "
           @"ORDER BY name ASC "
           @"LIMIT %d", _term, [self.class incrementString:_term], (exactMatch != nil ? 9 : 10)];
    NSLog(@"preparing statement \"%@\"", sql);

    if ((rc=sqlite3_prepare_v2(appDelegate.database,
                               [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
    else {
        NSLog(@"prepared statement successfully");
    }
    
    NSLog(@"searching DB for autcompleter matches");
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _name = (char const*)sqlite3_column_text(statement, 0);
        NSString* match = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];
        
        [_results addObject:match];
    }
    sqlite3_finalize(statement);
    NSLog(@"done searching for autocompleter matches");
}

- (void)parseData
{
    NSArray* response = [[self decoder] objectWithData:[self data]];
    
    NSMutableArray* r = [[NSMutableArray array]retain];
    NSArray* list = [response objectAtIndex:1];
    for (int j=0; j<list.count; ++j) {
        [r addObject:[list objectAtIndex:j]];
    }
    _results = r;
    
    NSLog(@"autocompleter for term \"%@\" (URL \"%@\") finished with %d results:", [response objectAtIndex:0], [self _url], _results.count);
}

@end
