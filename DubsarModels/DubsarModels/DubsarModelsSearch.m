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

#import "DubsarModelsDatabaseWrapper.h"
#import "DubsarModelsSearch.h"
#import "DubsarModelsPartOfSpeechDictionary.h"
#import "DubsarModelsSense.h"
#import "DubsarModelsSynset.h"
#import "DubsarModelsWord.h"

static int _seqNum = 0;
#define NUM_PER_PAGE 30

@implementation DubsarModelsSearch
@synthesize results;
@synthesize term;
@synthesize matchCase;
@synthesize currentPage;
@synthesize totalPages;
@synthesize seqNum;
@synthesize isWildCard;
@synthesize title;
@synthesize exact;

+(instancetype)searchWithTerm:(id)theTerm matchCase:(BOOL)mustMatchCase
{
    return [[self alloc]initWithTerm:theTerm matchCase:mustMatchCase seqNum:_seqNum++];
}

+(instancetype)searchWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase page:(int)page
{
    return [[self alloc]initWithTerm:theTerm matchCase:mustMatchCase page:page seqNum:_seqNum++];
}

+(instancetype)searchWithWildcard:(NSString *)globExpression page:(int)page title:(NSString *)theTitle
{
    return [[self alloc]initWithWildcard:globExpression page:page title:theTitle seqNum:_seqNum++];
}

-(instancetype)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase seqNum:(int)theSeqNum
{
#ifdef DEBUG
    NSLog(@"constructing search for \"%@\"", theTerm);
#endif // DEBUG
    
    self = [super init];
    if (self) {   
        matchCase = mustMatchCase;
        term = theTerm;
        isWildCard = false;
        title = [term copy];
        results = nil;
        currentPage = 1;
        totalPages = 0;
        seqNum = theSeqNum;
        exact = false;

        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
    }
    return self;
}

-(instancetype)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase page:(int)page seqNum:(int)theSeqNum
{
#ifdef DEBUG
    NSLog(@"constructing search for \"%@\"", theTerm);
#endif // DEBUG
    
    self = [super init];
    if (self) {   
        matchCase = mustMatchCase;
        term = theTerm;
        isWildCard = false;
        title = [term copy];
        results = nil;
        seqNum = theSeqNum;
        currentPage = page;
        exact = false;
        
        // totalPages is set by the server in the response
        totalPages = 0;

        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        if (page > 1) __url = [__url stringByAppendingFormat:@"&page=%d", page];
        [self set_url:__url];
    }
    return self;
}

-(instancetype)initWithWildcard:(NSString *)globExpression page:(int)page title:(NSString*)theTitle seqNum:(int)theSeqNum
{
#ifdef DEBUG
    NSLog(@"constructing search for \"%@\"", globExpression);
#endif // DEBUG
    
    self = [super init];
    if (self) {   
        matchCase = false;
        term = globExpression;
        isWildCard = true;
        title = theTitle;
        results = nil;
        seqNum = theSeqNum;
        currentPage = page;
        exact = false;
        
        // totalPages is set by the server in the response
        totalPages = 0;

        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        __url = [__url stringByAppendingString:@"&match=glob"];
        if (page > 1) __url = [__url stringByAppendingFormat:@"&page=%d", page];
        [self set_url:__url];
    }
    return self;
}

- (void)loadResults:(DubsarModelsDatabaseWrapper*)database
{    
    self.results = [NSMutableArray array];

    if (isWildCard) {
        [self loadWildcardResults:database];
    }
    else {
        [self loadFulltextResults:database];
    }
}

- (void)loadWildcardResults:(DubsarModelsDatabaseWrapper *)database

