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

#import "Synset.h"
#import "SynsetTest.h"

@implementation SynsetTest

- (void)testParsing
{
    NSString* stringData = @"[21803,\"n\",\"noun.Tops\",\"synset gloss\",[],[[35629,\"food\",null,29],[35630,\"nutrient\",null,1]],30,[[\"hypernym\",\"synset\",21801,\"substance\",\"hypernym gloss\"]]]";
    
    Synset* synset = [Synset synsetWithId:21803 gloss:@"synset gloss" partOfSpeech:POSNoun];
    synset.data = [self.class dataWithString:stringData];
    [synset parseData];
    
    STAssertEqualObjects(@"noun.Tops", synset.lexname, @"lexname failed");
    STAssertNotNil(synset.samples, @"samples failed");
    STAssertEquals((unsigned int)0, synset.samples.count, @"samples count failed");
    STAssertEquals((unsigned int)2, synset.senses.count, @"senses count failed");
    STAssertEquals(30, synset.freqCnt, @"frequency count failed");
    STAssertEquals((unsigned int)1, synset.pointers.count, @"pointers count failed");
}

@end
