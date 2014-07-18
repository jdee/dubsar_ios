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
#import <sqlite3.h>

#import "DubsarModelsDatabase.h"
#import "DubsarModelsDatabaseWrapper.h"
#import "DubsarModelsPartOfSpeechDictionary.h"
#import "DubsarModelsPointer.h"
#import "DubsarModelsPointerDictionary.h"
#import "DubsarModelsSection.h"
#import "DubsarModelsSense.h"
#import "DubsarModelsSynset.h"
#import "DubsarModelsWord.h"

@implementation DubsarModelsSynset {
    sqlite3_stmt* pointerQuery;
    sqlite3_stmt* semanticQuery;
}

@synthesize _id;
@synthesize gloss;
@synthesize partOfSpeech;
@synthesize lexname;
@synthesize freqCnt;
@synthesize samples;
@synthesize senses;
@synthesize pointers;
@synthesize sections;

+ (instancetype)synsetWithId:(int)theId partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    return [[self alloc]initWithId:theId partOfSpeech:thePartOfSpeech];
}

+ (instancetype)synsetWithId:(int)theId gloss:(NSString *)theGloss partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    return [[self alloc]initWithId:theId gloss:theGloss partOfSpeech:thePartOfSpeech];
}

- (instancetype)initWithId:(int)theId partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = nil;
        partOfSpeech = thePartOfSpeech;
        lexname = nil;
        samples = nil;
        senses = nil;
        _includeExtraSections = NO;
        // [self set_url: [NSString stringWithFormat:@"/synsets/%d", _id]];
        [self prepareStatements];
    }
    return self;

}

- (instancetype)initWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = [theGloss copy];
        partOfSpeech = thePartOfSpeech;
        lexname = nil;
        samples = nil;
        senses = nil;
        _includeExtraSections = NO;
        // [self set_url: [NSString stringWithFormat:@"/synsets/%d", _id]];
        [self prepareStatements];
    }
    return self;
}

- (void)dealloc
{
    [self destroyStatements];
}

- (void)parseData
{
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFromPOS:response[1]];
    lexname = response[2];
#ifdef DEBUG
    NSLog(@"lexname: \"%@\"", lexname);
#endif // DEBUG
    if (!gloss) {
        gloss = response[3];
    }
    samples = response[4];
    NSNumber* _freqCnt;
    NSArray* _senses = response[5];
#ifdef DEBUG
    NSLog(@"found %lu senses", (unsigned long)_senses.count);
#endif // DEBUG
    senses = [NSMutableArray arrayWithCapacity:_senses.count];
    for (int j=0; j<_senses.count; ++j) {
        NSArray* _sense = _senses[j];
        NSNumber* _senseId = _sense[0];
        DubsarModelsSense* sense = [DubsarModelsSense senseWithId:_senseId.intValue name:_sense[1] synset:self];
        id marker = _sense[2];
        _freqCnt = _sense[3];
        sense.lexname = lexname;
        sense.freqCnt = _freqCnt.intValue;
        if (marker != NSNull.null) {
            sense.marker = marker;
        }
        [senses insertObject:sense atIndex:j];
    }
    [senses sortUsingSelector:@selector(compareFreqCnt:)];
    
    _freqCnt = response[6];
    freqCnt = _freqCnt.intValue;
    
    [self parsePointers:response];
}

- (void)parsePointers:(NSArray*)response
{    
    pointers = [NSMutableDictionary dictionary];
    NSArray* _pointers = response[7];
    for (int j=0; j<_pointers.count; ++j) {
        NSArray* _pointer = _pointers[j];
        
        NSString* ptype = _pointer[0];
        NSString* targetType = _pointer[1];
        NSNumber* targetId = _pointer[2];
        NSString* targetText = _pointer[3];
        NSString* targetGloss = _pointer[4];
        
        NSMutableArray* _pointersByType = [pointers valueForKey:ptype];
        if (_pointersByType == nil) {
            _pointersByType = [NSMutableArray array];
            [pointers setValue:_pointersByType forKey:ptype];
        }
        
        NSMutableArray* _ptr = [NSMutableArray array];
        [_ptr addObject:targetType];
        [_ptr addObject:targetId];
        [_ptr addObject:targetText];
        [_ptr addObject:targetGloss];
        
        [_pointersByType addObject:_ptr];
        [pointers setValue:_pointersByType forKey:ptype];
    }
}

