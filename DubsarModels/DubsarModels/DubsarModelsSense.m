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

#import "DubsarModels.h"
#import "DubsarModelsDatabase.h"
#import "DubsarModelsDatabaseWrapper.h"
#import "DubsarModelsPartOfSpeechDictionary.h"
#import "DubsarModelsPointer.h"
#import "DubsarModelsPointerDictionary.h"
#import "DubsarModelsSection.h"
#import "DubsarModelsSense.h"
#import "DubsarModelsSynset.h"
#import "DubsarModelsWord.h"

@implementation DubsarModelsSense {
    sqlite3_stmt* pointerQuery;
    sqlite3_stmt* lexicalQuery;
    sqlite3_stmt* semanticQuery;
}

@synthesize _id;
@synthesize name;
@synthesize partOfSpeech;
@synthesize gloss;
@synthesize synonyms;
@synthesize synset;
@synthesize word;
@synthesize lexname;
@synthesize marker;
@synthesize freqCnt;
@synthesize verbFrames;
@synthesize samples;
@synthesize pointers;
@synthesize sections;

+(instancetype)senseWithId:(NSUInteger)theId name:(NSString *)theName synset:(DubsarModelsSynset *)theSynset
{
    return [[self alloc]initWithId:theId name:theName synset:theSynset];
}

+(instancetype)senseWithId:(NSUInteger)theId name:(NSString *)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    return [[self alloc]initWithId:theId name:theName partOfSpeech:thePartOfSpeech];
}

+(instancetype)senseWithId:(NSUInteger)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(DubsarModelsWord *)theWord
{
    return [[self alloc]initWithId:theId gloss:theGloss synonyms:theSynonyms word:theWord];
}

+(instancetype)senseWithId:(NSUInteger)theId nameAndPos:(NSString*)nameAndPos
{
    return [[self alloc]initWithId:theId nameAndPos:nameAndPos];
}

- (instancetype)init
{
    self = [super init];
    return self;
}

-(instancetype)initWithId:(NSUInteger)theId name:(NSString *)theName synset:(DubsarModelsSynset *)theSynset
{
    self = [super init];
    if (self) {
        _id = theId;
        name = theName;
        word = nil;
        gloss = nil;
        synonyms = nil;
        synset = theSynset;
        partOfSpeech = synset.partOfSpeech;
        marker = @"";
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = true;
        weakWordLink = false;
        _includeExtraSections = NO;
        sections = [NSMutableArray array];
        [self initUrl];
    }
    return self;
}

-(instancetype)initWithId:(NSUInteger)theId name:(NSString *)theName partOfSpeech:(DubsarModelsPartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        name = theName;
        word = nil;
        gloss = nil;
        synonyms = nil;
        synset = nil;
        partOfSpeech = thePartOfSpeech;
        marker = @"";
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakWordLink = weakSynsetLink = false;
        _includeExtraSections = NO;
        sections = [NSMutableArray array];
        [self initUrl];
    }
    return self;
   
}

-(instancetype)initWithId:(NSUInteger)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(DubsarModelsWord *)theWord
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = theGloss;
        synonyms = [theSynonyms copy];
        word = theWord;
        partOfSpeech = word.partOfSpeech;
        name = word.name;
        synset = nil;
        marker = @"";
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = false;
        weakWordLink = true;
        _includeExtraSections = NO;
        sections = [NSMutableArray array];
        [self initUrl];
    }
    return self;
}

-(instancetype)initWithId:(NSUInteger)theId nameAndPos:(NSString*)nameAndPos
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = nil;
        synonyms = nil;
        word = nil;
        synset = nil;
        marker = @"";
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = false;
        weakWordLink = false;
        _includeExtraSections = NO;
        [self initUrl];
        sections = [NSMutableArray array];
        [self parseNameAndPos:nameAndPos];
    }
    return self;
}

-(void)dealloc
{
    [self destroyStatements];
}

-(NSString*)synonymsAsString
{
    
    NSString* synonymList = [NSString string];
    
    for(int j=0; j<synonyms.count; ++j) {
        DubsarModelsSense* synonym = synonyms[j];
        synonymList = [synonymList stringByAppendingString:synonym.name];
        if (j<synonyms.count-1) {
            synonymList = [synonymList stringByAppendingString:@", "];
        }
    }
    
    return synonymList;
}

