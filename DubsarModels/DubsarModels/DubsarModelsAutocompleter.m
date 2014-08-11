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

@import Foundation;

#import <sqlite3.h>

#import "DubsarModels.h"
#import "DubsarModelsAutocompleter.h"
#import "DubsarModelsDatabaseWrapper.h"

@interface DubsarModelsAutocompleter()
@property (nonatomic) NSURLConnection* connection;
@end

@implementation DubsarModelsAutocompleter {
    BOOL aborted;
}

@synthesize seqNum;
@synthesize results=_results;
@synthesize term=_term;
@synthesize matchCase;
@synthesize max;

+ (instancetype)autocompleterWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase scope:(DubsarModelsSearchScope)scope
{
    static NSInteger _seqNum = 0;
    return [[self alloc]initWithTerm:theTerm seqNum:_seqNum++ matchCase:mustMatchCase scope:scope];
}

- (instancetype)initWithTerm:(NSString *)theTerm seqNum:(NSInteger)theSeqNum matchCase:(BOOL)mustMatchCase scope:(DubsarModelsSearchScope)scope
{
    self = [super init];
    if (self) {
        seqNum = theSeqNum;
        _term = theTerm;
        _results = nil;
        _scope = scope;
        matchCase = mustMatchCase;
        max = 10;
        aborted = NO;
        
        NSString* __url = [NSString stringWithFormat:@"/os?term=%@", [_term stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
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
    [self.connection cancel];
    if (!self.database.dbptr) {
        [self callDelegateSelectorOnMainThread:@selector(networkLoadFinished:) withError:nil];
    }
}

- (void)loadResults:(DubsarModelsDatabaseWrapper*)database
{
    @synchronized(database) {
        sqlite3_reset(database.exactAutocompleterStmt);
        sqlite3_reset(database.autocompleterStmt);
        sqlite3_reset(database.autocompleterStmtWithoutExact);
        sqlite3_reset(database.synsetAutocompleterStmt);
        
        int rc;

        if (_scope == DubsarModelsSearchScopeWords) {
            if ((rc=sqlite3_bind_text(database.exactAutocompleterStmt, 1, _term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }

            NSString* exactMatch = nil;
            if (sqlite3_step(database.exactAutocompleterStmt) == SQLITE_ROW) {
                if (aborted) return;

                char const* _wName = (char const*)sqlite3_column_text(database.exactAutocompleterStmt, 0);
                exactMatch = @(_wName);
                if (![exactMatch hasPrefix:_term]) {
                    exactMatch = nil;
                }
            }

            if (exactMatch) {
                // DMLOG(@"found exact match %@", exactMatch);
                self.results = [NSMutableArray arrayWithObject:exactMatch];
                [self updateDelegate];

                if ((rc=sqlite3_bind_text(database.autocompleterStmt, 1, [_term stringByAppendingString:@"*"].UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                    self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                    return;
                }
                if ((rc=sqlite3_bind_text(database.autocompleterStmt, 2, exactMatch.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                    self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                    return;
                }
                if ((rc=sqlite3_bind_text(database.autocompleterStmt, 3, exactMatch.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                    self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                    return;
                }
                if ((rc=sqlite3_bind_int(database.autocompleterStmt, 4, (int)(max-1))) != SQLITE_OK) {
                    self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                    return;
                }

                // DMLOG(@"searching DB for autocompleter matches for %@", _term);
                while ((rc=sqlite3_step(database.autocompleterStmt)) == SQLITE_ROW) {
                    if (aborted) return;
                    char const* _name = (char const*)sqlite3_column_text(database.autocompleterStmt, 0);
                    NSString* match = @(_name);

                    [_results addObject:match];
                    [self updateDelegate];
                }

                if (rc != SQLITE_DONE) {
                    DMERROR(@"Autocompleter FTS search failed: %d", rc);
                }
            }
            else {
                self.results = [NSMutableArray array];

                if ((rc=sqlite3_bind_text(database.autocompleterStmtWithoutExact, 1, [_term stringByAppendingString:@"*"].UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                    self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                    return;
                }
                if ((rc=sqlite3_bind_int(database.autocompleterStmtWithoutExact, 2, (int)max)) != SQLITE_OK) {
                    self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                    return;
                }

                // DMLOG(@"searching DB for autocompleter matches for %@", _term);
                while ((rc=sqlite3_step(database.autocompleterStmtWithoutExact)) == SQLITE_ROW) {
                    if (aborted) return;
                    char const* _name = (char const*)sqlite3_column_text(database.autocompleterStmtWithoutExact, 0);
                    NSString* match = @(_name);
                    
                    // DMLOG(@"autocompleter matched %@", match);
                    
                    [_results addObject:match];
                    [self updateDelegate];
                }
                
                if (rc != SQLITE_DONE) {
                    DMERROR(@"Autocompleter FTS search failed: %d", rc);
                }
            }
        }
        else if (_scope == DubsarModelsSearchScopeSynsets) {
            if ((rc=sqlite3_bind_text(database.synsetAutocompleterStmt, 1, [_term stringByAppendingString:@"*"].UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }
            if ((rc=sqlite3_bind_int(database.synsetAutocompleterStmt, 2, (int)max)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }

            self.results = [NSMutableArray array];
            while ((rc=sqlite3_step(database.synsetAutocompleterStmt)) == SQLITE_ROW) {
                if (aborted) return;
                char const* _suggestion = (char const*)sqlite3_column_text(database.synsetAutocompleterStmt, 0);
                [_results addObject:@(_suggestion)];
                [self updateDelegate];
            }

            if (rc != SQLITE_DONE) {
                DMERROR(@"Autocompleter synsets FTS search failed: %d", rc);
            }
        }
    }
}

- (void)parseData
{
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    
    NSMutableArray* r = [NSMutableArray array];
    NSArray* list = response[1];
    for (int j=0; j<list.count && j < max; ++j) {
        [r addObject:list[j]];
    }
    _results = r;

    DMTRACE(@"autocompleter for term \"%@\" (URL \"%@\") finished with %lu results:", response[0], [self _url], (unsigned long)_results.count);
}

- (void)updateDelegate
{
    if (![self.delegate respondsToSelector:@selector(newResultFound:model:)]) {
        return;
    }

    DMTRACE(@"Updating delegate with %lu results", (unsigned long)_results.count);

    if ([NSThread currentThread] == [NSThread mainThread]) {
        [self.delegate newResultFound:nil model:self];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate newResultFound:nil model:self];
    });
}

@end
