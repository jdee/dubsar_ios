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
#import "DubsarModelsDatabaseWrapper.h"
#import "DubsarModelsPartOfSpeechDictionary.h"
#import "DubsarModelsSense.h"
#import "DubsarModelsSynset.h"
#import "DubsarModelsWord.h"

@implementation DubsarModelsWord
@synthesize _id;
@synthesize name;
@synthesize partOfSpeech;
@synthesize freqCnt;

@synthesize inflections;
@synthesize senses;

+(instancetype)wordWithId:(NSUInteger)theId name:(id)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    return [[self alloc] initWithId:theId name:theName partOfSpeech:thePartOfSpeech];
}

+(instancetype)wordWithId:(NSUInteger)theId name:(NSString *)theName posString:(NSString *)posString
{
    return [[self alloc] initWithId:theId name:theName posString:posString];
}

-(instancetype)initWithId:(NSUInteger)theId name:(NSString *)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        name = theName;
        partOfSpeech = thePartOfSpeech;
        inflections = nil;
        [self initUrl];
    }
    return self;
}

-(instancetype)initWithId:(NSUInteger)theId name:(NSString *)theName posString:(NSString *)posString
{
    self = [super init];
    if (self) {
        _id = theId;
        name = theName;
        
        partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFromPOS:posString];
        [self initUrl];
    }
    return self;
}

-(NSString*)pos
{
    return [DubsarModelsPartOfSpeechDictionary posFromPartOfSpeech:partOfSpeech];
}

-(NSString *)nameAndPos
{
    return [NSString stringWithFormat:@"%@, %@.", name, self.pos];
}

- (NSString *)otherForms
{
    NSString* result = @"";
    for (int j=0; j<inflections.count; ++j) {
        NSString* inflection = inflections[j];
        if (j < inflections.count-1) {
            result = [result stringByAppendingFormat:@"%@, ", inflection];
        }
        else {
            result = [result stringByAppendingString:inflection];
        }
    }
    return result;
}

-(void)loadResults:(DubsarModelsDatabaseWrapper *)database
{
    NSString* sql = [NSString stringWithFormat:
                     @"SELECT DISTINCT w.name, w.part_of_speech, w.freq_cnt, i.name "
                     @"FROM words w "
                     @"INNER JOIN inflections i ON w.id = i.word_id "
                     @"WHERE w.id = %lu "
                     @"ORDER BY i.name ASC ", (unsigned long)_id];
    int rc;
    sqlite3_stmt* statement;
#ifdef DEBUG
    DMLOG(@"preparing statement \"%@\"", sql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        DMLOG(@"%@", self.errorMessage);
        return;
    }
    
    self.inflections = nil;
    while ((rc=sqlite3_step(statement)) == SQLITE_ROW) {
        char const* _name = (char const*)sqlite3_column_text(statement, 0);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 1);
        freqCnt = sqlite3_column_int(statement, 2);
        char const* _inflection = (char const*)sqlite3_column_text(statement, 3);
        
        self.name = @(_name);
        
        NSString* inflection = @(_inflection);
        [self addInflection:inflection];
#ifdef DEBUG
        DMLOG(@"added inflection %@", inflection);
#endif // DEBUG
        
        if (partOfSpeech == DubsarModelsPartOfSpeechUnknown) {
            partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
        }
    }

#ifdef DEBUG
    DMLOG(@"%lu inflections", (unsigned long)inflections.count);
#endif // DEBUG
    
    sqlite3_finalize(statement);

    sql = [NSString stringWithFormat:@"SELECT se.id, sy.definition, sy.lexname, se.freq_cnt, se.marker, sy.id "
           @"FROM senses se "
           @"INNER JOIN synsets sy ON se.synset_id = sy.id "
           @"WHERE se.word_id = %lu "
           @"ORDER BY se.freq_cnt DESC ", (unsigned long)_id];