-(NSString*)synonymsAsString
{
    NSString* synonymList = [NSString string];
    
    /* 
     * The app still sometimes crashes when this autorelease pool is used.
     */
#ifdef AUTORELEASE_POOL_FOR_SYNONYMS
    @autoreleasepool {
#endif // AUTORELEASE_POOL_FOR_SYNOYMS
    
    for(int j=0; j<senses.count; ++j) {
        DubsarModelsSense* sense = senses[j];
        synonymList = [synonymList stringByAppendingString:sense.name];
        if (j<senses.count-1) {
            synonymList = [synonymList stringByAppendingString:@", "];
        }
    }
    
#ifdef AUTORELEASE_POOL_FOR_SYNONYMS
    }
#endif // AUTORELEASE_POOL_FOR_SYNONYMS    
    return synonymList;
}


- (void)loadResults:(DubsarModelsDatabaseWrapper*)database
{
    NSString* sql = [NSString stringWithFormat:
                     @"SELECT sy.definition, sy.lexname, sy.part_of_speech, se.freq_cnt, se.id, w.name "
                     @"FROM senses se "
                     @"INNER JOIN synsets sy ON sy.id = se.synset_id "
                     @"INNER JOIN words w ON se.word_id = w.id "
                     @"WHERE sy.id = %d ", _id];
    
    int rc;
    sqlite3_stmt* statement;
    
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        return;
    }

#ifdef DEBUG
    NSLog(@"executing %@", sql);
#endif // DEBUG
    freqCnt = 0;
    self.senses = [NSMutableArray array];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _definition = (char const*)sqlite3_column_text(statement, 0);
        char const* _lexname = (char const*)sqlite3_column_text(statement, 1);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
        int senseFreqCnt = sqlite3_column_int(statement, 3);
        freqCnt += senseFreqCnt;
        int senseId = sqlite3_column_int(statement, 4);
        char const* _name = (char const*)sqlite3_column_text(statement, 5);
 
        if (samples == nil) {
            partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
            
            self.lexname = @(_lexname);
            
            NSString* definition = @(_definition);
            NSArray* components = [definition componentsSeparatedByString:@"; \""];
            self.gloss = components[0];
            
            self.samples = [NSMutableArray array];
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
        }
        
        DubsarModelsSense* synonym = [DubsarModelsSense senseWithId:senseId name:@(_name) partOfSpeech:partOfSpeech];
        synonym.freqCnt = senseFreqCnt;
        [synonym load];
        NSLog(@"Loaded synonym %@", synonym.name);
        [senses addObject:synonym];
    }
    sqlite3_finalize(statement);
}

-(NSUInteger)numberOfSections
{
#ifdef DEBUG
    NSLog(@"in numberOfSections");
#endif // DEBUG
    DubsarModelsDatabaseWrapper* database = [DubsarModelsDatabase instance].database;
    
    NSString* sql;
    int rc;
    sqlite3_stmt* statement;
    
    self.sections = [NSMutableArray array];

    if (_includeExtraSections) {
        if (senses.count > 0) {
            DubsarModelsSection* section = [DubsarModelsSection section];
            section.header = @"Synonyms";
            section.footer = [DubsarModelsPointerDictionary helpWithPointerType:@"synonym"];
            section.linkType = @"sense";
            section.ptype = @"synonym";
            section.numRows = senses.count;
            [sections addObject:section];
        }
        if (samples.count > 0) {
            DubsarModelsSection* section = [DubsarModelsSection section];
            section.header = @"Samples";
            section.footer = [DubsarModelsPointerDictionary helpWithPointerType:@"synset sample"];
            section.linkType = @"sample";
            section.ptype = @"sample sentence";
            section.numRows = samples.count;
            [sections addObject:section];
        }
    }
    
    sql = [NSString stringWithFormat:
           @"SELECT DISTINCT ptype FROM pointers WHERE source_id = %d AND source_type = 'Synset' ", _id];
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        NSLog(@"%@", self.errorMessage);
        return 1;
    }

#ifdef DEBUG
    NSLog(@"executing %@", sql);
#endif // DEBUG
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _ptype = (char const*)sqlite3_column_text(statement, 0);
        
        DubsarModelsSection* section = [DubsarModelsSection section];
        section.ptype = @(_ptype);
        section.header = [DubsarModelsPointerDictionary titleWithPointerType:section.ptype];
        section.footer = [DubsarModelsPointerDictionary helpWithPointerType:section.ptype];
        section.ptype = @(_ptype);
        section.senseId = 0;
        section.synsetId = _id;
        section.linkType = @"pointer";
        [sections addObject:section];
    }
    sqlite3_finalize(statement);
#ifdef DEBUG
    NSLog(@"%lu sections in tableView", (unsigned long)sections.count);
#endif // DEBUG
    return sections.count;
}

