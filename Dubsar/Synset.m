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

#import "JSONKit.h"
#import "PartOfSpeechDictionary.h"
#import "Pointer.h"
#import "PointerDictionary.h"
#import "Section.h"
#import "Sense.h"
#import "Synset.h"
#import "Word.h"

@implementation Synset

@synthesize _id;
@synthesize gloss;
@synthesize partOfSpeech;
@synthesize lexname;
@synthesize freqCnt;
@synthesize samples;
@synthesize senses;
@synthesize pointers;
@synthesize sections;

+ (id)synsetWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[[self alloc]initWithId:theId partOfSpeech:thePartOfSpeech]autorelease];
}

+ (id)synsetWithId:(int)theId gloss:(NSString *)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    return [[[self alloc]initWithId:theId gloss:theGloss partOfSpeech:thePartOfSpeech]autorelease];
}

- (id)initWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = nil;
        partOfSpeech = thePartOfSpeech;
        lexname = nil;
        samples = nil;
        senses = nil;
        // [self set_url: [NSString stringWithFormat:@"/synsets/%d", _id]];
        [self prepareStatements];
    }
    return self;

}

- (id)initWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech
{
    self = [super init];
    if (self) {
        _id = theId;
        gloss = [[theGloss copy]retain];
        partOfSpeech = thePartOfSpeech;
        lexname = nil;
        samples = nil;
        senses = nil;
        // [self set_url: [NSString stringWithFormat:@"/synsets/%d", _id]];
        [self prepareStatements];
    }
    return self;
}

- (void)dealloc
{
    [self destroyStatements];
    [pointers release];
    [senses release];
    [samples release];
    [lexname release];
    [gloss release];
    [super dealloc];
}

- (void)parseData
{
    NSArray* response = [[self decoder] objectWithData:[self data]];
    partOfSpeech = [PartOfSpeechDictionary partOfSpeechFromPOS:[response objectAtIndex:1]];
    lexname = [[response objectAtIndex:2] retain];
    NSLog(@"lexname: \"%@\"", lexname);
    if (!gloss) {
        gloss = [[response objectAtIndex:3] retain];
    }
    samples = [[response objectAtIndex:4] retain];
    NSNumber* _freqCnt;
    NSArray* _senses = [response objectAtIndex:5];
    NSLog(@"found %u senses", _senses.count);
    senses = [[NSMutableArray arrayWithCapacity:_senses.count]retain];
    for (int j=0; j<_senses.count; ++j) {
        NSArray* _sense = [_senses objectAtIndex:j];
        NSNumber* _senseId = [_sense objectAtIndex:0];
        Sense* sense = [Sense senseWithId:_senseId.intValue name:[_sense objectAtIndex:1] synset:self];
        id marker = [_sense objectAtIndex:2];
        _freqCnt = [_sense objectAtIndex:3];
        sense.lexname = lexname;
        sense.freqCnt = _freqCnt.intValue;
        if (marker != NSNull.null) {
            sense.marker = marker;
        }
        [senses insertObject:sense atIndex:j];
    }
    [senses sortUsingSelector:@selector(compareFreqCnt:)];
    
    _freqCnt = [response objectAtIndex:6];
    freqCnt = _freqCnt.intValue;
    
    [self parsePointers:response];
}

- (void)parsePointers:(NSArray*)response
{    
    pointers = [[NSMutableDictionary dictionary]retain];
    NSArray* _pointers = [response objectAtIndex:7];
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

-(NSString*)synonymsAsString
{
    NSString* synonymList = [NSString string];
    
    /* 
     * The app still sometimes crashes when this autorelease pool is used.
     */
#ifdef AUTORELEASE_POOL_FOR_SYNONYMS
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
#endif // AUTORELEASE_POOL_FOR_SYNOYMS
    
    for(int j=0; j<senses.count; ++j) {
        Sense* sense = [senses objectAtIndex:j];
        synonymList = [synonymList stringByAppendingString:sense.name];
        if (j<senses.count-1) {
            synonymList = [synonymList stringByAppendingString:@", "];
        }
    }
    
#ifdef AUTORELEASE_POOL_FOR_SYNONYMS
    [pool release];
#endif // AUTORELEASE_POOL_FOR_SYNONYMS    
    return synonymList;
}


- (void)loadResults:(DubsarAppDelegate *)appDelegate
{
    NSString* sql = [NSString stringWithFormat:
                     @"SELECT sy.definition, sy.lexname, sy.part_of_speech, se.freq_cnt, se.id, w.name "
                     @"FROM senses se "
                     @"INNER JOIN synsets sy ON sy.id = se.synset_id "
                     @"INNER JOIN words w ON se.word_id = w.id "
                     @"WHERE sy.id = %d ", _id];
    
    int rc;
    sqlite3_stmt* statement;
    
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        return;
    }
    
    NSLog(@"executing %@", sql);
    freqCnt = 0;
    self.senses = [NSMutableArray array];
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _definition = (char const*)sqlite3_column_text(statement, 0);
        char const* _lexname = (char const*)sqlite3_column_text(statement, 1);
        char const* _part_of_speech = (char const*)sqlite3_column_text(statement, 2);
        freqCnt += sqlite3_column_int(statement, 3);
        int senseId = sqlite3_column_int(statement, 4);
        char const* _name = (char const*)sqlite3_column_text(statement, 5);
 
        if (samples == nil) {
            partOfSpeech = [PartOfSpeechDictionary partOfSpeechFrom_part_of_speech:_part_of_speech];
            
            self.lexname = [NSString stringWithCString:_lexname encoding:NSUTF8StringEncoding];
            
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
        
        Sense* synonym = [Sense senseWithId:senseId name:[NSString stringWithCString:_name encoding:NSUTF8StringEncoding] partOfSpeech:partOfSpeech];
        [senses addObject:synonym];
    }
    sqlite3_finalize(statement);
}