#ifdef DEBUG
    DMLOG(@"preparing statement \"%@\"", sql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        DMLOG(@"%@", self.errorMessage);
        return;
    }
    
    self.senses = [NSMutableArray array];
    
    while (sqlite3_step(statement) == SQLITE_ROW) {
        int senseId = sqlite3_column_int(statement, 0);
        char const* _definition = (char const*)sqlite3_column_text(statement, 1);
        char const* _lexname = (char const*)sqlite3_column_text(statement, 2);
        int senseFC = sqlite3_column_int(statement, 3);
        char const* _marker = (char const*)sqlite3_column_text(statement, 4);
        int synsetId = sqlite3_column_int(statement, 5);
        
        NSMutableArray* synonyms = [NSMutableArray array];
        
        NSString* synSql = [NSString stringWithFormat:@"SELECT s.id, w.name "
                            @"FROM senses s "
                            @"INNER JOIN words w ON w.id = s.word_id "
                            @"WHERE s.synset_id = %d AND w.name != ? "
                            @"ORDER BY w.name ASC ", synsetId];
        
        sqlite3_stmt* synStatement;
#ifdef DEBUG
        DMLOG(@"preparing statement \"%@\"", synSql);
#endif // DEBUG
        if ((rc=sqlite3_prepare_v2(database.dbptr, synSql.UTF8String, -1, &synStatement, NULL))
            != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
            sqlite3_finalize(statement);
            return;
        }
        
        if ((rc=sqlite3_bind_text(synStatement, 1, name.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            sqlite3_finalize(synStatement);
            sqlite3_finalize(statement);
            return;
        }
        
        while (sqlite3_step(synStatement) == SQLITE_ROW) {
            int synonymSenseId = sqlite3_column_int(synStatement, 0);
            char const* _synonym = (char const*)sqlite3_column_text(synStatement, 1);
#ifdef DEBUG
            DMLOG(@"synonym %s (%d)", _synonym, synonymSenseId);
#endif // DEBUG
    
            DubsarModelsSense* synonym = [DubsarModelsSense senseWithId:synonymSenseId name:@(_synonym) partOfSpeech:partOfSpeech];
            [synonyms addObject:synonym];
        }
        
        NSString* definition = @(_definition);
        NSString* gloss = [definition componentsSeparatedByString:@"; \""][0];
        
        DubsarModelsSense* sense = [DubsarModelsSense senseWithId:senseId gloss:gloss synonyms:synonyms word:self];
        sense.lexname = @(_lexname);
        sense.freqCnt = senseFC;
        sense.marker = _marker == NULL ? @"" : @(_marker);
        sense.synset = [DubsarModelsSynset synsetWithId:synsetId gloss:gloss partOfSpeech:partOfSpeech];
        [senses addObject:sense];
#ifdef DEBUG
        DMLOG(@"added sense ID %d, gloss \"%@\", lexname \"%@\", freq. cnt. %d, synset with ID %ld", senseId, gloss, sense.lexname, senseFC, (long)sense.synset._id);
#endif // DEBUG
    }
    
    sqlite3_finalize(statement);
#ifdef DEBUG
    DMLOG(@"%@", @"completed word query");
#endif // DEBUG
}

-(void)parseData
{
    NSArray* response =[NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    
    inflections = [[response[3] componentsSeparatedByString:@", "] mutableCopy];

    NSNumber* _freqCnt;
    NSArray* _senses = response[4];
    senses = [NSMutableArray arrayWithCapacity:_senses.count];
    for (int j=0; j<_senses.count; ++j) {
        NSArray* _sense = _senses[j];
        NSArray* _synonyms = _sense[1];
        NSNumber* numericId = nil;
        NSMutableArray* synonyms = [NSMutableArray arrayWithCapacity:_synonyms.count];
        for (int k=0; k<_synonyms.count; ++k) {
            NSArray* _synonym = _synonyms[k];
            numericId = _synonym[0];
            DubsarModelsSense* sense = [DubsarModelsSense senseWithId:numericId.intValue name:_synonym[1] partOfSpeech:partOfSpeech];
            [synonyms insertObject:sense atIndex:k];
        }
        
        numericId = _sense[0];
        DubsarModelsSense* sense = [DubsarModelsSense senseWithId:numericId.intValue gloss:_sense[2] synonyms:synonyms word:self];
        NSString* lexname = _sense[3];
        id marker = _sense[4];
        _freqCnt = _sense[5];
        sense.lexname = lexname;
        if (marker != NSNull.null) {
            sense.marker = marker;
        }
        sense.freqCnt = _freqCnt.intValue;
        
        [senses insertObject:sense atIndex:j];
    }
    [senses sortUsingSelector:@selector(compareFreqCnt:)];
    _freqCnt = response[5];
    freqCnt = _freqCnt.intValue;
}

-(void)initUrl
{
    [self set_url: [NSString stringWithFormat:@"/words/%ld", (long)_id]];
}

- (NSComparisonResult)compareFreqCnt:(DubsarModelsWord*)word
{
    return freqCnt < word.freqCnt ? NSOrderedDescending : 
        freqCnt > word.freqCnt ? NSOrderedAscending : 
        NSOrderedSame;
}

- (void)addInflection:(NSString*)inflection
{
    if (!inflections) self.inflections = [NSMutableArray array];

    if ([inflection compare:name options:NSCaseInsensitiveSearch] == NSOrderedSame) return;

    [inflections addObject:inflection];
}

@end