{
    NSString* sql = @"SELECT w.id, w.name, w.part_of_speech, w.freq_cnt FROM WORDS w ";
    
    NSString* capital1;
    NSString* capital2;
    NSString* lower1;
    NSString* lower2;
    
    // globbing for iPad alphabet buttons, term is like "[ABab]*" or "[^A-Za-z]*".
    unichar first = [term characterAtIndex:1];
    
    NSString* where;
    switch (first) {
        default:
            // e.g.,
            // WHERE (w.name >= 'A' AND w.name <'C') OR (w.name >= 'a' AND w.name < 'c') AND w.name GLOB '[ABab]*'
            where = @"WHERE (w.name >= :capital1 AND w.name < :capital2) OR "
            @"(w.name >= :lower1 AND w.name < :lower2) AND w.name GLOB :term ";
            
            capital1 = [NSString stringWithCharacters:&first length:1];
            first += 2;
            capital2 = [NSString stringWithCharacters:&first length:1];
            first += 30;
            lower1 = [NSString stringWithCharacters:&first length:1];
            first += 2;
            lower2 = [NSString stringWithCharacters:&first length:1];
            
            break;
        case '^':
            // things that don't begin with a letter
            where = @"WHERE (w.name < 'A' OR (w.name >= '[' AND w.name < 'a') OR w.name >= '{') AND w.name GLOB '[^A-Za-z]*' ";
            break;
    }
    
    
    NSString* countSql = @"SELECT COUNT(*) FROM words w ";
    countSql = [countSql stringByAppendingString:where];
    
    /* execute countSql to get number of rows */
    sqlite3_stmt* countStmt;
    int rc;
    if ((rc=sqlite3_prepare_v2(database.dbptr, countSql.UTF8String, -1, &countStmt, NULL))
        != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing count statement, error %d", rc];
        return;
    }
    
    if (sqlite3_bind_parameter_count(countStmt) != 0) {
        int c1Idx = sqlite3_bind_parameter_index(countStmt, ":capital1");
        int c2Idx = sqlite3_bind_parameter_index(countStmt, ":capital2");
        int l1Idx = sqlite3_bind_parameter_index(countStmt, ":lower1");
        int l2Idx = sqlite3_bind_parameter_index(countStmt, ":lower2");
        int termIdx = sqlite3_bind_parameter_index(countStmt, ":term");
        
        if ((rc=sqlite3_bind_text(countStmt, c1Idx, capital1.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(countStmt);
            return;
        }
        if ((rc=sqlite3_bind_text(countStmt, c2Idx, capital2.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(countStmt);
            return;
        }
        if ((rc=sqlite3_bind_text(countStmt, l1Idx, lower1.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(countStmt);
            return;
        }
        if ((rc=sqlite3_bind_text(countStmt, l2Idx, lower2.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(countStmt);
            return;
        }
        if ((rc=sqlite3_bind_text(countStmt, termIdx, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(countStmt);
            return;
        }
    }

#ifdef DEBUG
    NSLog(@"executing \"%@\"", countSql);
#endif // DEBUG
    if (sqlite3_step(countStmt) == SQLITE_ROW) {
        int totalRows = sqlite3_column_int(countStmt, 0);
#ifdef DEBUG
        NSLog(@"count statement returned %d total matching rows", totalRows);
#endif // DEBUG
        totalPages = totalRows/NUM_PER_PAGE;
        if (totalRows % NUM_PER_PAGE != 0) {
            ++ totalPages;
        }
    }
    sqlite3_finalize(countStmt);
    
    sql = [sql stringByAppendingString:where];
    
    sql = [sql stringByAppendingString:@"ORDER BY w.name ASC, w.part_of_speech ASC "];
    sql = [sql stringByAppendingFormat:@"LIMIT %d ", NUM_PER_PAGE];
    if (currentPage > 1) {
        sql = [sql stringByAppendingFormat:@"OFFSET %lu ", (unsigned long)(currentPage-1)*NUM_PER_PAGE];
    }

#ifdef DEBUG
    NSLog(@"preparing SQL statement \"%@\"", sql);
#endif // DEBUG
    
    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(database.dbptr,
                               sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
    else {
#ifdef DEBUG
        NSLog(@"prepared statement successfully");
#endif // DEBUG
    }
    
    int termIdx = sqlite3_bind_parameter_index(statement, ":term");
    int c1Idx = sqlite3_bind_parameter_index(statement, ":capital1");
    int c2Idx = sqlite3_bind_parameter_index(statement, ":capital2");
    int l1Idx = sqlite3_bind_parameter_index(statement, ":lower1");
    int l2Idx = sqlite3_bind_parameter_index(statement, ":lower2");
    
    if (termIdx != 0) {
        if ((rc=sqlite3_bind_text(statement, termIdx, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;   
        }
#ifdef DEBUG
        NSLog(@"bound :term to \"%@\"", term);
#endif // DEBUG
    }
    if (c1Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, c1Idx, capital1.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return; 
        }
#ifdef DEBUG
        NSLog(@"bound :capital1 to \"%@\"", capital1);
#endif // DEBUG
    }
    if (c2Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, c2Idx, capital2.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;
        }
#ifdef DEBUG
        NSLog(@"bound :capital2 to \"%@\"", capital2);
#endif // DEBUG
    }
    if (l1Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, l1Idx, lower1.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;
        }
#ifdef DEBUG
        NSLog(@"bound :lower1 to \"%@\"", lower1);
#endif // DEBUG
    }
    if (l2Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, l2Idx, lower2.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;
        }
#ifdef DEBUG
        NSLog(@"bound :lower2 to \"%@\"", lower2);
#endif // DEBUG
    }
    
    while (sqlite3_step(statement) == SQLITE_ROW && results.count < NUM_PER_PAGE) {
#ifdef DEBUG
        NSLog(@"found matching row");
#endif // DEBUG
        int _id = sqlite3_column_int(statement, 0);
        char const* _name = (char const*)sqlite3_column_text(statement, 1);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
        int freqCnt = sqlite3_column_int(statement, 3);

#ifdef DEBUG
        NSLog(@"ID=%d, NAME=%s, PART_OF_SPEECH=%s, FREQ_CNT=%d",
              _id, _name, _part_of_speech, freqCnt);
#endif // DEBUG
        
        DubsarModelsPartOfSpeech partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];   
        NSString* name = @(_name);
        
        DubsarModelsWord* word = [DubsarModelsWord wordWithId:_id name:name partOfSpeech:partOfSpeech];
        word.freqCnt = freqCnt;
        [results addObject:word];
        
        /* now get the inflections */
        /* 
         * We have this 1+N problem because of pagination. If we join inflections in wildcard searches,
         * we get one row per inflection, and that doesn't work with pagination. So here we are.
         */
        NSString* isql = [NSString stringWithFormat:@"SELECT DISTINCT name FROM inflections WHERE word_id = %d", _id];
        sqlite3_stmt* istmt;
        if ((rc=sqlite3_prepare_v2(database.dbptr, isql.UTF8String, -1, &istmt, NULL)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
            NSLog(@"%@", self.errorMessage);
            return;
        }
        
        while (sqlite3_step(istmt) == SQLITE_ROW) {
            char const* _name = (char const*)sqlite3_column_text(istmt, 0);
            NSString* name = @(_name);
            [word addInflection:name];
        }
        
        sqlite3_finalize(istmt);
    }
    
    sqlite3_finalize(statement);

#ifdef DEBUG
    NSLog(@"completed database search (delegate is %@)", (self.delegate == nil ? @"nil" : @"not nil"));
#endif // DEBUG
}

- (void)loadFulltextResults:(DubsarModelsDatabaseWrapper*)database
{
    NSString* sql;
    int rc;
    sqlite3_stmt* statement;
    
    NSString* countSql = @"SELECT COUNT(*) FROM words WHERE id IN (SELECT word_id FROM inflections_fts WHERE name MATCH :term )";
#ifdef DEBUG
    NSLog(@"preparing statement %@", countSql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(database.dbptr, countSql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
    
    int termIdx = sqlite3_bind_parameter_index(statement, ":term");
    if ((rc=sqlite3_bind_text(statement, termIdx, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
        sqlite3_finalize(statement);
        return;            
    }
    
    if (sqlite3_step(statement) == SQLITE_ROW) {
        int totalRows = sqlite3_column_int(statement, 0);
#ifdef DEBUG
        NSLog(@"count statement returned %d total matching rows", totalRows);
#endif // DEBUG
        totalPages = totalRows/NUM_PER_PAGE;
        if (totalRows % NUM_PER_PAGE != 0) {
            ++ totalPages;
        }           
    }
    sqlite3_finalize(statement);
    
    // number of exact matches
    int numExact = 0;
    sql = @"SELECT COUNT(*) FROM words w INNER JOIN inflections i ON i.word_id = w.id WHERE i.name = ?";
#ifdef DEBUG
    NSLog(@"preparing statement %@", sql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;        
    }
    if ((rc=sqlite3_bind_text(statement, 1, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
        sqlite3_finalize(statement);
        return;            
    }
    
    if (sqlite3_step(statement) == SQLITE_ROW) {
        numExact = sqlite3_column_int(statement, 0);
#ifdef DEBUG
        NSLog(@"%d exact matches", numExact);
#endif // DEBUG
    }
    sqlite3_finalize(statement);

    sql =  @"SELECT DISTINCT w.id, w.name, w.part_of_speech, w.freq_cnt "
    @"FROM words w "
    @"INNER JOIN inflections_fts ifts ON ifts.word_id = w.id "
    @"WHERE ifts.name MATCH :term AND ifts.name != :term "
    @"ORDER BY w.name ASC, w.part_of_speech ASC ";
    
    if (currentPage > 1) {
        sql = [sql stringByAppendingFormat:@"LIMIT %d OFFSET %lu ", NUM_PER_PAGE, (unsigned long)(currentPage-1)*NUM_PER_PAGE-numExact];
    }
    else {
        sql = [sql stringByAppendingFormat:@"LIMIT %d ", NUM_PER_PAGE - numExact];
        
        /*
         * Load the exact matches first
         */
        NSString* exactSql = @"SELECT DISTINCT w.id, w.name, w.part_of_speech, w.freq_cnt "
        @"FROM words w "
        @"INNER JOIN inflections i ON i.word_id = w.id "
        @"WHERE i.name = ? "
        @"ORDER BY w.name ASC, w.freq_cnt DESC, w.part_of_speech ASC";
#ifdef DEBUG
        NSLog(@"preparing statement %@", exactSql);
#endif // DEBUG
        if ((rc=sqlite3_prepare_v2(database.dbptr, exactSql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
            return;          
        }
        if ((rc=sqlite3_bind_text(statement, 1, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;           
        }
        
        while (sqlite3_step(statement) == SQLITE_ROW) {
#ifdef DEBUG
            NSLog(@"found matching row");
#endif // DEBUG
            int _id = sqlite3_column_int(statement, 0);
            char const* _name = (char const*)sqlite3_column_text(statement, 1);
            char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
            int freqCnt = sqlite3_column_int(statement, 3);

#ifdef DEBUG
            NSLog(@"ID=%d, NAME=%s, PART_OF_SPEECH=%s, FREQ_CNT=%d",
                  _id, _name, _part_of_speech, freqCnt);
#endif // DEBUG
            
            DubsarModelsPartOfSpeech partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];   
            NSString* name = @(_name);
            
            DubsarModelsWord* word = [DubsarModelsWord wordWithId:_id name:name partOfSpeech:partOfSpeech];
            word.freqCnt = freqCnt;
            [results addObject:word];

            exact = true;
        }
        
        sqlite3_finalize(statement);
    }

#ifdef DEBUG
    NSLog(@"preparing SQL statement \"%@\"", sql);
#endif // DEBUG
    
    if ((rc=sqlite3_prepare_v2(database.dbptr,
                               sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
#ifdef DEBUG
    else {
        NSLog(@"prepared statement successfully");
    }
#endif // DEBUG
    
    termIdx = sqlite3_bind_parameter_index(statement, ":term");    
    if (termIdx != 0) {
        if ((rc=sqlite3_bind_text(statement, termIdx, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;   
        }
#ifdef DEBUG
        NSLog(@"bound :term to \"%@\"", term);
#endif // DEBUG
    }
    
    while (sqlite3_step(statement) == SQLITE_ROW && results.count < NUM_PER_PAGE) {
#ifdef DEBUG
        NSLog(@"found matching row");
#endif // DEBUG
        int _id = sqlite3_column_int(statement, 0);
        char const* _name = (char const*)sqlite3_column_text(statement, 1);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
        int freqCnt = sqlite3_column_int(statement, 3);

#ifdef DEBUG
        NSLog(@"ID=%d, NAME=%s, PART_OF_SPEECH=%s, FREQ_CNT=%d",
              _id, _name, _part_of_speech, freqCnt);
#endif // DEBUG
        
        DubsarModelsPartOfSpeech partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];   
        NSString* name = @(_name);
        
        DubsarModelsWord* word = [DubsarModelsWord wordWithId:_id name:name partOfSpeech:partOfSpeech];
        word.freqCnt = freqCnt;
        [results addObject:word];
    }
    
    for (int j=0; j<results.count; ++j) {
        DubsarModelsWord* word = results[j];
        
        /* now get the inflections */
        /* 
         * We have this 1+N problem because of pagination. If we join inflections in wildcard searches,
         * we get one row per inflection, and that doesn't work with pagination. So here we are.
         */
        NSString* isql = [NSString stringWithFormat:@"SELECT DISTINCT name FROM inflections WHERE word_id = %lu", (unsigned long)word._id];
        sqlite3_stmt* istmt;
        if ((rc=sqlite3_prepare_v2(database.dbptr, isql.UTF8String, -1, &istmt, NULL)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
            NSLog(@"%@", self.errorMessage);
            return;
        }
        
        while (sqlite3_step(istmt) == SQLITE_ROW) {
            char const* _name = (char const*)sqlite3_column_text(istmt, 0);
            NSString* name = @(_name);
            [word addInflection:name];
        }
        
        sqlite3_finalize(istmt);
    }
    
    sqlite3_finalize(statement);

#ifdef DEBUG
    NSLog(@"completed database search (delegate is %@)", (self.delegate == nil ? @"nil" : @"not nil"));
#endif // DEBUG
}

- (void)parseData
{        
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    NSArray* list = response[1];
    NSNumber* pages = response[2];
    totalPages = pages.intValue;
    
    results = [NSMutableArray arrayWithCapacity:list.count];
#ifdef DEBUG
    NSLog(@"search request for \"%@\" returned %lu results", response[0], (unsigned long)list.count);
    NSLog(@"(%lu total pages)", (unsigned long)totalPages);
#endif
    int j;
    for (j=0; j<list.count; ++j) {
        NSArray* entry = list[j];
        
        NSNumber* numericId = entry[0];
        NSString* name = entry[1];
        NSString* posString = entry[2];
        NSNumber* numericFc = entry[3];
        
        DubsarModelsWord* word = [DubsarModelsWord wordWithId:numericId.intValue name:name posString:posString];
        word.freqCnt = numericFc.intValue;
        
        NSString* otherForms = [entry objectAtIndex:4];
        word.inflections = [otherForms componentsSeparatedByString:@","].mutableCopy;
        
        [results insertObject:word atIndex:j];
    }
    
    /* This looks odd when browsing long lists. */
    /* [results sortUsingSelector:@selector(compareFreqCnt:)]; */
}

- (DubsarModelsSearch*)newSearchForPage:(int)page
{
    DubsarModelsSearch* search;
    
    if (isWildCard) {
        search = [DubsarModelsSearch searchWithWildcard:term page:page title:title];
    }
    else {
        search = [DubsarModelsSearch searchWithTerm:term matchCase:matchCase page:page];
    }
    
    return search;
}

@end
