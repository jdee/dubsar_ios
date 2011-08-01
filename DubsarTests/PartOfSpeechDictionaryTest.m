//
//  PartOfSpeechDictionaryTest.m
//  Dubsar
//
//  Created by Jimmy Dee on 8/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PartOfSpeechDictionary.h"
#import "PartOfSpeechDictionaryTest.h"

@implementation PartOfSpeechDictionaryTest

- (void)testMapping 
{
    PartOfSpeechDictionary* dictionary = [PartOfSpeechDictionary instance];
    
    STAssertNotNil(dictionary, @"PartOfSpeechDictionary should not be nil");
    STAssertNotNil(dictionary.dictionary, @"NSDictionary should not be nil");
    
    STAssertTrue(8 == dictionary.dictionary.count, @"expected dictionary to have 8 entries, found %d", dictionary.dictionary.count);
    
    PartOfSpeech partOfSpeech;
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"adj"];
    STAssertEquals(POSAdjective, partOfSpeech, @"expected POSAdjective, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"adv"];
    STAssertEquals(POSAdverb, partOfSpeech, @"expected POSAdverb, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"conj"];
    STAssertEquals(POSConjunction, partOfSpeech, @"expected POSConjunction, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"interj"];
    STAssertEquals(POSInterjection, partOfSpeech, @"expected POSInterjection, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"n"];
    STAssertEquals(POSNoun, partOfSpeech, @"expected POSNoun, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"prep"];
    STAssertEquals(POSPreposition, partOfSpeech, @"expected POSPreposition, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"pron"];
    STAssertEquals(POSPronoun, partOfSpeech, @"expected POSPronoun, found %d", partOfSpeech);
    
    partOfSpeech = [dictionary partOfSpeechFromPOS:@"v"];
    STAssertEquals(POSVerb, partOfSpeech, @"expected POSVerb, found %d", partOfSpeech);
}

- (void)testReverseMapping
{
    PartOfSpeechDictionary* dictionary = [PartOfSpeechDictionary instance];
    
    NSString* pos;
    
    pos = [dictionary posFromPartOfSpeech:POSAdjective];
    STAssertTrue([pos isEqualToString:@"adj"], @"expected pos \"adj\" for adjective, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:POSAdverb];
    STAssertTrue([pos isEqualToString:@"adv"], @"expected pos \"adv\" for adverb, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:POSConjunction];
    STAssertTrue([pos isEqualToString:@"conj"], @"expected pos \"conj\" for conjunction, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:POSInterjection];
    STAssertTrue([pos isEqualToString:@"interj"], @"expected pos \"interj\" for interjection, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:POSNoun];
    STAssertTrue([pos isEqualToString:@"n"], @"expected pos \"n\" for noun, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:POSPreposition];
    STAssertTrue([pos isEqualToString:@"prep"], @"expected pos \"prep\" for preposition, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:POSPronoun];
    STAssertTrue([pos isEqualToString:@"pron"], @"expected pos \"pron\" for pronoun, found \"%@\"", pos);
    
    pos = [dictionary posFromPartOfSpeech:POSVerb];
    STAssertTrue([pos isEqualToString:@"v"], @"expected pos \"v\" for verb, found \"%@\"", pos);
}

@end