-(NSString*)pos
{
    switch (partOfSpeech) {
        case DubsarModelsPartOfSpeechAdjective:
            return @"adj";
        case DubsarModelsPartOfSpeechAdverb:
            return @"adv";
        case DubsarModelsPartOfSpeechConjunction:
            return @"conj";
        case DubsarModelsPartOfSpeechInterjection:
            return @"interj";
        case DubsarModelsPartOfSpeechNoun:
            return @"n";
        case DubsarModelsPartOfSpeechPreposition:
            return @"prep";
        case DubsarModelsPartOfSpeechPronoun:
            return @"pron";
        case DubsarModelsPartOfSpeechVerb:
            return @"v";
        default:
            return @"..";
    }
}

-(NSString *)nameAndPos
{
    return [NSString stringWithFormat:@"%@, %@.", name, self.pos];
}

-(void)parseNameAndPos:(NSString *)nameAndPos
{
    NSRange posStartRange = [nameAndPos rangeOfString:@", "];
    if (posStartRange.location == NSNotFound) {
        DMWARN(@"did not find \", ");
        return;
    }

    NSRange nameRange = NSMakeRange(0, posStartRange.location);
    NSRange posRange = NSMakeRange(posStartRange.location+2, nameAndPos.length-posStartRange.location-3);
    
    name = [nameAndPos substringWithRange:nameRange];
    partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFromPOS:[nameAndPos substringWithRange:posRange]];
}

-(void)parseData
{
    DMTRACE(@"parsing Sense response for %@, %lu bytes", self.nameAndPos, (unsigned long)[self data].length);

    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    DMTRACE(@"sense response array has %lu entries", (unsigned long)response.count);

    NSArray* _word = response[1];
    NSNumber* _wordId = _word[0];
    NSArray* _synset = response[2];
    NSNumber* _synsetId = _synset[0];
    
    partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFromPOS:_word[2]];
    
    if (!word) {
        word = [DubsarModelsWord wordWithId:_wordId.intValue name:_word[1] partOfSpeech:partOfSpeech];
        weakWordLink = false;
    }

    if (!gloss) {
        gloss = _synset[1];
    }
   
    if (!synset) {
        synset = [DubsarModelsSynset synsetWithId:_synsetId.intValue gloss:_synset[1] partOfSpeech:partOfSpeech];
        weakSynsetLink = false;
    }
    
    lexname = response[3];
    DMTRACE(@"lexname: \"%@\"", lexname);

    synset.lexname = lexname;

    NSObject* _marker = response[4];
    if (_marker != NSNull.null) {
        marker = (NSString*)_marker;
    }

    NSNumber* fc = response[5];
    freqCnt = fc.intValue;

    DMTRACE(@"freq. cnt.: %d", freqCnt);

    NSArray* _synonyms = response[6];
    DMTRACE(@"found %lu synonyms", (unsigned long)[_synonyms count]);
    synonyms = [NSMutableArray arrayWithCapacity:_synonyms.count];
    for (int j=0; j< _synonyms.count; ++j) {
        NSArray* _synonym = _synonyms[j];
        NSNumber* _senseId = _synonym[0];
        DubsarModelsSense* sense = [DubsarModelsSense senseWithId:_senseId.intValue name:_synonym[1] synset:synset];
        _marker = _synonym[2];
        if (_marker != NSNull.null) {
            sense.marker = _synonym[2];
        }
        fc = _synonym[3];
        sense.freqCnt = fc.intValue;

        int wordId = ((NSNumber*)_synonym[4]).intValue;
        sense.word = [DubsarModelsWord wordWithId:wordId name:_synonym[1] partOfSpeech:partOfSpeech];
        DMTRACE(@" found %@, ID %lu, freq. cnt. %d", sense.nameAndPos, (unsigned long)sense._id, sense.freqCnt);
        [synonyms insertObject:sense atIndex:j];
    }
    [synonyms sortUsingSelector:@selector(compareFreqCnt:)];
    
    NSArray* _verbFrames = response[7];
    DMTRACE(@"found %lu verb frames", (unsigned long)_verbFrames.count);
    verbFrames = [NSMutableArray arrayWithCapacity:_verbFrames.count];
    for (int j=0; j<_verbFrames.count; ++j) {
        NSString* frame = _verbFrames[j];
        NSString* format = [frame stringByReplacingOccurrencesOfString:@"%s" withString:@"%@"];
        DMTRACE(@" %@", format);
        [verbFrames insertObject:[NSString stringWithFormat:format, name] atIndex:j];
    }
    samples = response[8];

    DMTRACE(@"found %lu verb frames and %lu sample sentences", (unsigned long)[verbFrames count], (unsigned long)[samples count]);

    [self parsePointers:response];
}

