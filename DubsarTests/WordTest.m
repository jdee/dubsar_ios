//
//  WordTest.m
//  Dubsar
//
//  Created by Jimmy Dee on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Sense.h"
#import "Word.h"
#import "WordTest.h"

@implementation WordTest

- (void)testParsing
{
    NSString* stringData = @"[26063,\"food\",\"n\",\"foods\",[[35629,[[35630,\"nutrient\"]],\"any substance that can be metabolized by an animal to give energy and build tissue  \",\"noun.Tops\",null,29]],29]";
    
    Word* word =[Word wordWithId:26063 name:@"food" partOfSpeech:POSNoun]; 
    word.data = [self.class dataWithString:stringData];
    [word parseData];
        
    STAssertEquals((unsigned int)1, word.senses.count, @"expected 1 sense, got %u", word.senses.count);
    
    Sense* sense = [word.senses objectAtIndex:0];
    
    STAssertEquals(35629, sense._id, @"expected 35629, found %d", word._id);
    STAssertEqualObjects(@"nutrient", sense.synonymsAsString, @"expected \"nutrient\", found \"%@\"", sense.synonymsAsString);
    STAssertEqualObjects(@"any substance that can be metabolized by an animal to give energy and build tissue  ", sense.gloss, @"gloss failure");
    STAssertEqualObjects(@"noun.Tops", sense.lexname, @"expected \"noun.Tops\", found \"%@\"", sense.lexname);
    STAssertNil(sense.marker, @"expected nil sense marker, found non-nil");
    STAssertEquals(29, sense.freqCnt, @"expected 29, found %d", sense.freqCnt);
    STAssertEquals(29, word.freqCnt, @"expected 29, found %d", word.freqCnt);
}
                         
@end
