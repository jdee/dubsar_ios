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

#import "Autocompleter.h"
#import "AutocompleterTest.h"


@implementation AutocompleterTest

-(void)testParsing
{
    NSString* stringData = @"[ \"li\", [ \"like\", \"link\", \"lion\" ] ]";
    NSRange range;
    range.location = 0;
    range.length = stringData.length;
    
    NSUInteger length;
    unsigned char buffer[256];
    
    [stringData getBytes:buffer maxLength:256 usedLength:&length encoding:NSUTF8StringEncoding options:0 range:range remainingRange:NULL];
    
    NSMutableData* data = [NSData dataWithBytes:buffer length:length];
    
    Autocompleter* autocompleter = [Autocompleter autocompleterWithTerm:@"li" matchCase:NO];
    autocompleter.data = data;
    [autocompleter parseData];
    
    STAssertEqual(3, autocompleter.results.count, @"expected 3 autocompleter results, got %u", autocompleter.results.count);
}

@end