- (void)parsePointers:(NSArray*)response
{    
    pointers = [NSMutableDictionary dictionary];
    [sections removeAllObjects];

    NSArray* _pointers = response[9];
    DMTRACE(@"%lu pointers", (unsigned long)_pointers.count);
    for (int j=0; j<_pointers.count; ++j) {
        NSArray* _pointer = _pointers[j];
        
        NSString* ptype = _pointer[0];
        NSString* targetType = _pointer[1];
        NSNumber* targetId = _pointer[2];
        NSString* targetText = _pointer[3];
        NSString* targetGloss = _pointer[4];
        NSNumber* targetSynsetId;

        if (_pointer.count > 5) targetSynsetId = _pointer[5];
        
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
        if (targetSynsetId) {
            [_ptr addObject:targetSynsetId];
        }
        
        [_pointersByType addObject:_ptr];
        // [pointers setValue:_pointersByType forKey:ptype];

        DubsarModelsSection* section;
        BOOL found = NO;
        for (DubsarModelsSection* s in sections) {
            if (s.ptype == ptype) {
                found = YES;
                section = s;
                break;
            }
        }

        if (!found) {
            section = [DubsarModelsSection section];
            section.ptype = ptype;
            section.header = [DubsarModelsPointerDictionary titleWithPointerType:section.ptype];
            section.footer = [DubsarModelsPointerDictionary helpWithPointerType:section.ptype];
            section.senseId = _id;
            section.synsetId = synset._id;
            section.numRows = 0;
            section.linkType = @"pointer";
            [sections addObject:section];
        }

        ++ section.numRows;

        DMTRACE(@"After %@: %lu rows of type %@", targetText, (unsigned long)section.numRows, ptype);
    }
}

- (void)initUrl
{
    [self set_url: [NSString stringWithFormat:@"/senses/%lu", (unsigned long)_id]];
}

- (NSComparisonResult)compareFreqCnt:(DubsarModelsSense*)sense
{
    return freqCnt < sense.freqCnt ? NSOrderedDescending : 
        freqCnt > sense.freqCnt ? NSOrderedAscending : 
        NSOrderedSame;
}

