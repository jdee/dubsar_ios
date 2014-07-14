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

@import DubsarModels;

#import "PartOfSpeechDictionaryTest.h"

@implementation PartOfSpeechDictionaryTest

- (void)testMapping 
{
    DubsarModelsPartOfSpeechDictionary* dictionary = [DubsarModelsPartOfSpeechDictionary instance];
    
    XCTAssertNotNil(dictionary, @"PartOfSpeechDictionary should not be nil");
    XCTAssertNotNil(dictionary.dictionary, @"NSDictionary should not be nil");
    
    XCTAssertEqual((unsigned int)8, dictionary.dictionary.count, @"expected dictionary to have 8 entries, found %lu", (unsigned long)dictionary.dictionary.count);
    
    DubsarModelsPartOfSpeech partOfSpeech;
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"adj"];
    XCTAssertEqual(DubsarModelsPartOfSpeechAdjective, partOfSpeech, @"expected POSAdjective, found %ld", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"adv"];
    XCTAssertEqual(DubsarModelsPartOfSpeechAdverb, partOfSpeech, @"expected POSAdverb, found %ld", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"conj"];
    XCTAssertEqual(DubsarModelsPartOfSpeechConjunction, partOfSpeech, @"expected POSConjunction, found %ld", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"interj"];
    XCTAssertEqual(DubsarModelsPartOfSpeechInterjection, partOfSpeech, @"expected POSInterjection, found %ld", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"n"];
    XCTAssertEqual(DubsarModelsPartOfSpeechNoun, partOfSpeech, @"expected POSNoun, found %ld", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"prep"];
    XCTAssertEqual(DubsarModelsPartOfSpeechPreposition, partOfSpeech, @"expected POSPreposition, found %ld", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"pron"];
    XCTAssertEqual(DubsarModelsPartOfSpeechPronoun, partOfSpeech, @"expected POSPronoun, found %ld", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"v"];
    XCTAssertEqual(DubsarModelsPartOfSpeechVerb, partOfSpeech, @"expected POSVerb, found %ld", partOfSpeech);
}

- (void)testReverseMapping
{
    DubsarModelsPartOfSpeechDictionary* dictionary = [DubsarModelsPartOfSpeechDictionary instance];
    
    NSString* pos;
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechAdjective];
    XCTAssertTrue([pos isEqualToString:@"adj"], @"expected pos \"adj\" for adjective, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechAdverb];
    XCTAssertTrue([pos isEqualToString:@"adv"], @"expected pos \"adv\" for adverb, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechConjunction];
    XCTAssertTrue([pos isEqualToString:@"conj"], @"expected pos \"conj\" for conjunction, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechInterjection];
    XCTAssertTrue([pos isEqualToString:@"interj"], @"expected pos \"interj\" for interjection, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechNoun];
    XCTAssertTrue([pos isEqualToString:@"n"], @"expected pos \"n\" for noun, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechPreposition];
    XCTAssertTrue([pos isEqualToString:@"prep"], @"expected pos \"prep\" for preposition, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechPronoun];
    XCTAssertTrue([pos isEqualToString:@"pron"], @"expected pos \"pron\" for pronoun, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:DubsarModelsPartOfSpeechVerb];
    XCTAssertTrue([pos isEqualToString:@"v"], @"expected pos \"v\" for verb, found \"%@\"", pos);
}

@end
