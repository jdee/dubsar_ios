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

#import "PartOfSpeechDictionary.h"
#import "Pointer.h"
#import "PointerDictionary.h"
#import "Section.h"
#import "Sense.h"
#import "Synset.h"
#import "Word.h"

@implementation Sense

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
@synthesize numberOfSections=_numberOfSections;
@synthesize sections;

+(id)senseWithId:(int)theId name:(NSString *)theName synset:(Synset *)theSynset
{
    return [[self alloc]initWithId:theId name:theName synset:theSynset];
}

+(id)senseWithId:(int)theId name:(NSString *)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[self alloc]initWithId:theId name:theName partOfSpeech:thePartOfSpeech];
}

+(id)senseWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(Word *)theWord
{
    return [[self alloc]initWithId:theId gloss:theGloss synonyms:theSynonyms word:theWord];
}

+(id)senseWithId:(int)theId nameAndPos:(NSString*)nameAndPos
{
    return [[self alloc]initWithId:theId nameAndPos:nameAndPos];
}

-(id)initWithId:(int)theId name:(NSString *)theName synset:(Synset *)theSynset
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
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = true;
        weakWordLink = false;
        [self initUrl];
    }
    return self;
}

-(id)initWithId:(int)theId name:(NSString *)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech
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
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakWordLink = weakSynsetLink = false;
        [self initUrl];
    }
    return self;
   
}

-(id)initWithId:(int)theId gloss:(NSString *)theGloss synonyms:(NSArray *)theSynonyms word:(Word *)theWord
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
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = false;
        weakWordLink = true;
        [self initUrl];
    }
    return self;
}

-(id)initWithId:(int)theId nameAndPos:(NSString*)nameAndPos
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = nil;
        synonyms = nil;
        word = nil;
        synset = nil;
        marker = nil;
        verbFrames = nil;
        samples = nil;
        pointers = nil;
        weakSynsetLink = false;
        weakWordLink = false;
        [self initUrl];
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
        Sense* synonym = [synonyms objectAtIndex:j];
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
        case POSAdjective:
            return @"adj";
        case POSAdverb:
            return @"adv";
        case POSConjunction:
            return @"conj";
        case POSInterjection:
            return @"interj";
        case POSNoun:
            return @"n";
        case POSPreposition:
            return @"prep";
        case POSPronoun:
            return @"pron";
        case POSVerb:
            return @"v";
        default:
            return @"..";
    }
}

-(NSString *)nameAndPos
{
    return [NSString stringWithFormat:@"%@ (%@.)", name, self.pos];
}

-(void)parseNameAndPos:(NSString *)nameAndPos
{
    NSRange posStartRange = [nameAndPos rangeOfString:@" ("];
    if (posStartRange.location == NSNotFound) {
#ifdef DEBUG
        NSLog(@"did not find \" (\"");
#endif // DEBUG
        return;
    }
    
    NSRange posEndRange = [nameAndPos rangeOfString:@".)" options:0 range:NSMakeRange(posStartRange.location+2, nameAndPos.length-posStartRange.location-2)];
    if (posEndRange.location == NSNotFound) {
#ifdef DEBUG
        NSLog(@"did not find \".)\"");
#endif // DEBUG
        return;
    }
    
    NSRange nameRange = NSMakeRange(0, posStartRange.location);
    NSRange posRange = NSMakeRange(posStartRange.location+2, posEndRange.location-posStartRange.location-2);
    
    name = [nameAndPos substringWithRange:nameRange];
    partOfSpeech = [PartOfSpeechDictionary partOfSpeechFromPOS:[nameAndPos substringWithRange:posRange]];
}