- (void)loadResults:(DubsarModelsDatabaseWrapper *)database
{
    NSString* sql = [NSString stringWithFormat:
                     @"SELECT sy.id, sy.definition, sy.lexname, se.marker, se.freq_cnt, w.id, w.part_of_speech, vf.frame, vf.number, w.name "
                     @"FROM senses se "
                     @"INNER JOIN synsets sy ON sy.id = se.synset_id "
                     @"INNER JOIN words w ON w.id = se.word_id "
                     @"LEFT JOIN senses_verb_frames svf ON svf.sense_id = se.id "
                     @"LEFT JOIN verb_frames vf ON vf.id = svf.verb_frame_id "
                     @"WHERE se.id = %lu "
                     @"ORDER BY vf.number ASC ", (unsigned long)_id];
    
    int rc;
    sqlite3_stmt* statement;
    
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        return;
    }

    DMTRACE(@"executing %@", sql);
    self.verbFrames = [NSMutableArray array];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        int synsetId = sqlite3_column_int(statement, 0);
        char const* _definition = (char const*)sqlite3_column_text(statement, 1);
        char const* _lexname = (char const*)sqlite3_column_text(statement, 2);
        char const* _marker = (char const*)sqlite3_column_text(statement, 3);
        freqCnt = sqlite3_column_int(statement, 4);
        int wordId = sqlite3_column_int(statement, 5);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 6);
        char const* _frame = (char const*)sqlite3_column_text(statement, 7);
        char const* _name = (char const*)sqlite3_column_text(statement, 9);
        self.name = @(_name);

        DMTRACE(@"matching row: synsetId = %d, wordId = %d", synsetId, wordId);

        if (samples == nil) {
            partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
            word = [DubsarModelsWord wordWithId:wordId name:name partOfSpeech:partOfSpeech];
            synset = [DubsarModelsSynset synsetWithId:synsetId partOfSpeech:partOfSpeech];
            weakSynsetLink = weakWordLink = false;
            DMTRACE(@"created synset with id %lu", (unsigned long)synset._id);

            self.lexname = @(_lexname);
            self.marker = _marker == NULL ? @"" : @(_marker);
            
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
        
        if (_frame != NULL) {
            // often contain a %s format
            char const* _name = name.UTF8String;
            NSString* frame = @(_frame);
            [verbFrames addObject:[NSString stringWithFormat:frame, _name]];
        }
    }
    sqlite3_finalize(statement);
    
    if (self.preview) {
        self.synonyms = [NSMutableArray array];
        [self prepareStatements];
        return;
    }
    
    sql = [NSString stringWithFormat:
           @"SELECT se.id, w.name, w.id "
           @"FROM senses se "
           @"INNER JOIN words w ON w.id = se.word_id "
           @"WHERE se.synset_id = %lu AND w.name != ? "
           @"ORDER BY se.synset_index ASC ", (unsigned long)synset._id];
    
    if ((rc=sqlite3_prepare(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        return;
    }
    
    if ((rc=sqlite3_bind_text(statement, 1, name.UTF8String, -1, SQLITE_STATIC)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
        sqlite3_finalize(statement);
        return;       
    }

    DMTRACE(@"executing %@", sql);
    self.synonyms = [NSMutableArray array];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        int senseId = sqlite3_column_int(statement, 0);
        char const* _name = (char const*)sqlite3_column_text(statement, 1);
        int wordId = sqlite3_column_int(statement, 2);
        
        DubsarModelsSense* synonym = [DubsarModelsSense senseWithId:senseId name:@(_name) partOfSpeech:partOfSpeech];
        synonym.word = [DubsarModelsWord wordWithId:wordId name:@(_name) partOfSpeech:partOfSpeech];
        [synonyms addObject:synonym];
    }
    
    sqlite3_finalize(statement);
    
    [self prepareStatements];
}

-(NSUInteger)numberOfSections
{
    if (!self.database.dbptr) {
        return sections.count;
    }

    DMTRACE(@"in numberOfSections");
    DubsarModelsDatabaseWrapper* database = [DubsarModelsDatabase instance].database;

    NSString* sql;
    int rc;
    sqlite3_stmt* statement;
    
    [sections removeAllObjects];

    if (_includeExtraSections) {
        if (synonyms.count > 0) {
            DubsarModelsSection* section = [DubsarModelsSection section];
            section.header = @"Synonyms";
            section.footer = [DubsarModelsPointerDictionary helpWithPointerType:@"synonym"];
            section.linkType = @"sense";
            section.ptype = @"synonym";
            section.numRows = synonyms.count;
            [sections addObject:section];
        }
        if (verbFrames.count > 0) {
            DubsarModelsSection* section = [DubsarModelsSection section];
            section.header = @"Verb Frames";
            section.footer = [DubsarModelsPointerDictionary helpWithPointerType:@"verb frame"];
            section.linkType = @"sample";
            section.ptype = @"verb frame";
            section.numRows = verbFrames.count;
            [sections addObject:section];
        }
        if (samples.count > 0) {
            DubsarModelsSection* section = [DubsarModelsSection section];
            section.header = @"Samples";
            section.footer = [DubsarModelsPointerDictionary helpWithPointerType:@"sample sentence"];
            section.linkType = @"sample";
            section.ptype = @"sample sentence";
            section.numRows = samples.count;
            [sections addObject:section];
        }
    }
    
    sql = [NSString stringWithFormat:
           @"SELECT DISTINCT ptype FROM pointers WHERE (source_id = %lu AND source_type = 'Sense') OR "
           @"(source_id = %lu AND source_type = 'Synset') ", (unsigned long)_id, (unsigned long)synset._id];
    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        DMERROR(@"%@", self.errorMessage);
        return 1;
    }

    DMTRACE(@"executing %@", sql);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _ptype = (char const*)sqlite3_column_text(statement, 0);
        
        DubsarModelsSection* section = [DubsarModelsSection section];
        section.ptype = @(_ptype);
        section.header = [DubsarModelsPointerDictionary titleWithPointerType:section.ptype];
        section.footer = [DubsarModelsPointerDictionary helpWithPointerType:section.ptype];
        section.senseId = _id;
        section.synsetId = synset._id;
        section.linkType = @"pointer";
        [sections addObject:section];
    }
    sqlite3_finalize(statement);
    DMTRACE(@"%lu sections in tableView", (unsigned long)sections.count);
    return sections.count;
}

