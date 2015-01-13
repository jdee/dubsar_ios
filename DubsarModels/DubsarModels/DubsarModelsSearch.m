/*
 Dubsar Dictionary Project
 Copyright (C) 2010-15 Jimmy Dee
 
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

+(instancetype)searchWithTerm:(id)theTerm matchCase:(BOOL)mustMatchCase scope:(DubsarModelsSearchScope)scope
{
    return [[self alloc]initWithTerm:theTerm matchCase:mustMatchCase seqNum:_seqNum++ scope:scope];
}

+(instancetype)searchWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase page:(int)page scope:(DubsarModelsSearchScope)scope
{
    return [[self alloc]initWithTerm:theTerm matchCase:mustMatchCase page:page seqNum:_seqNum++ scope:scope];
}

+(instancetype)searchWithWildcard:(NSString *)globExpression page:(int)page title:(NSString *)theTitle scope:(DubsarModelsSearchScope)scope
{
    return [[self alloc]initWithWildcard:globExpression page:page title:theTitle seqNum:_seqNum++ scope:scope];
}

-(instancetype)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase seqNum:(int)theSeqNum scope:(DubsarModelsSearchScope)scope
{
    DMLOG(@"constructing search for \"%@\"", theTerm);

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
        _scope = scope;

        [self updateUrl];
    }
    return self;
}

-(instancetype)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase page:(int)page seqNum:(int)theSeqNum scope:(DubsarModelsSearchScope)scope
{
    DMLOG(@"constructing search for \"%@\"", theTerm);

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
        _scope = scope;

        // totalPages is set by the server in the response
        totalPages = 0;
        [self updateUrl];
    }
    return self;
}

-(instancetype)initWithWildcard:(NSString *)globExpression page:(int)page title:(NSString*)theTitle seqNum:(int)theSeqNum scope:(DubsarModelsSearchScope)scope
{
    DMLOG(@"constructing search for \"%@\"", globExpression);

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
        _scope = scope;

        // totalPages is set by the server in the response
        totalPages = 0;

        [self updateUrl];
    }
    return self;
}

- (void)updateUrl
{
    NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    __url = [__url stringByAppendingFormat:@"&scope=%s", (_scope == DubsarModelsSearchScopeWords ? "words" : "synsets")];
    if (isWildCard) {
        __url = [__url stringByAppendingString:@"&match=glob"];
    }

    if (matchCase) {
        __url = [__url stringByAppendingString:@"&match=case"];
    }

    if (currentPage > 1) {
        __url = [__url stringByAppendingFormat:@"&page=%d", currentPage];
    }

    [self set_url:__url];
}

- (void)setScope:(DubsarModelsSearchScope)scope
{
    _scope = scope;
    [self updateUrl];
}

- (void)loadResults:(DubsarModelsDatabaseWrapper*)database
{    
    self.results = [NSMutableArray array];

    if (isWildCard) {
        [self loadWildcardResults:database];
    }
    else if (_scope == DubsarModelsSearchScopeWords) {
        [self loadFulltextResults:database];
    }else if (_scope == DubsarModelsSearchScopeSynsets) {
        [self loadSynsetResults:database];
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

    DMTRACE(@"executing \"%@\"", countSql);
    if (sqlite3_step(countStmt) == SQLITE_ROW) {
        int totalRows = sqlite3_column_int(countStmt, 0);
        DMTRACE(@"count statement returned %d total matching rows", totalRows);
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

    DMTRACE(@"preparing SQL statement \"%@\"", sql);

    sqlite3_stmt* statement;
    if ((rc=sqlite3_prepare_v2(database.dbptr,
                               sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
    else {
        DMTRACE(@"prepared statement successfully");
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
        DMTRACE(@"bound :term to \"%@\"", term);
    }
    if (c1Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, c1Idx, capital1.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return; 
        }
        DMTRACE(@"bound :capital1 to \"%@\"", capital1);
    }
    if (c2Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, c2Idx, capital2.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;
        }
        DMTRACE(@"bound :capital2 to \"%@\"", capital2);
    }
    if (l1Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, l1Idx, lower1.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;
        }
        DMTRACE(@"bound :lower1 to \"%@\"", lower1);
    }
    if (l2Idx != 0) {
        if ((rc=sqlite3_bind_text(statement, l2Idx, lower2.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;
        }
        DMTRACE(@"bound :lower2 to \"%@\"", lower2);
    }
    
    while (sqlite3_step(statement) == SQLITE_ROW && results.count < NUM_PER_PAGE) {
        DMTRACE(@"found matching row");
        int _id = sqlite3_column_int(statement, 0);
        char const* _name = (char const*)sqlite3_column_text(statement, 1);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
        int freqCnt = sqlite3_column_int(statement, 3);

        DMLOG(@"ID=%d, NAME=%s, PART_OF_SPEECH=%s, FREQ_CNT=%d",
              _id, _name, _part_of_speech, freqCnt);

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
            DMERROR(@"%@", self.errorMessage);
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

    DMTRACE(@"completed database search (delegate is %@)", (self.delegate == nil ? @"nil" : @"not nil"));
}

- (void)loadFulltextResults:(DubsarModelsDatabaseWrapper*)database
{
    NSString* sql;
    int rc;
    sqlite3_stmt* statement;
    
    NSString* countSql = @"SELECT COUNT(*) FROM words WHERE id IN (SELECT word_id FROM inflections_fts WHERE name MATCH :term )";
    DMTRACE(@"preparing statement %@", countSql);
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
        DMTRACE(@"count statement returned %d total matching rows", totalRows);
        totalPages = totalRows/NUM_PER_PAGE;
        if (totalRows % NUM_PER_PAGE != 0) {
            ++ totalPages;
        }           
    }
    sqlite3_finalize(statement);
    
    // number of exact matches
    int numExact = 0;
    sql = @"SELECT COUNT(*) FROM words w INNER JOIN inflections i ON i.word_id = w.id WHERE i.name = ?";
    DMTRACE(@"preparing statement %@", sql);
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
        DMTRACE(@"%d exact matches", numExact);
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
        DMTRACE(@"preparing statement %@", exactSql);
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
            DMTRACE(@"found matching row");
            int _id = sqlite3_column_int(statement, 0);
            char const* _name = (char const*)sqlite3_column_text(statement, 1);
            char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
            int freqCnt = sqlite3_column_int(statement, 3);

            DMTRACE(@"ID=%d, NAME=%s, PART_OF_SPEECH=%s, FREQ_CNT=%d",
                  _id, _name, _part_of_speech, freqCnt);

            DubsarModelsPartOfSpeech partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];   
            NSString* name = @(_name);
            
            DubsarModelsWord* word = [DubsarModelsWord wordWithId:_id name:name partOfSpeech:partOfSpeech];
            word.freqCnt = freqCnt;
            [results addObject:word];

            exact = true;
        }
        
        sqlite3_finalize(statement);
    }

    DMTRACE(@"preparing SQL statement \"%@\"", sql);

    if ((rc=sqlite3_prepare_v2(database.dbptr,
                               sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error preparing statement, error %d", rc];
        return;
    }
    else {
        DMTRACE(@"prepared statement successfully");
    }

    termIdx = sqlite3_bind_parameter_index(statement, ":term");    
    if (termIdx != 0) {
        if ((rc=sqlite3_bind_text(statement, termIdx, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(statement);
            return;   
        }
        DMTRACE(@"bound :term to \"%@\"", term);
    }
    
    while (sqlite3_step(statement) == SQLITE_ROW && results.count < NUM_PER_PAGE) {
        DMTRACE(@"found matching row");
        int _id = sqlite3_column_int(statement, 0);
        char const* _name = (char const*)sqlite3_column_text(statement, 1);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
        int freqCnt = sqlite3_column_int(statement, 3);

        DMTRACE(@"ID=%d, NAME=%s, PART_OF_SPEECH=%s, FREQ_CNT=%d",
              _id, _name, _part_of_speech, freqCnt);

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
            DMERROR(@"%@", self.errorMessage);
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

    DMTRACE(@"completed database search (delegate is %@)", (self.delegate == nil ? @"nil" : @"not nil"));
}

- (void)loadSynsetResults:(DubsarModelsDatabaseWrapper *)database
{
    const char* sql = "SELECT COUNT(*) FROM synsets_fts WHERE definition MATCH ?";
    sqlite3_stmt* statement;
    int rc = sqlite3_prepare_v2(database.dbptr, sql, -1, &statement, NULL);
    if (rc != SQLITE_OK) {
        DMERROR(@"Error %d preparing \"%s\"", rc, sql);
        return;
    }

    if ((rc=sqlite3_bind_text(statement, 1, term.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
        DMERROR(@"Error %d binding term %@ to \"%s\"", rc, term, sql);
        return;
    }

    if ((rc=sqlite3_step(statement)) != SQLITE_ROW) {
        DMERROR(@"Error %d from sqlite3_step with \"%s\"", rc, sql);
        sqlite3_finalize(statement);
        return;
    }

    int rowCount = sqlite3_column_int(statement, 0);
    sqlite3_finalize(statement);

    totalPages = (rowCount + NUM_PER_PAGE - 1) / NUM_PER_PAGE;
    DMTRACE(@"%d synset rows match \"%@\"; %lu total pages", rowCount, term, (unsigned long)totalPages);

    sql = "SELECT sy.id, sy.definition, sy.lexname, sy.part_of_speech, se.id, w.id, w.name FROM synsets sy "
        "JOIN synsets_fts syfts ON sy.id = syfts.id JOIN senses se ON se.synset_id = sy.id JOIN words w ON w.id = se.word_id "
        "WHERE syfts.definition MATCH ? ORDER BY sy.id ASC, se.synset_index ASC LIMIT ? OFFSET ?";
    rc = sqlite3_prepare_v2(database.dbptr, sql, -1, &statement, NULL);
    if (rc != SQLITE_OK) {
        DMERROR(@"Error %d preparing \"%s\"", rc, sql);
        return;
    }

    rc = sqlite3_bind_text(statement, 1, term.UTF8String, -1, SQLITE_STATIC);
    if (rc != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"Error binding %@ in statement \"%s\": %d", term, sql, rc];
        sqlite3_finalize(statement);
        return;
    }

    if ((rc=sqlite3_bind_int(statement, 2, NUM_PER_PAGE)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"Error binding %@ in statement \"%s\": %d", term, sql, rc];
        sqlite3_finalize(statement);
        return;
    }
    if ((rc=sqlite3_bind_int(statement, 3, NUM_PER_PAGE * (int)(currentPage-1))) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"Error binding %@ in statement \"%s\": %d", term, sql, rc];
        sqlite3_finalize(statement);
        return;
    }

    NSMutableArray* synsets = [NSMutableArray array];
    NSMutableArray* senses;

    DubsarModelsSynset* synset;

    while ((rc=sqlite3_step(statement)) == SQLITE_ROW) {
        int synsetId = sqlite3_column_int(statement, 0);
        const char* _definition = (const char*)sqlite3_column_text(statement, 1);
        const char* lexname = (const char*)sqlite3_column_text(statement, 2);
        const char* part_of_speech = (const char*)sqlite3_column_text(statement, 3);
        int senseId = sqlite3_column_int(statement, 4);
        int wordId = sqlite3_column_int(statement, 5);
        const char* name = (const char*)sqlite3_column_text(statement, 6);

        if (!synset || synset._id != synsetId) {
            synset.senses = senses;

            NSString* definition = @(_definition);
            NSArray* components = [definition componentsSeparatedByString:@"; \""];
            NSString* gloss = components[0];

            NSMutableArray* samples = [NSMutableArray array];
            if (components.count > 1) {
                NSRange range;
                range.location = 1;
                range.length = components.count - 1;
                NSArray* sampleArray = [components subarrayWithRange:range];

                for (int j=0; j<sampleArray.count; ++j) {
                    NSString* sample = sampleArray[j];
                    sample = [sample stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
                    if (sample.length > 0 && [sample characterAtIndex:sample.length-1] == '"') {
                        sample = [sample substringToIndex:sample.length-1];
                    }
                    [samples addObject:sample];
                }
            }

            synset = [DubsarModelsSynset synsetWithId:synsetId gloss:gloss partOfSpeech:[DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:part_of_speech]];
            synset.lexname = @(lexname);
            
            synset.samples = samples;

            [synsets addObject:synset];

            senses = [NSMutableArray array];
        }
        assert(synset);

        DubsarModelsSense* sense = [DubsarModelsSense senseWithId:senseId name:@(name) partOfSpeech:synset.partOfSpeech];

        DubsarModelsWord* word = [DubsarModelsWord wordWithId:wordId name:@(name) partOfSpeech:synset.partOfSpeech];

        sense.word = word;

        [senses addObject:sense];
    }

    if (rc != SQLITE_DONE) {
        DMERROR(@"%d returned from sqlite3_step() with %s", rc, sql);
    }

    synset.senses = senses;

    results = synsets;

    sqlite3_finalize(statement);
}

- (void)parseData
{        
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    NSArray* list = response[1];
    NSNumber* pages = response[2];
    totalPages = pages.intValue;
    
    results = [NSMutableArray arrayWithCapacity:list.count];
    DMTRACE(@"search request for \"%@\" returned %lu results", response[0], (unsigned long)list.count);
    DMTRACE(@"(%lu total pages)", (unsigned long)totalPages);
    int j;
    for (j=0; j<list.count; ++j) {
        NSArray* entry = list[j];

        if (_scope == DubsarModelsSearchScopeWords || self.isWildCard) {
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
        else {
            NSNumber* numericId = entry[0];
            NSString* definition = entry[1];
            NSString* lexname = entry[2];
            NSString* part_of_speech = entry[3];

            NSArray* components = [definition componentsSeparatedByString:@"; \""];
            NSRange theRest;
            theRest.location = 1;
            theRest.length = components.count - 1;

            DubsarModelsSynset* synset = [DubsarModelsSynset synsetWithId:numericId.integerValue gloss:components[0] partOfSpeech:[DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:part_of_speech.UTF8String]];
            synset.lexname = lexname;
            synset.samples = [components subarrayWithRange:theRest].mutableCopy;

            NSMutableArray* senses = [NSMutableArray array];
            for (NSArray* senseEntry in (NSArray*)entry[4]) {
                NSNumber* numericSenseId = senseEntry[0];
                NSNumber* numericWordId = senseEntry[1];
                NSString* name = senseEntry[2];

                DubsarModelsSense* sense = [DubsarModelsSense senseWithId:numericSenseId.integerValue name:name partOfSpeech:synset.partOfSpeech];
                sense.word = [DubsarModelsWord wordWithId:numericWordId.integerValue name:name partOfSpeech:synset.partOfSpeech];

                [senses addObject:sense];
            }

            synset.senses = senses;
            [results insertObject:synset atIndex:j];
        }
    }
    
    /* This looks odd when browsing long lists. */
    /* [results sortUsingSelector:@selector(compareFreqCnt:)]; */
}

- (DubsarModelsSearch*)newSearchForPage:(int)page
{
    DubsarModelsSearch* search;
    
    if (isWildCard) {
        search = [DubsarModelsSearch searchWithWildcard:term page:page title:title scope:_scope];
    }
    else {
        search = [DubsarModelsSearch searchWithTerm:term matchCase:matchCase page:page scope:_scope];
    }
    
    return search;
}

@end