-(void)parseData
{
#ifdef DEBUG
    NSLog(@"parsing Sense response for %@, %u bytes", self.nameAndPos, [self data].length);
#endif // DEBUG
    
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
#ifdef DEBUG
    NSLog(@"sense response array has %u entries", response.count);
#endif // DEBUG
    
    NSArray* _word = [response objectAtIndex:1];
    NSNumber* _wordId = [_word objectAtIndex:0];
    NSArray* _synset = [response objectAtIndex:2];
    NSNumber* _synsetId = [_synset objectAtIndex:0];
    
    partOfSpeech = [PartOfSpeechDictionary partOfSpeechFromPOS:[_word objectAtIndex:2]];
    
    if (!word) {
        word = [Word wordWithId:_wordId.intValue name:[_word objectAtIndex:1] partOfSpeech:partOfSpeech];
        weakWordLink = false;
    }

    if (!gloss) {
        gloss = [_synset objectAtIndex:1];
    }
   
    if (!synset) {
        synset = [Synset synsetWithId:_synsetId.intValue gloss:[_synset objectAtIndex:1] partOfSpeech:partOfSpeech];
        weakSynsetLink = false;
    }
    
    lexname = [response objectAtIndex:3];
#ifdef DEBUG
    NSLog(@"lexname: \"%@\"", lexname);
#endif // DEBUG
    
    synset.lexname = lexname;

    NSObject* _marker = [response objectAtIndex:4];
    if (_marker != NSNull.null) {
        marker = (NSString*)_marker;
    }
    
    NSNumber* fc = [response objectAtIndex:5];
    freqCnt = fc.intValue;

#ifdef DEBUG
    NSLog(@"freq. cnt.: %d", freqCnt);
#endif // DEBUG
    
    NSArray* _synonyms = [response objectAtIndex:6];
#ifdef DEBUG
    NSLog(@"found %u synonyms", [_synonyms count]);
#endif // DEBUG
    synonyms = [NSMutableArray arrayWithCapacity:_synonyms.count];
    for (int j=0; j< _synonyms.count; ++j) {
        NSArray* _synonym = [_synonyms objectAtIndex:j];
        NSNumber* _senseId = [_synonym objectAtIndex:0];
        Sense* sense = [Sense senseWithId:_senseId.intValue name:[_synonym objectAtIndex:1] synset:synset];
        _marker = [_synonym objectAtIndex:2];
        if (_marker != NSNull.null) {
            sense.marker = [_synonym objectAtIndex:2];
        }
        fc = [_synonym objectAtIndex:3];
        sense.freqCnt = fc.intValue;
#ifdef DEBUG
        NSLog(@" found %@, ID %d, freq. cnt. %d", sense.nameAndPos, sense._id, sense.freqCnt);
#endif // DEBUG
        [synonyms insertObject:sense atIndex:j];
    }
    [synonyms sortUsingSelector:@selector(compareFreqCnt:)];
    
    NSArray* _verbFrames = [response objectAtIndex:7];
#ifdef DEBUG
    NSLog(@"found %u verb frames", _verbFrames.count);
#endif // DEBUG
    verbFrames = [NSMutableArray arrayWithCapacity:_verbFrames.count];
    for (int j=0; j<_verbFrames.count; ++j) {
        NSString* frame = [_verbFrames objectAtIndex:j];
        NSString* format = [frame stringByReplacingOccurrencesOfString:@"%s" withString:@"%@"];
#ifdef DEBUG
        NSLog(@" %@", format);
#endif // DEBUG
        [verbFrames insertObject:[NSString stringWithFormat:format, name] atIndex:j];
    }
    samples = [response objectAtIndex:8];

#ifdef DEBUG
    NSLog(@"found %u verb frames and %u sample sentences", [verbFrames count], [samples count]);
#endif // DEBUG
    
    [self parsePointers:response];
}