- (DubsarModelsPointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger pathSection = [indexPath indexAtPosition:0];
    NSUInteger pathRow = [indexPath indexAtPosition:1];

    DubsarModelsSection* section = sections[pathSection];
    // DMLOG(@"Building pointer for section %d, row %d (section %@, ptype %@)", pathSection, pathRow, section.header, section.ptype);
    DubsarModelsPointer* pointer = [DubsarModelsPointer pointer];
        
    if ([section.ptype isEqualToString:@"synonym"]) {
        DubsarModelsSense* synonym = synonyms[pathRow];
        DMTRACE(@"requesting synonym %@", synonym.name);
        pointer.targetText = synonym.name;
        pointer.targetId = synonym._id;
        pointer.targetType = @"sense";
    }
    else if ([section.ptype isEqualToString:@"verb frame"]) {
        pointer.targetText = verbFrames[pathRow];
    }
    else if ([section.ptype isEqualToString:@"sample sentence"]) {
        pointer.targetText = samples[pathRow];
    }
    else if (!self.database.dbptr) {
        NSArray* pointersByType = pointers[section.ptype];
        NSArray* pointerArray = pointersByType[pathRow];
        pointer.targetType = pointerArray[0];
        pointer.targetId = ((NSNumber*)pointerArray[1]).integerValue;
        pointer.targetText = pointerArray[2];
        pointer.targetGloss = pointerArray[3];
        if (pointerArray.count > 4) {
            pointer.targetSynsetId = ((NSNumber*)pointerArray[4]).integerValue;
        }
    }
    else {
        int rc;
        int ptypeIdx = sqlite3_bind_parameter_index(pointerQuery, ":ptype");
        int offsetIdx = sqlite3_bind_parameter_index(pointerQuery, ":offset");
        
        if ((rc=sqlite3_reset(pointerQuery)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error resetting statement, error %d", rc];
            return nil;
        }
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
            // DMLOG(@"Pointer target type is %@", pointer.targetType);
            
            if ([pointer.targetType isEqualToString:@"Sense"]) {
                if ((rc=sqlite3_reset(lexicalQuery)) != SQLITE_OK) {
                    DMERROR(@"error %d resetting lexical query", rc);
                }
                if ((rc=sqlite3_bind_int(lexicalQuery, 1, (int)pointer.targetId)) != SQLITE_OK) {
                    DMERROR(@"error %d binding lexical query", rc);
                }
                
                /* lexical pointers */
                if (sqlite3_step(lexicalQuery) == SQLITE_ROW) {
                    char const* _name = (char const*)sqlite3_column_text(lexicalQuery, 0);
                    char const* _part_of_speech = (char const*)sqlite3_column_text(lexicalQuery, 1);
                    char const* _definition = (char const*)sqlite3_column_text(lexicalQuery, 2);
                    char const* _marker = (char const*)sqlite3_column_text(lexicalQuery, 3);
                    char const* _lexname = (char const*)sqlite3_column_text(lexicalQuery, 4);
                    int _synsetId = sqlite3_column_int(lexicalQuery, 5);
                    if (!_marker) _marker = "";
                    DMTRACE(@"name: %s, part_of_speech: %s, definition: %s, marker: %s, lexname: %s, synset ID: %d", _name, _part_of_speech, _definition, _marker, _lexname, _synsetId);
                    
                    DubsarModelsPartOfSpeech _partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
                    NSString* definition = @(_definition);
                    pointer.targetGloss = [definition componentsSeparatedByString:@"; \""][0];
                    if (_marker && *_marker) {
                        pointer.targetText = [NSString stringWithFormat:@"<%s> (%s) %s, %@.", _lexname, _marker, _name, [DubsarModelsPartOfSpeechDictionary posFromPartOfSpeech:_partOfSpeech]];
                    }
                    else {
                        pointer.targetText = [NSString stringWithFormat:@"<%s> %s, %@.", _lexname, _name, [DubsarModelsPartOfSpeechDictionary posFromPartOfSpeech:_partOfSpeech]];
                    }
                    pointer.targetSynsetId = _synsetId;
                }
                
            }
            else {
                if ((rc=sqlite3_reset(semanticQuery)) != SQLITE_OK) {
                    DMERROR(@"error %d resetting semantic query", rc);
                }
                if ((rc=sqlite3_bind_int(semanticQuery, 1, (int)pointer.targetId)) != SQLITE_OK) {
                    DMERROR(@"error %d binding semantic query", rc);
                }
                
                /* semantic pointers */
                NSMutableArray* wordList = [NSMutableArray array];
                DubsarModelsPartOfSpeech ptrPartOfSpeech=DubsarModelsPartOfSpeechUnknown;
                char const* _lexname = "";
                NSString* pointerLexname;
                while (sqlite3_step(semanticQuery) == SQLITE_ROW) {
                    char const* _name;
                    char const* _part_of_speech;
                    if (pointer.targetGloss == nil) {
                        _name = (char const*)sqlite3_column_text(semanticQuery, 0);
                        _part_of_speech = (char const*)sqlite3_column_text(semanticQuery, 1);
                        char const* _definition = (char const*)sqlite3_column_text(semanticQuery, 2);
                        NSString* definition = @(_definition);
                        _lexname = (char const*)sqlite3_column_text(semanticQuery, 3);
                        pointerLexname = @(_lexname);

                        pointer.targetGloss = [definition componentsSeparatedByString:@"; \""][0];
                        ptrPartOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
                    }
                    
                    NSString* synonym = @(_name);
                    [wordList addObject:synonym];
                }
                                
                NSString* words = [NSString string];
                for (int j=0; j<wordList.count-1; ++j) {
                    words = [words stringByAppendingFormat:@"%@, ", wordList[j]];
                }
                if (wordList.count > 0) {
                    words = [words stringByAppendingString:wordList[wordList.count-1]];
                }
                
                pointer.targetText = [NSString stringWithFormat:@"<%@> %@, %@.", pointerLexname, words, [DubsarModelsPartOfSpeechDictionary posFromPartOfSpeech:ptrPartOfSpeech]];
            }
        }
        
    }
    
    return pointer;
}

