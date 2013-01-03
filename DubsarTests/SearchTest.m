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

#import "PartOfSpeechDictionary.h"
#import "Search.h"
#import "SearchTest.h"
#import "Word.h"

@implementation SearchTest

/*
-(void)testParsing
{
    NSString* stringData = @"[\"food\",[[26063,\"food\",\"n\",29,\"foods\"]],1]";

    Search* search = [Search searchWithTerm:@"food" matchCase:NO];
    search.data = [self.class dataWithString:stringData];
    [search parseData];

    STAssertEquals(1, search.totalPages, @"total pages failed");
    
    NSArray* results = search.results;
    Word* word = [results objectAtIndex:0];
    
    STAssertEquals((unsigned int)1, results.count, @"results count failed");
    STAssertEquals(26063, word._id, @"word ID failed");
    STAssertEqualObjects(@"food", word.name, @"word name failed");
    STAssertEquals(POSNoun, word.partOfSpeech, @"word part of speech failed");
    STAssertEquals(29, word.freqCnt, @"word frequency count failed");
    STAssertNotNil(word.inflections, @"word inflections failed");
    STAssertEqualObjects(@"foods", word.inflections, @"word inflection content failed");
}
 */

-(void)testExactInflectionMatch
{
    Search* search = [Search searchWithTerm:@"recommended" matchCase:NO];
    [search loadResults:self.appDelegate];
    
    NSLog(@"search for recommended returned %d results", search.results.count);
    // STAssertEquals((unsigned int)1, search.results.count, @"search count failed");
}

-(void)testInitialization
{
    Search* a = [[[Search alloc]init]autorelease];
    STAssertTrue(!a.complete, @"complete failed");
    STAssertTrue(!a.error, @"error failed");
}

@end
