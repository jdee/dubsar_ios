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

#import "AutocompleterTest.h"

@implementation AutocompleterTest

-(void)testParsing
{
    NSString* stringData = @"[ \"li\", [ \"like\", \"link\", \"lion\" ] ]";
    
    DubsarModelsAutocompleter* autocompleter = [DubsarModelsAutocompleter autocompleterWithTerm:@"li" matchCase:NO];
    autocompleter.data = [self.class dataWithString:stringData];
    [autocompleter parseData];
    
    NSArray* results = autocompleter.results;
    XCTAssertEqual((unsigned int)3, results.count, @"expected 3 autocompleter results, got %u", results.count);
    XCTAssertEqualObjects(@"like", [results objectAtIndex:0], @"expected \"like\", found \"%@\"", [results objectAtIndex:0]);
    XCTAssertEqualObjects(@"link", [results objectAtIndex:1], @"expected \"link\", found \"%@\"", [results objectAtIndex:1]);
    XCTAssertEqualObjects(@"lion", [results objectAtIndex:2], @"expected \"lion\", found \"%@\"", [results objectAtIndex:2]);
}

-(void)testInitialization
{
    DubsarModelsAutocompleter* a = [[DubsarModelsAutocompleter alloc]init];
    XCTAssertTrue(!a.complete, @"complete failed");
    XCTAssertTrue(!a.error, @"error failed");
}

@end
