/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURDubsarModelsPartOfSpeechE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

@import DubsarModels;

#import "SenseTest.h"

@implementation SenseTest

- (void)testParsing
{
    NSString* stringData = @"[35629,[26063,\"food\",\"n\"],[21803,\"sense gloss\"],\"noun.Tops\",null,29,[[35630,\"nutrient\",null,1]],[],[],[[\"hypernym\",\"synset\",21801,\"substance\",\"hypernym gloss\"]]]";
    
    /* This resembles the way senses are parsed in word responses. */
    DubsarModelsWord* word = [DubsarModelsWord wordWithId:26063 name:@"food" partOfSpeech:DubsarModelsPartOfSpeechNoun];

    DubsarModelsSense* synSense = [DubsarModelsSense senseWithId:35630 name:@"nutrient" partOfSpeech:DubsarModelsPartOfSpeechNoun];
    NSMutableArray* synonyms = [NSMutableArray arrayWithObject:synSense];
    
    DubsarModelsSense* sense =[DubsarModelsSense senseWithId:35629 gloss:@"sense gloss" synonyms:synonyms word:word];
    sense.data = [self.class dataWithString:stringData];
    NSLog(@"sense.data: %u bytes", sense.data.length);
    [sense parseData];
    
    // word
    XCTAssertEqual(26063, sense.word._id, @"word ID failed");
    XCTAssertEqualObjects(@"food", sense.word.name, @"word name failed");
    XCTAssertEqual(DubsarModelsPartOfSpeechNoun, sense.word.partOfSpeech, @"word partOfSpeech failed");

    // synset
    XCTAssertEqual(21803, sense.synset._id, @"synset ID failed");
    XCTAssertEqualObjects(@"sense gloss", sense.synset.gloss, @"synset gloss failed");

    // sense
    XCTAssertEqualObjects(@"noun.Tops", sense.lexname, @"lexname failed");
    XCTAssertNil(sense.marker, @"marker failed");
    XCTAssertEqual(29, sense.freqCnt, @"frequency count failed");

    // synonyms
    XCTAssertNotNil(sense.synonyms, @"synonyms failed");
    XCTAssertEqual((unsigned int)1, sense.synonyms.count, @"synonym count failed");
    
    synSense = (sense.synonyms)[0];
    XCTAssertEqual(35630, synSense._id, @"synonym ID failed");
    XCTAssertEqualObjects(@"nutrient", synSense.name, @"synonym name failed");
    XCTAssertNil(synSense.marker, @"synonym marker failed");
    XCTAssertEqual(1, synSense.freqCnt, @"synonym frequency count failed");

    // samples, verb frames
    XCTAssertNotNil(sense.samples, @"samples failed");
    XCTAssertEqual(sense.samples.count, (unsigned int)0, @"samples count failed");
    XCTAssertNotNil(sense.verbFrames, @"verb frames failed");
    XCTAssertEqual(sense.verbFrames.count, (unsigned int)0, @"verb frames count failed");
    
    // pointers
    NSDictionary* pointers = sense.pointers;    
    XCTAssertEqual((unsigned int)1, pointers.count, @"pointer count failed");
    NSArray* _pointers = [pointers valueForKey:@"hypernym"];
    XCTAssertNotNil(_pointers, @"pointers failed");
    XCTAssertEqual((unsigned int)1, _pointers.count, @"pointers count failed");
    
    NSArray* _pointer = _pointers[0];

    NSNumber* numericID = _pointer[1];
    
    XCTAssertEqualObjects(@"synset", _pointer[0], @"hypernym target type failed");
    XCTAssertEqual(21801, numericID.intValue, @"hypernym ID failed");
    XCTAssertEqualObjects(@"substance", _pointer[2], @"hypernym text failed");
    XCTAssertEqualObjects(@"hypernym gloss", _pointer[3], @"hypernym gloss failed");
}

-(void)testNameAndPosParsing
{
    NSString* nameAndPos = @"beauty (n.)";
    DubsarModelsSense* sense = [DubsarModelsSense senseWithId:1 nameAndPos:nameAndPos];
    XCTAssertEqualObjects(@"beauty", sense.name, @"name failed");
    XCTAssertEqual(DubsarModelsPartOfSpeechNoun, sense.partOfSpeech, @"part of speech failed");
}

-(void)testInitialization
{
    DubsarModelsSense* a = [[DubsarModelsSense alloc]init];
    XCTAssertTrue(!a.complete, @"complete failed");
    XCTAssertTrue(!a.error, @"error failed");
}

@end