- (void)parsePointers:(NSArray*)response
{    
    pointers = [NSMutableDictionary dictionary];
    NSArray* _pointers = [response objectAtIndex:9];
    for (int j=0; j<_pointers.count; ++j) {
        NSArray* _pointer = [_pointers objectAtIndex:j];
        
        NSString* ptype = [_pointer objectAtIndex:0];
        NSString* targetType = [_pointer objectAtIndex:1];
        NSNumber* targetId = [_pointer objectAtIndex:2];
        NSString* targetText = [_pointer objectAtIndex:3];
        NSString* targetGloss = [_pointer objectAtIndex:4];
        
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

- (void)initUrl
{
    // [self set_url: [NSString stringWithFormat:@"/senses/%d", _id]];
}

- (NSComparisonResult)compareFreqCnt:(Sense*)sense
{
    return freqCnt < sense.freqCnt ? NSOrderedDescending : 
        freqCnt > sense.freqCnt ? NSOrderedAscending : 
        NSOrderedSame;
}

/*
- (void)load
{
    [NSThread detachNewThreadSelector:@selector(databaseThread) toTarget:self withObject:nil];
}
 */

- (void)loadResults:(AppDelegate *)appDelegate
{
    NSString* sql = [NSString stringWithFormat:
                     @"SELECT sy.id, sy.definition, sy.lexname, se.marker, se.freq_cnt, w.id, w.part_of_speech, vf.frame, vf.number, w.name "
                     @"FROM senses se "
                     @"INNER JOIN synsets sy ON sy.id = se.synset_id "
                     @"INNER JOIN words w ON w.id = se.word_id "
                     @"LEFT JOIN senses_verb_frames svf ON svf.sense_id = se.id "
                     @"LEFT JOIN verb_frames vf ON vf.id = svf.verb_frame_id "
                     @"WHERE se.id = %d "
                     @"ORDER BY vf.number ASC ", _id];
    
    int rc;
    sqlite3_stmt* statement;
    
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        return;
    }

#ifdef DEBUG
    NSLog(@"executing %@", sql);
#endif // DEBUG
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
        self.name = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];

#ifdef DEBUG
        NSLog(@"matching row: synsetId = %d, wordId = %d", synsetId, wordId);
#endif // DEBUG
        
        if (samples == nil) {
            partOfSpeech = [PartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
            word = [Word wordWithId:wordId name:name partOfSpeech:partOfSpeech];
            synset = [Synset synsetWithId:synsetId partOfSpeech:partOfSpeech];
            weakSynsetLink = weakWordLink = false;
#ifdef DEBUG
            NSLog(@"created synset with id %d", synset._id);
#endif // DEBUG
            
            self.lexname = [NSString stringWithCString:_lexname encoding:NSUTF8StringEncoding];
            self.marker = _marker == NULL ? nil : [NSString stringWithCString:_marker encoding:NSUTF8StringEncoding];
            
            NSString* definition = [NSString stringWithCString:_definition encoding:NSUTF8StringEncoding];
            NSArray* components = [definition componentsSeparatedByString:@"; \""];
            self.gloss = [components objectAtIndex:0];
            
            self.samples = [NSMutableArray array];
            if (components.count > 1) {
                NSRange range;
                range.location = 1;
                range.length = components.count - 1;
                NSArray* sampleArray = [components subarrayWithRange:range];
                
                for (int j=0; j<sampleArray.count; ++j) {
                    NSString* sample = [sampleArray objectAtIndex:j];
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
            char const* _name = [name cStringUsingEncoding:NSUTF8StringEncoding];
            NSString* frame = [NSString stringWithCString:_frame encoding:NSUTF8StringEncoding];
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
           @"SELECT se.id, w.name "
           @"FROM senses se "
           @"INNER JOIN words w ON w.id = se.word_id "
           @"WHERE se.synset_id = %d AND w.name != ? "
           @"ORDER BY w.name ASC ", synset._id];
    
    if ((rc=sqlite3_prepare(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        return;
    }
    
    if ((rc=sqlite3_bind_text(statement, 1, [name cStringUsingEncoding:NSUTF8StringEncoding], -1, SQLITE_STATIC)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
        sqlite3_finalize(statement);
        return;       
    }

#ifdef DEBUG
    NSLog(@"executing %@", sql);
#endif // DEBUG
    self.synonyms = [NSMutableArray array];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        int senseId = sqlite3_column_int(statement, 0);
        char const* _name = (char const*)sqlite3_column_text(statement, 1);
        
        Sense* synonym = [Sense senseWithId:senseId name:[NSString stringWithCString:_name encoding:NSUTF8StringEncoding] partOfSpeech:partOfSpeech];
        [synonyms addObject:synonym];
    }
    
    sqlite3_finalize(statement);
    
    [self prepareStatements];
}

-(int)numberOfSections
{
#ifdef DEBUG
    NSLog(@"in numberOfSections");
#endif // DEBUG
    AppDelegate* appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
    
    NSString* sql;
    int rc;
    sqlite3_stmt* statement;
    
    self.sections = [NSMutableArray array];
    
    if (synonyms.count > 0) {
        Section* section = [Section section];
        section.header = @"Synonyms";
        section.footer = [PointerDictionary helpWithPointerType:@"synonym"];
        section.linkType = @"sense";
        section.ptype = @"synonym";
        section.numRows = synonyms.count;
        [sections addObject:section];
    }
    if (verbFrames.count > 0) {
        Section* section = [Section section];
        section.header = @"Verb Frames";
        section.footer = [PointerDictionary helpWithPointerType:@"verb frame"];
        section.linkType = @"sample";
        section.ptype = @"verb frame";
        section.numRows = verbFrames.count;
        [sections addObject:section];
    }
    if (samples.count > 0) {
        Section* section = [Section section];
        section.header = @"Samples";
        section.footer = [PointerDictionary helpWithPointerType:@"sample sentence"];
        section.linkType = @"sample";
        section.ptype = @"sample sentence";
        section.numRows = samples.count;
        [sections addObject:section];
    }
    
    sql = [NSString stringWithFormat:
           @"SELECT DISTINCT ptype FROM pointers WHERE (source_id = %d AND source_type = 'Sense') OR "
           @"(source_id = %d AND source_type = 'Synset') ", _id, synset._id];
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        NSLog(@"%@", self.errorMessage);
        return 1;
    }

#ifdef DEBUG
    NSLog(@"executing %@", sql);
#endif // DEBUG
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _ptype = (char const*)sqlite3_column_text(statement, 0);
        
        Section* section = [Section section];
        section.ptype = [NSString stringWithCString:_ptype encoding:NSUTF8StringEncoding];
        section.header = [PointerDictionary titleWithPointerType:section.ptype];
        section.footer = [PointerDictionary helpWithPointerType:section.ptype];
        section.senseId = _id;
        section.synsetId = synset._id;
        section.linkType = @"pointer";
        [sections addObject:section];
    }
    sqlite3_finalize(statement);
#ifdef DEBUG
    NSLog(@"%d sections in tableView", sections.count);
#endif // DEBUG
    return sections.count;
}

- (Pointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath
{
    Section* section = [sections objectAtIndex:indexPath.section];
    Pointer* pointer = [Pointer pointer];
        
    if ([section.ptype isEqualToString:@"synonym"]) {
        Sense* synonym = [synonyms objectAtIndex:indexPath.row];
#ifdef DEBUG
        NSLog(@"requesting synonym %@", synonym.name);
#endif // DEBUG
        pointer.targetText = synonym.name;
        pointer.targetId = synonym._id;
        pointer.targetType = @"sense";
    }
    else if ([section.ptype isEqualToString:@"verb frame"]) {
        pointer.targetText = [verbFrames objectAtIndex:indexPath.row];
    }
    else if ([section.ptype isEqualToString:@"sample sentence"]) {
        pointer.targetText = [samples objectAtIndex:indexPath.row];
    }
    else {
        int rc;        
        int ptypeIdx = sqlite3_bind_parameter_index(pointerQuery, ":ptype");
        int offsetIdx = sqlite3_bind_parameter_index(pointerQuery, ":offset");
        
        if ((rc=sqlite3_reset(pointerQuery)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error resetting statement, error %d", rc];
            return nil;
        }
        if ((rc=sqlite3_bind_int(pointerQuery, offsetIdx, indexPath.row)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return nil;
        }
        if ((rc=sqlite3_bind_text(pointerQuery, ptypeIdx, [section.ptype cStringUsingEncoding:NSUTF8StringEncoding], -1, NULL)) != SQLITE_OK) {
            self.errorMessage = [NSString stringWithFormat:@"error %d binding parameter", rc];
            return nil;          
        }
        
        if (sqlite3_step(pointerQuery) == SQLITE_ROW) {
            pointer.targetId = sqlite3_column_int(pointerQuery, 1);
            char const* _targetType = (char const*)sqlite3_column_text(pointerQuery, 2);
            pointer.targetType = [NSString stringWithCString:_targetType encoding:NSUTF8StringEncoding];
            
            if ([pointer.targetType isEqualToString:@"Sense"]) {
                if ((rc=sqlite3_reset(lexicalQuery)) != SQLITE_OK) {
                    NSLog(@"error %d resetting lexical query", rc);
                }
                if ((rc=sqlite3_bind_int(lexicalQuery, 1, pointer.targetId)) != SQLITE_OK) {
                    NSLog(@"error %d binding lexical query", rc);
                }
                
                /* lexical pointers */
                if (sqlite3_step(lexicalQuery) == SQLITE_ROW) {
                    char const* _name = (char const*)sqlite3_column_text(lexicalQuery, 0);
                    char const* _part_of_speech = (char const*)sqlite3_column_text(lexicalQuery, 1);
                    char const* _definition = (char const*)sqlite3_column_text(lexicalQuery, 2);
                    
                    PartOfSpeech _partOfSpeech = [PartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
                    NSString* definition = [NSString stringWithCString:_definition encoding:NSUTF8StringEncoding];
                    pointer.targetGloss = [[definition componentsSeparatedByString:@"; \""]objectAtIndex:0];
                    pointer.targetText = [NSString stringWithFormat:@"%s (%@.)", _name, [PartOfSpeechDictionary posFromPartOfSpeech:_partOfSpeech]];
                    // pointer.targetName = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];
                }
                
            }
            else {
                if ((rc=sqlite3_reset(semanticQuery)) != SQLITE_OK) {
                    NSLog(@"error %d resetting semantic query", rc);
                }
                if ((rc=sqlite3_bind_int(semanticQuery, 1, pointer.targetId)) != SQLITE_OK) {
                    NSLog(@"error %d binding semantic query", rc);
                }
                
                /* semantic pointers */
                NSMutableArray* wordList = [NSMutableArray array];
                PartOfSpeech ptrPartOfSpeech=POSUnknown;
                while (sqlite3_step(semanticQuery) == SQLITE_ROW) {
                    char const* _name;
                    char const* _part_of_speech;
                    if (pointer.targetGloss == nil) {
                        _name = (char const*)sqlite3_column_text(semanticQuery, 0);
                        _part_of_speech = (char const*)sqlite3_column_text(semanticQuery, 1);
                        char const* _definition = (char const*)sqlite3_column_text(semanticQuery, 2);
                        NSString* definition = [NSString stringWithCString:_definition encoding:NSUTF8StringEncoding];
                        
                        pointer.targetGloss = [[definition componentsSeparatedByString:@"; \""]objectAtIndex:0];
                        ptrPartOfSpeech = [PartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
                    }
                    
                    NSString* synonym = [NSString stringWithCString:_name encoding:NSUTF8StringEncoding];
                    [wordList addObject:synonym];
                }
                                
                NSString* words = [NSString string];
                for (int j=0; j<wordList.count-1; ++j) {
                    words = [words stringByAppendingFormat:@"%@, ", [wordList objectAtIndex:j]];
                }
                if (wordList.count > 0) {
                    words = [words stringByAppendingString:[wordList objectAtIndex:wordList.count-1]];
                }
                
                pointer.targetText = [NSString stringWithFormat:@"%@ (%@.)", words, [PartOfSpeechDictionary posFromPartOfSpeech:ptrPartOfSpeech]];
            }
        }
        
    }
    
    return pointer;
}

-(void)prepareStatements
{
    AppDelegate* appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
    int rc;

    NSString* sql = [NSString stringWithFormat:
                     @"SELECT id, target_id, target_type "
                     @"FROM pointers "
                     @"WHERE ((source_id = %d AND source_type = 'Sense') OR "
                     @"(source_id = %d AND source_type = 'Synset')) AND "
                     @"ptype = :ptype "
                     @"ORDER BY id ASC "
                     @"LIMIT 1 "
                     @"OFFSET :offset ", _id, synset._id];

    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &pointerQuery, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing pointer query", rc);
        return;
    }
    
    char const* csql = "SELECT w.name, w.part_of_speech, sy.definition, se.marker "
              "FROM words w "
              "INNER JOIN senses se ON se.word_id = w.id "
              "INNER JOIN synsets sy ON sy.id = se.synset_id "
              "WHERE se.id = ? "
              "ORDER BY w.name ASC, w.part_of_speech ASC ";
#ifdef DEBUG
    NSLog(@"preparing lexical query %s", csql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(appDelegate.database, csql, -1, &lexicalQuery, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing lexical query", rc);
        return;
    }
    
    csql = "SELECT w.name, w.part_of_speech, sy.definition "
           "FROM synsets sy "
           "INNER JOIN senses se ON se.synset_id = sy.id "
           "INNER JOIN words w ON w.id = se.word_id "
           "WHERE sy.id = ? "
           "ORDER BY w.name ASC";

#ifdef DEBUG
    NSLog(@"preparing semantic query %s", csql);
#endif // DEBUG
    if ((rc=sqlite3_prepare_v2(appDelegate.database, csql, -1, &semanticQuery, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing semantic query", rc);
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
