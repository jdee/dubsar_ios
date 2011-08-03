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
#import "Search.h"
#import "SearchTest.h"
#import "Word.h"

@implementation SearchTest


-(void)testParsing
{
    NSString* stringData = @"[\"food\",[[26063,\"food\",\"n\"]]]";

    Search* search = [Search searchWithTerm:@"food" matchCase:NO];
    search.data = [self.class dataWithString:stringData];
    [search parseData];
    
    NSArray* results = search.results;
    Word* word = [results objectAtIndex:0];
    
    STAssertEquals((unsigned int)1, results.count, @"expected 1 search result, got %u", results.count);
    STAssertEquals(26063, word._id, @"expected 26063, found %d", word._id);
    STAssertEqualObjects(@"food", word.name, @"expected \"food\", found \"%@\"", word.name);
    STAssertEquals(POSNoun, word.partOfSpeech, @"expected n, found %@", [PartOfSpeechDictionary posFromPartOfSpeech:word.partOfSpeech]);
}

@end