- (DubsarModelsPointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger pathSection = [indexPath indexAtPosition:0];
    NSUInteger pathRow = [indexPath indexAtPosition:1];

    DubsarModelsSection* section = sections[pathSection];
    DubsarModelsPointer* pointer = [DubsarModelsPointer pointer];
    
    if ([section.ptype isEqualToString:@"synonym"]) {
        DubsarModelsSense* synonym = senses[pathRow];
#ifdef DEBUG
        NSLog(@"requesting synonym %@", synonym.name);
#endif // DEBUG
        pointer.targetText = synonym.name;
        pointer.targetId = synonym._id;
        pointer.targetType = @"sense";
    }
    else if ([section.ptype isEqualToString:@"sample sentence"]) {
        pointer.targetText = samples[pathRow];
    }
    else {
        int rc;
        if ((rc=sqlite3_reset(pointerQuery)) != SQLITE_OK) {
            NSLog(@"error %d preparing statement", rc);
            return pointer;
        }

        int ptypeIdx = sqlite3_bind_parameter_index(pointerQuery, ":ptype");
        int offsetIdx = sqlite3_bind_parameter_index(pointerQuery, ":offset");
        if ((rc=sqlite3_bind_int(pointerQuery, offsetIdx, (int)pathRow)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return nil;
        }
        if ((rc=sqlite3_bind_text(pointerQuery, ptypeIdx, section.ptype.UTF8String, -1, NULL)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return nil;          
        }
        
        if (sqlite3_step(pointerQuery) == SQLITE_ROW) {
            pointer.targetId = sqlite3_column_int(pointerQuery, 1);
            char const* _targetType = (char const*)sqlite3_column_text(pointerQuery, 2);
            pointer.targetType = @(_targetType);
            
            if ((rc=sqlite3_reset(semanticQuery)) != SQLITE_OK) {
                NSLog(@"error %d resetting semantic query", rc);
            }
            if ((rc=sqlite3_bind_int(semanticQuery, 1, (int)pointer.targetId)) != SQLITE_OK) {
                NSLog(@"error %d binding semantic query", rc);
            }
            
            /* semantic pointers */
            NSMutableArray* wordList = [NSMutableArray array];
            DubsarModelsPartOfSpeech ptrPartOfSpeech=DubsarModelsPartOfSpeechUnknown;
            while (sqlite3_step(semanticQuery) == SQLITE_ROW) {
                char const* _name;
                char const* _part_of_speech;
                if (pointer.targetGloss == nil) {
                    _name = (char const*)sqlite3_column_text(semanticQuery, 0);
                    _part_of_speech = (char const*)sqlite3_column_text(semanticQuery, 1);
                    char const* _definition = (char const*)sqlite3_column_text(semanticQuery, 2);
                    NSString* definition = @(_definition);
                    
                    pointer.targetGloss = [definition componentsSeparatedByString:@"; \""][0];
                    ptrPartOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
                }
                
                [wordList addObject:@(_name)];
            }
            
            NSString* words = [NSString string];
            for (int j=0; j<wordList.count-1; ++j) {
                words = [words stringByAppendingFormat:@"%@, ", wordList[j]];
            }
            if (wordList.count > 0) {
                words = [words stringByAppendingString:wordList[wordList.count-1]];
            }
            
            pointer.targetText = [NSString stringWithFormat:@"%@, %@.", words, [DubsarModelsPartOfSpeechDictionary posFromPartOfSpeech:ptrPartOfSpeech]];
        }
        
    }
    
    return pointer;
}

-(void)prepareStatements
{
    DubsarModelsDatabaseWrapper* database = [DubsarModelsDatabase instance].database;
    int rc;
    
    NSString* sql = [NSString stringWithFormat:@"SELECT id, target_id, target_type "
                     @"FROM pointers "
                     @"WHERE source_id = %d AND source_type = 'Synset' AND "
                     @"ptype = :ptype "
                     @"ORDER BY id ASC "
                     @"LIMIT 1 "
                     @"OFFSET :offset ", _id];
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &pointerQuery, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing statement", rc);
        return;
    }        
    
    char const* csql = "SELECT w.name, w.part_of_speech, sy.definition "
    "FROM synsets sy "
    "INNER JOIN senses se ON se.synset_id = sy.id "
    "INNER JOIN words w ON w.id = se.word_id "
    "WHERE sy.id = ? "
    "ORDER BY w.name ASC";

#ifdef DEBUG
    NSLog(@"preparing semantic query %s", csql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(database.dbptr, csql, -1, &semanticQuery, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing semantic query", rc);
        return;
    }
}

-(void)destroyStatements
{
    sqlite3_finalize(semanticQuery);
    sqlite3_finalize(pointerQuery);
}


@end