-(void)prepareStatements
{
    DubsarModelsDatabaseWrapper* database = [DubsarModelsDatabase instance].database;
    int rc;

    NSString* sql = [NSString stringWithFormat:
                     @"SELECT id, target_id, target_type "
                     @"FROM pointers "
                     @"WHERE ((source_id = %lu AND source_type = 'Sense') OR "
                     @"(source_id = %lu AND source_type = 'Synset')) AND "
                     @"ptype = :ptype "
                     @"ORDER BY id ASC "
                     @"LIMIT 1 "
                     @"OFFSET :offset ", (unsigned long)_id, (unsigned long)synset._id];

    if ((rc=sqlite3_prepare_v2(database.dbptr, sql.UTF8String, -1, &pointerQuery, NULL)) != SQLITE_OK) {
        DMLOG(@"error %d preparing pointer query", rc);
        return;
    }
    
    char const* csql = "SELECT w.name, w.part_of_speech, sy.definition, se.marker, sy.lexname, sy.id "
              "FROM words w "
              "INNER JOIN senses se ON se.word_id = w.id "
              "INNER JOIN synsets sy ON sy.id = se.synset_id "
              "WHERE se.id = ? "
              "ORDER BY w.name ASC, w.part_of_speech ASC ";
    DMTRACE(@"preparing lexical query %s", csql);
    if ((rc=sqlite3_prepare_v2(database.dbptr, csql, -1, &lexicalQuery, NULL)) != SQLITE_OK) {
        DMLOG(@"error %d preparing lexical query", rc);
        return;
    }
    
    csql = "SELECT w.name, w.part_of_speech, sy.definition, sy.lexname "
           "FROM synsets sy "
           "INNER JOIN senses se ON se.synset_id = sy.id "
           "INNER JOIN words w ON w.id = se.word_id "
           "WHERE sy.id = ? "
           "ORDER BY w.name ASC";

    DMTRACE(@"preparing semantic query %s", csql);
    if ((rc=sqlite3_prepare_v2(database.dbptr, csql, -1, &semanticQuery, NULL)) != SQLITE_OK) {
        DMLOG(@"error %d preparing semantic query", rc);
        return;
    }
}

-(void)destroyStatements
{
    sqlite3_finalize(semanticQuery);
    sqlite3_finalize(lexicalQuery);
    sqlite3_finalize(pointerQuery);
}

@end
