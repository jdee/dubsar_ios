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
@synthesize max;
@synthesize aborted;
@synthesize lock;

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

- (void)dealloc
{
    // NSLog(@"releasing autocompleter for term %@", _term);
    [_term release];
    [_results release];
    [super dealloc];
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
    [NSThread detachNewThreadSelector:@selector(databaseThread:) toTarget:self withObject:UIApplication.sharedApplication.delegate];
}

- (void)loadResults:(DubsarAppDelegate*)appDelegate
{
    @synchronized(appDelegate) {
        sqlite3_reset(appDelegate.exactAutocompleterStmt);
        sqlite3_reset(appDelegate.autocompleterStmt);
        
        int rc;
        if ((rc=sqlite3_bind_text(appDelegate.exactAutocompleterStmt, 1, [_term cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }
        
        NSString* exactMatch = nil;
        while (sqlite3_step(appDelegate.exactAutocompleterStmt) == SQLITE_ROW) {
            if (aborted) return;
            
            char const* _wName = (char const*)sqlite3_column_text(appDelegate.exactAutocompleterStmt, 0);            
            NSString* wName = [NSString stringWithCString:_wName encoding:NSUTF8StringEncoding];
            
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
        
        if ((rc=sqlite3_bind_text(appDelegate.autocompleterStmt, 1, [_term cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }
        if ((rc=sqlite3_bind_text(appDelegate.autocompleterStmt, 2, [_term cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }
        if ((rc=sqlite3_bind_text(appDelegate.autocompleterStmt, 3, [_term cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;
        }
        if ((rc=sqlite3_bind_int(appDelegate.autocompleterStmt, 4, (exactMatch != nil ? max-1 : max))) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return;    
        }
        
        // NSLog(@"searching DB for autocompleter matches for %@", _term);
        while (sqlite3_step(appDelegate.autocompleterStmt) == SQLITE_ROW) {
            if (aborted) return;
            char const* _name = (char const*)sqlite3_column_text(appDelegate.autocompleterStmt, 0);
            NSString* match = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];
            
            [_results addObject:match];
        }
    }
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
