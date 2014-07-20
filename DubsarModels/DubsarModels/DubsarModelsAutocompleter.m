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

#import <sqlite3.h>

#import "DubsarModelsAutocompleter.h"
#import "DubsarModelsDatabaseWrapper.h"
#import "NSString+URLEncoding.h"

@interface DubsarModelsAutocompleter()
@end

@implementation DubsarModelsAutocompleter {
    BOOL aborted;
}

@synthesize seqNum;
@synthesize results=_results;
@synthesize term=_term;
@synthesize matchCase;
@synthesize max;

+ (instancetype)autocompleterWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase
{
    static NSInteger _seqNum = 0;
    return [[self alloc]initWithTerm:theTerm seqNum:_seqNum++ matchCase:mustMatchCase];
}

- (instancetype)initWithTerm:(NSString *)theTerm seqNum:(NSInteger)theSeqNum matchCase:(BOOL)mustMatchCase
{
    self = [super init];
    if (self) {
        seqNum = theSeqNum;
        _term = theTerm;
        _results = nil;
        matchCase = mustMatchCase;
        max = 10;
        aborted = NO;
        
        /*
        NSString* __url = [NSString stringWithFormat:@"/os?term=%@", [_term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
         */
    }
    return self;
}

/* Checked in loadResults: to terminate a search */
- (bool)aborted
{
    @synchronized(self.class) {
        return aborted;
    }
}

- (void)setAborted:(bool)isAborted
{
    @synchronized(self.class) {
        aborted = isAborted;
    }
}

- (void)cancel
{
    self.aborted = YES;
}

- (void)load
{
#if 1
    // Seems to perform better this way
    [NSThread detachNewThreadSelector:@selector(databaseThread:) toTarget:self withObject:self.database];
#else
    dispatch_async(dispatch_get_main_queue(), ^{
        [self databaseThread:self.database];
    });
#endif
}

- (void)loadResults:(DubsarModelsDatabaseWrapper*)database
{
    @synchronized(database) {
        sqlite3_reset(database.exactAutocompleterStmt);
        sqlite3_reset(database.autocompleterStmt);
        
        int rc;
        if ((rc=sqlite3_bind_text(database.exactAutocompleterStmt, 1, _term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }
        
        NSString* exactMatch = nil;
        while (sqlite3_step(database.exactAutocompleterStmt) == SQLITE_ROW) {
            if (aborted) return;
            
            char const* _wName = (char const*)sqlite3_column_text(database.exactAutocompleterStmt, 0);
            NSString* wName = @(_wName);
            
            if (exactMatch == nil) exactMatch = _term;
            
            if ([wName compare:exactMatch options:NSCaseInsensitiveSearch] == NSOrderedSame &&
                [wName compare:exactMatch] == NSOrderedAscending) {
                exactMatch = wName;
            }
        }
        
        if (exactMatch != nil) {
            // NSLog(@"found exact match %@", exactMatch);
            self.results = [NSMutableArray arrayWithObject:exactMatch];
        }
        else {
            self.results = [NSMutableArray array];
        }
        
        if ((rc=sqlite3_bind_text(database.autocompleterStmt, 1, [_term stringByAppendingString:@"*"].UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }
        if ((rc=sqlite3_bind_text(database.autocompleterStmt, 2, _term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }
        if ((rc=sqlite3_bind_int(database.autocompleterStmt, 3, (exactMatch != nil ? max-1 : max))) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;    
        }
        
        // NSLog(@"searching DB for autocompleter matches for %@", _term);
        while (sqlite3_step(database.autocompleterStmt) == SQLITE_ROW) {
            if (aborted) return;
            char const* _name = (char const*)sqlite3_column_text(database.autocompleterStmt, 0);
            NSString* match = @(_name);
            
            [_results addObject:match];
        }
    }
}

- (void)parseData
{
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    
    NSMutableArray* r = [NSMutableArray array];
    NSArray* list = response[1];
    for (int j=0; j<list.count; ++j) {
        [r addObject:list[j]];
    }
    _results = r;

#ifdef DEBUG
    NSLog(@"autocompleter for term \"%@\" (URL \"%@\") finished with %lu results:", response[0], [self _url], (unsigned long)_results.count);
#endif // DEBUG
}

@end
