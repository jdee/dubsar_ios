/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
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
#import "URLEncoding.h"

@implementation Autocompleter

@synthesize seqNum;
@synthesize results=_results;
@synthesize term=_term;
@synthesize matchCase;
@synthesize max;
@synthesize aborted;
@synthesize lock;

+ (id)autocompleterWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase
{
    static NSInteger _seqNum = 0;
    return [[self alloc]initWithTerm:theTerm seqNum:_seqNum++ matchCase:mustMatchCase];
}

- (id)initWithTerm:(NSString *)theTerm seqNum:(NSInteger)theSeqNum matchCase:(BOOL)mustMatchCase
{
    self = [super init];
    if (self) {
        seqNum = theSeqNum;
        _term = theTerm;
        _results = nil;
        matchCase = mustMatchCase;
        max = 10;
        aborted = false;
        
        /*
        NSString* __url = [NSString stringWithFormat:@"/os?term=%@", [_term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
         */
    }
    return self;
}

/* Called in loadResults: to terminate a search */
- (bool)aborted
{
    @synchronized(lock) {
        return aborted;
    }
}

/* Don't synchronize this; leave that to the caller, so termination can be atomic */
- (void)setAborted:(bool)isAborted
{
    aborted = isAborted;
}

- (void)load
{
#if 1
    // Seems to perform better this way
    [NSThread detachNewThreadSelector:@selector(databaseThread:) toTarget:self withObject:UIApplication.sharedApplication.delegate];
#else
    dispatch_async(dispatch_get_main_queue(), ^{
        [self databaseThread:UIApplication.sharedApplication.delegate];
    });
#endif
}

- (void)loadResults:(DubsarAppDelegate*)appDelegate
{
    @synchronized(appDelegate) {
        sqlite3_reset(appDelegate.exactAutocompleterStmt);
        sqlite3_reset(appDelegate.autocompleterStmt);
        sqlite3_reset(appDelegate.autocompleterStmtWithoutExact);

        int rc;
        if ((rc=sqlite3_bind_text(appDelegate.exactAutocompleterStmt, 1, _term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }

        NSString* exactMatch = nil;
        if (sqlite3_step(appDelegate.exactAutocompleterStmt) == SQLITE_ROW) {
            if (aborted) return;

            char const* _wName = (char const*)sqlite3_column_text(appDelegate.exactAutocompleterStmt, 0);
            exactMatch = @(_wName);
            if (![exactMatch hasPrefix:_term]) {
                exactMatch = nil;
            }
        }

        if (exactMatch) {
            // NSLog(@"found exact match %@", exactMatch);
            self.results = [NSMutableArray arrayWithObject:exactMatch];

            if ((rc=sqlite3_bind_text(appDelegate.autocompleterStmt, 1, [_term stringByAppendingString:@"*"].UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }
            if ((rc=sqlite3_bind_text(appDelegate.autocompleterStmt, 2, exactMatch.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }
            if ((rc=sqlite3_bind_text(appDelegate.autocompleterStmt, 3, exactMatch.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }
            if ((rc=sqlite3_bind_int(appDelegate.autocompleterStmt, 4, max - 1)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }

            // NSLog(@"searching DB for autocompleter matches for %@", _term);
            while ((rc=sqlite3_step(appDelegate.autocompleterStmt)) == SQLITE_ROW) {
                if (aborted) return;
                char const* _name = (char const*)sqlite3_column_text(appDelegate.autocompleterStmt, 0);
                NSString* match = @(_name);

                [_results addObject:match];
            }

            if (rc != SQLITE_DONE) {
                NSLog(@"Autocompleter FTS search failed: %d", rc);
            }
        }
        else {
            self.results = [NSMutableArray array];

            if ((rc=sqlite3_bind_text(appDelegate.autocompleterStmtWithoutExact, 1, [_term stringByAppendingString:@"*"].UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }
            if ((rc=sqlite3_bind_int(appDelegate.autocompleterStmtWithoutExact, 2, max)) != SQLITE_OK) {
                self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
                return;
            }

            // NSLog(@"searching DB for autocompleter matches for %@", _term);
            while ((rc=sqlite3_step(appDelegate.autocompleterStmtWithoutExact)) == SQLITE_ROW) {
                if (aborted) {
                    NSLog(@"Aborted");
                    return;
                }
                char const* _name = (char const*)sqlite3_column_text(appDelegate.autocompleterStmtWithoutExact, 0);
                NSString* match = @(_name);

                // NSLog(@"autocompleter matched %@", match);

                [_results addObject:match];
            }

            if (rc != SQLITE_DONE) {
                NSLog(@"Autocompleter FTS search failed: %d", rc);
            }
        }
    }
}

- (void)parseData
{
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    
    NSMutableArray* r = [NSMutableArray array];
    NSArray* list = [response objectAtIndex:1];
    for (int j=0; j<list.count; ++j) {
        [r addObject:[list objectAtIndex:j]];
    }
    _results = r;

#ifdef DEBUG
    NSLog(@"autocompleter for term \"%@\" (URL \"%@\") finished with %d results:", [response objectAtIndex:0], [self _url], _results.count);
#endif // DEBUG
}

@end
