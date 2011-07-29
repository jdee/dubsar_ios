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

#import "PartOfSpeechDictionary.h"
#import "PartOfSpeechDictionaryTest.h"


@implementation PartOfSpeechDictionaryTest

- (void)testMapping 
{
    PartOfSpeechDictionary* dictionary = [PartOfSpeechDictionary instance];
    
    STAssertNotNil(dictionary, @"PartOfSpeechDictionary should not be nil");
    STAssertNotNil(dictionary.dictionary, @"NSDictionary should not be nil");
    
    STAssertTrue(8 == dictionary.dictionary.count, @"expected dictionary to have 8 entries, found %d", dictionary.dictionary.count);
    
    PartOfSpeech partOfSpeech;
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"adj"];
    STAssertEquals(POSAdjective, partOfSpeech, @"expected POSAdjective, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"adv"];
    STAssertEquals(POSAdverb, partOfSpeech, @"expected POSAdverb, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"conj"];
    STAssertEquals(POSConjunction, partOfSpeech, @"expected POSConjunction, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"interj"];
    STAssertEquals(POSInterjection, partOfSpeech, @"expected POSInterjection, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"n"];
    STAssertEquals(POSNoun, partOfSpeech, @"expected POSNoun, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"prep"];
    STAssertEquals(POSPreposition, partOfSpeech, @"expected POSPreposition, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"pron"];
    STAssertEquals(POSPronoun, partOfSpeech, @"expected POSPronoun, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"v"];
    STAssertEquals(POSVerb, partOfSpeech, @"expected POSVerb, found %d", partOfSpeech);
}

@end