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

#import "DailyWord.h"
#import "DailyWordTest.h"
#import "Word.h"

@implementation DailyWordTest

-(void)testParsing
{
    NSString* stringData = @"[147806,\"decelerate\",\"v\",1,\"decelerated, decelerates, decelerating\"]";
    
    DailyWord* dailyWord = [[[DailyWord alloc]init]autorelease];
    dailyWord.data = [self.class dataWithString:stringData];
    [dailyWord parseData];
    
    Word* word = dailyWord.word;
    STAssertNotNil(word, @"word failed");
    STAssertEquals(147806, word._id, @"word ID failed");
    STAssertEqualObjects(@"decelerate", word.name, @"word name failed");
    STAssertEquals(POSVerb, word.partOfSpeech, @"word part of speech failed");
    STAssertEquals(1, word.freqCnt, @"word frequency count failed");
    STAssertEqualObjects(@"decelerated, decelerates, decelerating", word.inflections, @"word inflections failed");
}

-(void)testInitialization
{
    DailyWord* a = [[[DailyWord alloc]init]autorelease];
    STAssertTrue(!a.complete, @"complete failed");
    STAssertTrue(!a.error, @"error failed");
}

@end
