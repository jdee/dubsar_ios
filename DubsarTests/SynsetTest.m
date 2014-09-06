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

#import "SynsetTest.h"

@implementation SynsetTest

- (void)testParsing
{
    NSString* stringData = @"[21803,\"n\",\"noun.Tops\",\"synset gloss\",[],[[35629,\"food\",null,29,35631],[35630,\"nutrient\",null,1,35630]],30,[[\"hypernym\",\"synset\",21801,\"substance\",\"hypernym gloss\"]]]";
    
    DubsarModelsSynset* synset = [DubsarModelsSynset synsetWithId:21803 gloss:@"synset gloss" partOfSpeech:DubsarModelsPartOfSpeechNoun];
    synset.data = [self.class dataWithString:stringData];
    [synset parseData];
    
    XCTAssertEqualObjects(@"noun.Tops", synset.lexname, @"lexname failed");
    XCTAssertNotNil(synset.samples, @"samples failed");
    XCTAssertEqual((unsigned int)0, synset.samples.count, @"samples count failed");
    XCTAssertEqual((unsigned int)2, synset.senses.count, @"senses count failed");
    XCTAssertEqual(30, synset.freqCnt, @"frequency count failed");
    XCTAssertEqual((unsigned int)1, synset.pointers.count, @"pointers count failed");
}

-(void)testInitialization
{
    DubsarModelsSynset* a = [[DubsarModelsSynset alloc]init];
    XCTAssertTrue(!a.complete, @"complete failed");
    XCTAssertTrue(!a.error, @"error failed");
}

@end
