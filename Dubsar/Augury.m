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

#import <ctype.h>
#import <string.h>

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

- (NSString*)infinitive
{
    Word* verb = [self randomVerb];
    NSLog(@"random infinitive: %@", verb.name);
    return [NSString stringWithFormat:@"to <a style='text-decoration: none;' href='dubsar://iOS/words/%d'>%@</a>", verb._id, verb.name];
}

- (Word*)randomVerb
{
    int verbId = rand()%11531 + 145054;
    Word *word = [Word wordWithId:verbId name:nil partOfSpeech:POSVerb];
    [word loadResults:self.appDelegate];
    return word;
}

- (void)loadResults:(DubsarAppDelegate *)appDelegate
{
#if 0
    // for testing, do this all the time
    [self type2:35];
#else
    int frameId = rand()%171 + 35;
    
    if (frameId == 35) { // 28
        [self type2:frameId];
    }
    else {
        [self type1:frameId];
    }
#endif
}

- (void)type1:(int)frameId
{
    Word* word = [self randomVerb];
    
    NSString* sql = [NSString stringWithFormat:@"SELECT frame FROM verb_frames WHERE id = %d",
                     frameId];
    int rc;
    sqlite3_stmt* statement;
    NSLog(@"preparing statement \"%@\"", sql);
    if ((rc=sqlite3_prepare_v2(self.appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
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
                          word._id, word.name];
    
    /*
     * The selected verb frames are all xxx %s xxx, so we convert the NSString word.name to
     * a C string and use it with the verb frame as a format.
     */
    self.text = [NSString stringWithFormat:frameFormat, [wordLink cStringUsingEncoding:NSUTF8StringEncoding]];
}

- (void)type2:(int)frameId
{
    // verb frame 28: Somebody ----s to INFINITIVE
    NSString* somebody = self.somebody;
    NSString* verb = self.randomVerbForFrame28;
    NSString* infinitive = self.infinitive;
    
    self.text = [NSString stringWithFormat:@"<span>%@ %@ %@</span>", somebody, verb, infinitive];
    
    NSLog(@"self.text = %@", self.text);
}

- (NSString*)somebody
{
    /*
     * SELECT COUNT(se.id) FROM senses se
     *   JOIN synsets sy ON sy.id = se.synset_id
     *   JOIN words w ON w.id = se.word_id
     *   WHERE sy.lexname = 'noun.person'
     *
     * This is expensive, so save the result:
     */
    int count = 21115;
    int rowNumber = rand() % count;
    
    NSString* sql = @"SELECT w.name, se.id FROM senses se "
        "JOIN synsets sy ON sy.id = se.synset_id "
        "JOIN words w ON w.id = se.word_id "
        "WHERE sy.lexname = 'noun.person'";
    sqlite3_stmt* statement;
    int rc;
    
    NSLog(@"preparing statement \"%@\"", sql);
    if ((rc=sqlite3_prepare_v2(self.appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3_prepare_v2: %d", rc);
        return nil;
    }

    int rowCount;
    for (rowCount=0; rowCount < rowNumber && (rc=sqlite3_step(statement)) == SQLITE_ROW; ++rowCount);
    
    if (rc != SQLITE_ROW) {
        NSLog(@"Did not get to row %d, %d", rowNumber, rc);
        return nil;
    }
    
    if ((rc=sqlite3_step(statement)) != SQLITE_ROW) {
        NSLog(@"error retrieving target row at %d, %d", rowNumber, rc);
        return nil;
    }
    
    NSString* name = [NSString stringWithCString:(const char*)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
    int senseId = sqlite3_column_int(statement, 1);
    sqlite3_finalize(statement);
    
    NSLog(@"somebody.name = %@", name);
    if ([name rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location == 0) {
        // if capitalized, no article
        NSString* senseLink = [NSString stringWithFormat:@"<a style='text-decoration: none;' href='dubsar://iOS/senses/%d'>%@</a>",
                               senseId, name];
        return senseLink;
    }
    
    int articleIndex = rand() % 3;
    
    NSString* article = nil;
    switch (articleIndex) {
        case 0:
            // none
            article = [NSString string];
            break;
        case 1:
            // a/an
            if ([name rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"aeiou"]].location == 0) {
                article = @"an ";
            }
            else {
                article = @"a ";
            }
            break;
        default:
            // the
            article = @"the ";
            break;
    }
    
    NSString* somebody = [article stringByAppendingString: name];
    
    NSString* senseLink = [NSString stringWithFormat:@"<a style='text-decoration: none;' href='dubsar://iOS/senses/%d'>%@</a>",
                          senseId, somebody];
    
    return senseLink;
}

- (NSString*)randomVerbForFrame28
{
    /*
     * SELECT COUNT(se.id) FROM senses se
     *   JOIN senses_verb_frames svf ON svf.sense_id = se.id 
     *   WHERE svf.verb_frame_id = 28
     */
    int count = 192;
    int rowNumber = rand() % count;
    
    NSString* sql = @"SELECT w.id, se.id FROM words w "
    "JOIN senses se ON se.word_id = w.id "
    "JOIN senses_verb_frames svf ON svf.sense_id = se.id "
    "WHERE svf.verb_frame_id = 28";
    sqlite3_stmt* statement;
    int rc;
    
    NSLog(@"preparing statement \"%@\"", sql);
    if ((rc=sqlite3_prepare_v2(self.appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3_prepare_v2: %d", rc);
        return nil;
    }
    
    int rowCount;
    for (rowCount=0; rowCount < rowNumber && (rc=sqlite3_step(statement)) == SQLITE_ROW; ++rowCount);
    
    if (rc != SQLITE_ROW) {
        NSLog(@"Did not get to row %d, %d", rowNumber, rc);
        return nil;
    }
    
    if ((rc=sqlite3_step(statement)) != SQLITE_ROW) {
        NSLog(@"error retrieving target row at %d, %d", rowNumber, rc);
        return nil;
    }
    
    int verbId = sqlite3_column_int(statement, 0);
    int senseId = sqlite3_column_int(statement, 1);
    sqlite3_finalize(statement);
    
    // now find the third-person singular
    sql = [NSString stringWithFormat:@"SELECT name FROM inflections WHERE word_id = %d AND name LIKE '%%s' LIMIT 1", verbId];
    if ((rc=sqlite3_prepare_v2(self.appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"preparing inflections select: %d", rc);
        return nil;
    }
    
    NSString* tps = nil;
    if ((rc=sqlite3_step(statement)) != SQLITE_ROW) {
        NSLog(@"No result found");
        Word* word = [Word wordWithId:verbId name:nil partOfSpeech:POSVerb];
        [word loadResults:self.appDelegate];
        tps = [word.name stringByAppendingString:@"s"]; // punt
    }
    else {
        // take the first match, regardless
        tps = [NSString stringWithCString:(const char*)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
    }
    
    NSLog(@"random verb (28) is %@", tps);
    sqlite3_finalize(statement);
    return [NSString stringWithFormat:@"<a style='text-decoration: none;' href='dubsar://iOS/senses/%d'>%@</a>", senseId, tps];
}

@end
