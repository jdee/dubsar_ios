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

#import "Sense.h"
#import "SenseTest.h"
#import "Synset.h"
#import "Word.h"

@implementation SenseTest

- (void)testParsing
{
    NSString* stringData = @"[35629,[26063,\"food\",\"n\"],[21803,\"sense gloss\"],\"noun.Tops\",null,29,[[35630,\"nutrient\",null,1]],[],[],[[\"hypernym\",\"synset\",21801,\"substance\",\"hypernym gloss\"]]]";
    
    /* This resembles the way senses are parsed in word responses. */
    Word* word = [Word wordWithId:26063 name:@"food" partOfSpeech:POSNoun];

    Sense* synSense = [Sense senseWithId:35630 name:@"nutrient" partOfSpeech:POSNoun];
    NSMutableArray* synonyms = [NSMutableArray arrayWithObject:synSense];
    
    Sense* sense =[Sense senseWithId:35629 gloss:@"sense gloss" synonyms:synonyms word:word]; 
    sense.data = [self.class dataWithString:stringData];
    NSLog(@"sense.data: %u bytes", sense.data.length);
    [sense parseData];
    
    // word
    STAssertEquals(26063, sense.word._id, @"word ID failed");
    STAssertEqualObjects(@"food", sense.word.name, @"word name failed");
    STAssertEquals(POSNoun, sense.word.partOfSpeech, @"word partOfSpeech failed");

    // synset
    STAssertEquals(21803, sense.synset._id, @"synset ID failed");
    STAssertEqualObjects(@"sense gloss", sense.synset.gloss, @"synset gloss failed");

    // sense
    STAssertEqualObjects(@"noun.Tops", sense.lexname, @"lexname failed");
    STAssertNil(sense.marker, @"marker failed");
    STAssertEquals(29, sense.freqCnt, @"frequency count failed");

    // synonyms
    STAssertNotNil(sense.synonyms, @"synonyms failed");
    STAssertEquals((unsigned int)1, sense.synonyms.count, @"synonym count failed");
    
    synSense = [sense.synonyms objectAtIndex:0];
    STAssertEquals(35630, synSense._id, @"synonym ID failed");
    STAssertEqualObjects(@"nutrient", synSense.name, @"synonym name failed");
    STAssertNil(synSense.marker, @"synonym marker failed");
    STAssertEquals(1, synSense.freqCnt, @"synonym frequency count failed");

    // samples, verb frames
    STAssertNotNil(sense.samples, @"samples failed");
    STAssertEquals(sense.samples.count, (unsigned int)0, @"samples count failed");
    STAssertNotNil(sense.verbFrames, @"verb frames failed");
    STAssertEquals(sense.verbFrames.count, (unsigned int)0, @"verb frames count failed");
    
    // pointers
    NSDictionary* pointers = sense.pointers;    
    STAssertEquals((unsigned int)1, pointers.count, @"pointer count failed");
    NSArray* _pointers = [pointers valueForKey:@"hypernym"];
    STAssertNotNil(_pointers, @"pointers failed");
    STAssertEquals((unsigned int)1, _pointers.count, @"pointers count failed");
    
    NSArray* _pointer = [_pointers objectAtIndex:0];

    NSNumber* numericID = [_pointer objectAtIndex:1];
    
    STAssertEqualObjects(@"synset", [_pointer objectAtIndex:0], @"hypernym target type failed");
    STAssertEquals(21801, numericID.intValue, @"hypernym ID failed");
    STAssertEqualObjects(@"substance", [_pointer objectAtIndex:2], @"hypernym text failed");
    STAssertEqualObjects(@"hypernym gloss", [_pointer objectAtIndex:3], @"hypernym gloss failed");
}

@end
