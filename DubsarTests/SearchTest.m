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

#import "SearchTest.h"

@implementation SearchTest

/*
-(void)testParsing
{
    NSString* stringData = @"[\"food\",[[26063,\"food\",\"n\",29,\"foods\"]],1]";

    Search* search = [Search searchWithTerm:@"food" matchCase:NO];
    search.data = [self.class dataWithString:stringData];
    [search parseData];

    XCTAssertEquals(1, search.totalPages, @"total pages failed");
    
    NSArray* results = search.results;
    Word* word = [results objectAtIndex:0];
    
    XCTAssertEquals((unsigned int)1, results.count, @"results count failed");
    XCTAssertEquals(26063, word._id, @"word ID failed");
    XCTAssertEqualObjects(@"food", word.name, @"word name failed");
    XCTAssertEquals(POSNoun, word.partOfSpeech, @"word part of speech failed");
    XCTAssertEquals(29, word.freqCnt, @"word frequency count failed");
    XCTAssertNotNil(word.inflections, @"word inflections failed");
    XCTAssertEqualObjects(@"foods", word.inflections, @"word inflection content failed");
}
 */

-(void)testExactInflectionMatch
{
    Search* search = [Search searchWithTerm:@"recommended" matchCase:NO];
    [search loadResults:self.database];
    
    NSLog(@"search for recommended returned %d results", search.results.count);
    // XCTAssertEquals((unsigned int)1, search.results.count, @"search count failed");
}

-(void)testInitialization
{
    Search* a = [[Search alloc]init];
    XCTAssertTrue(!a.complete, @"complete failed");
    XCTAssertTrue(!a.error, @"error failed");
}

@end