-(int)numberOfSections
{
    NSLog(@"in numberOfSections");
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)UIApplication.sharedApplication.delegate;
    
    NSString* sql;
    int rc;
    sqlite3_stmt* statement;
    
    self.sections = [NSMutableArray array];
    
    if (senses.count > 0) {
        Section* section = [Section section];
        section.header = @"Synonyms";
        section.footer = [PointerDictionary helpWithPointerType:@"synonym"];
        section.linkType = @"sense";
        section.ptype = @"synonym";
        section.numRows = senses.count;
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
           @"SELECT DISTINCT ptype FROM pointers WHERE source_id = %d AND source_type = 'Synset' ", _id];
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        self.errorMessage = [NSString stringWithFormat:@"error %d preparing statement", rc];
        NSLog(@"%@", self.errorMessage);
        return 1;
    }
    
    NSLog(@"executing %@", sql);
    while (sqlite3_step(statement) == SQLITE_ROW) {
        char const* _ptype = (char const*)sqlite3_column_text(statement, 0);
        
        Section* section = [Section section];
        section.ptype = [NSString stringWithCString:_ptype encoding:NSUTF8StringEncoding];
        section.header = [PointerDictionary titleWithPointerType:section.ptype];
        section.footer = [PointerDictionary helpWithPointerType:section.ptype];
        section.ptype = [NSString stringWithCString:_ptype encoding:NSUTF8StringEncoding];
        section.senseId = 0;
        section.synsetId = _id;
        section.linkType = @"pointer";
        [sections addObject:section];
    }
    sqlite3_finalize(statement);
    NSLog(@"%d sections in tableView", sections.count);
    return sections.count;
}

- (Pointer*)pointerForRowAtIndexPath:(NSIndexPath*)indexPath
{
    Section* section = [sections objectAtIndex:indexPath.section];
    Pointer* pointer = [Pointer pointer];
    
    if ([section.ptype isEqualToString:@"synonym"]) {
        Sense* synonym = [senses objectAtIndex:indexPath.row];
        NSLog(@"requesting synonym %@", synonym.name);
        pointer.targetText = synonym.name;
        pointer.targetId = synonym._id;
        pointer.targetType = @"sense";
    }
    else if ([section.ptype isEqualToString:@"sample sentence"]) {
        pointer.targetText = [samples objectAtIndex:indexPath.row];
    }
    else {
        int rc;
        if ((rc=sqlite3_reset(pointerQuery)) != SQLITE_OK) {
            NSLog(@"error %d preparing statement", rc);
            return pointer;
        }

        int ptypeIdx = sqlite3_bind_parameter_index(pointerQuery, ":ptype");
        int offsetIdx = sqlite3_bind_parameter_index(pointerQuery, ":offset");
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
                
                [wordList addObject:[NSString stringWithCString:_name encoding:NSUTF8StringEncoding]];
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
    
    return pointer;
}

-(void)prepareStatements
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)UIApplication.sharedApplication.delegate;
    int rc;
    
    NSString* sql = [NSString stringWithFormat:@"SELECT id, target_id, target_type "
                     @"FROM pointers "
                     @"WHERE source_id = %d AND source_type = 'Synset' AND "
                     @"ptype = :ptype "
                     @"ORDER BY id ASC "
                     @"LIMIT 1 "
                     @"OFFSET :offset ", _id];
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &pointerQuery, NULL)) != SQLITE_OK) {
        NSLog(@"error %d preparing statement", rc);
        return;
    }        
    
    char const* csql = "SELECT w.name, w.part_of_speech, sy.definition "
    "FROM synsets sy "
    "INNER JOIN senses se ON se.synset_id = sy.id "
    "INNER JOIN words w ON w.id = se.word_id "
    "WHERE sy.id = ? "
    "ORDER BY w.name ASC";
    
    NSLog(@"preparing semantic query %s", csql);
    if ((rc=sqlite3_prepare_v2(appDelegate.database, csql, -1, &semanticQuery, NULL)) != SQLITE_OK) {
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
