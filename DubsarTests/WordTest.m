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

#import "WordTest.h"

@implementation WordTest

- (void)testParsing
{
    NSString* stringData = @"[26063,\"food\",\"n\",\"foods\",[[35629,[[35630,\"nutrient\"]],\"any substance that can be metabolized by an animal to give energy and build tissue  \",\"noun.Tops\",null,29]],29]";
    
    DubsarModelsWord* word =[DubsarModelsWord wordWithId:26063 name:@"food" partOfSpeech:DubsarModelsPartOfSpeechNoun];
    word.data = [self.class dataWithString:stringData];
    [word parseData];
        
    XCTAssertEqual((unsigned int)1, word.senses.count, @"expected 1 sense, got %lu", (unsigned long)word.senses.count);
    
    DubsarModelsSense* sense = (word.senses)[0];
    
    XCTAssertEqual(35629, sense._id, @"expected 35629, found %lu", (unsigned long)word._id);
    XCTAssertEqualObjects(@"nutrient", sense.synonymsAsString, @"expected \"nutrient\", found \"%@\"", sense.synonymsAsString);
    XCTAssertEqualObjects(@"any substance that can be metabolized by an animal to give energy and build tissue  ", sense.gloss, @"gloss failure");
    XCTAssertEqualObjects(@"noun.Tops", sense.lexname, @"expected \"noun.Tops\", found \"%@\"", sense.lexname);
    XCTAssertNil(sense.marker, @"expected nil sense marker, found non-nil");
    XCTAssertEqual(29, sense.freqCnt, @"expected 29, found %d", sense.freqCnt);
    XCTAssertEqual(29, word.freqCnt, @"expected 29, found %lu", (unsigned long)word.freqCnt);
}

-(void)testInitialization
{
    DubsarModelsWord* a = [[DubsarModelsWord alloc]init];
    XCTAssertTrue(!a.complete, @"complete failed");
    XCTAssertTrue(!a.error, @"error failed");
}
                         
@end
