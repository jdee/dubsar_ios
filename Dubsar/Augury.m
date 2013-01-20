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

#import "Augury.h"
#import "Word.h"

@implementation Augury

@synthesize text;

+ (id) augury
{
    return [[[Augury alloc] init] autorelease];
}

- (id) init
{
    self = [super init];
    if (self) {
        self.text = nil;
    }
    return self;
}

- (void)loadResults:(DubsarAppDelegate *)appDelegate
{
    int frameId = rand()%170 + 36;
    int verbId = rand()%11531 + 145054;
    
    Word *word = [Word wordWithId:verbId name:nil partOfSpeech:POSVerb];
    [word loadResults:appDelegate];
    
    NSString* sql = [NSString stringWithFormat:@"SELECT frame FROM verb_frames WHERE id = %d",
                     frameId];
    int rc;
    sqlite3_stmt* statement;
    NSLog(@"preparing statement \"%@\"", sql);
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3_prepare_v2: %d", rc);
        return;
    }
    
    NSString* frameFormat = nil;
    if ((rc=sqlite3_step(statement)) == SQLITE_ROW) {
        char const* _frame = (char const*)sqlite3_column_text(statement, 0);
        frameFormat = [NSString stringWithCString:_frame encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"failed to find verb frame %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    sqlite3_finalize(statement);
    
    NSString* wordLink = [NSString stringWithFormat:@"<a style='text-decoration: none;' href='dubsar://iOS/words/%d'>%@</a>",
                          verbId, word.name];
    
    /*
     * The selected verb frames are all xxx %s xxx, so we convert the NSString word.name to
     * a C string and use it with the verb frame as a format.
     */
    self.text = [NSString stringWithFormat:frameFormat, [wordLink cStringUsingEncoding:NSUTF8StringEncoding]];
}

@end
