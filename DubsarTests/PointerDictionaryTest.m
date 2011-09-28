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

#import "PointerDictionary.h"
#import "PointerDictionaryTest.h"

@implementation PointerDictionaryTest

/* From the Rails server (Pointer model):
 'antonym' => 'words opposite in meaning',
 'hypernym' => 'more generic terms',
 'instance hypernym' => 'classes of which this is an instance',
 'hyponym' => 'more specific terms',
 'instance hyponym' => 'instances of this class',
 'member holonym' => 'wholes of which this is a member',
 'substance holonym' => 'wholes of which this is an ingredient',
 'part holonym' => 'wholes of which this is a part',
 'member meronym' => 'constituent members',
 'substance meronym' => 'constituent substances',
 'part meronym' => 'constituent parts',
 'attribute' => 'general quality',
 'derivationally related form' => 'cognates, etc.',
 'domain of synset (topic)' => 'related topics',
 'member of this domain (topic)' => 'entries under this topic',
 'domain of synset (region)' => 'relevant region',
 'member of this domain (region)' => 'things relevant to this region',
 'domain of synset (usage)' => 'pertinent to usage',
 'member of this domain (usage)' => 'relevant by usage',
 'entailment' => 'consequence',
 'cause' => 'origin or reason',
 'also see' => 'related entries',
 'verb group' => 'related verbs',
 'similar to' => 'near in meaning, but not exact',
 'participle of verb' => 'root verb',
 'derived from/pertains to' => 'adj: pertinent noun; adv: source noun'
 
 */

- (void)testHelp
{
    PointerDictionary* dictionary = [PointerDictionary instance];
    
    STAssertNotNil(dictionary, @"PointerDictionary should not be nil");
    STAssertNotNil(dictionary.helpDictionary, @"help dictionary should not be nil");
    
    STAssertEquals((unsigned int)30, dictionary.helpDictionary.count, @"expected 29 entries in help dictionary, found %d", dictionary.helpDictionary.count);
    
    [self singleHelpCase:@"antonym" expected:@"words opposite in meaning"];
    [self singleHelpCase:@"hypernym" expected:@"more generic terms"];
    [self singleHelpCase:@"instance hypernym" expected:@"classes of which this is an instance"];
    [self singleHelpCase:@"hyponym" expected:@"more specific terms"];
    [self singleHelpCase:@"instance hyponym" expected:@"instance of this class"];
    [self singleHelpCase:@"member holonym" expected:@"wholes of which this is a member"];
    [self singleHelpCase:@"substance holonym" expected:@"wholes of which this is an ingredient"];
    [self singleHelpCase:@"part holonym" expected:@"wholes of which this is a part"];
    [self singleHelpCase:@"member meronym" expected:@"constituent members"];
    [self singleHelpCase:@"substance meronym" expected:@"constituent substances"];
    [self singleHelpCase:@"part meronym" expected:@"constituent parts"];
    [self singleHelpCase:@"attribute" expected:@"general quality"];
    [self singleHelpCase:@"derivationally related form" expected:@"cognates, etc."];
    [self singleHelpCase:@"domain of synset (topic)" expected:@"related topics"];
    [self singleHelpCase:@"member of this domain (topic)" expected:@"entries under this topic"];
    [self singleHelpCase:@"domain of synset (region)" expected:@"relevant region"];
    [self singleHelpCase:@"member of this domain (region)" expected:@"things relevant to this region"];
    [self singleHelpCase:@"domain of synset (usage)" expected:@"pertinent to usage"];
    [self singleHelpCase:@"member of this domain (usage)" expected:@"relevant by usage"];
    [self singleHelpCase:@"entailment" expected:@"consequence"];
    [self singleHelpCase:@"cause" expected:@"origin or reason"];
    [self singleHelpCase:@"also see" expected:@"related entries"];
    [self singleHelpCase:@"verb group" expected:@"related verbs"];
    [self singleHelpCase:@"similar to" expected:@"near in meaning, but not exact"];
    [self singleHelpCase:@"participle of verb" expected:@"root verb"];
    [self singleHelpCase:@"derived from/pertains to" expected:@"adj: pertinent noun; adv: source noun"];
    [self singleHelpCase:@"synonym" expected:@"words that share this meaning"];
    [self singleHelpCase:@"sample sentence" expected:@"examples of usage for this word and synonyms"];
    [self singleHelpCase:@"synset sample" expected:@"examples of usage"];
    [self singleHelpCase:@"verb frame" expected:@"generic templates for this verb sense"];
}

- (void)testTitles
{
    PointerDictionary* dictionary = [PointerDictionary instance];
    
    STAssertNotNil(dictionary, @"PointerDictionary should not be nil");
    STAssertNotNil(dictionary.titleDictionary, @"title dictionary should not be nil");
    
    STAssertEquals((unsigned int)30, dictionary.titleDictionary.count, @"expected 29 entries in title dictionary, found %d", dictionary.titleDictionary.count);
    
    [self singleTitleCase:@"antonym" expected:@"Antonyms"];
    [self singleTitleCase:@"hypernym" expected:@"Hypernyms"];
    [self singleTitleCase:@"instance hypernym" expected:@"Instance Hypernyms"];
    [self singleTitleCase:@"hyponym" expected:@"Hyponyms"];
    [self singleTitleCase:@"instance hyponym" expected:@"Instance Hyponyms"];
    [self singleTitleCase:@"member holonym" expected:@"Member Holonyms"];
    [self singleTitleCase:@"substance holonym" expected:@"Substance Holonyms"];
    [self singleTitleCase:@"part holonym" expected:@"Part Holonyms"];
    [self singleTitleCase:@"member meronym" expected:@"Member Meronyms"];
    [self singleTitleCase:@"substance meronym" expected:@"Substance Meronyms"];
    [self singleTitleCase:@"part meronym" expected:@"Part Meronyms"];
    [self singleTitleCase:@"attribute" expected:@"Attributes"];
    [self singleTitleCase:@"derivationally related form" expected:@"Derivationally Related Forms"];
    [self singleTitleCase:@"domain of synset (topic)" expected:@"Domain of Synset (Topic)"];
    [self singleTitleCase:@"member of this domain (topic)" expected:@"Members of this Domain (Topic)"];
    [self singleTitleCase:@"domain of synset (region)" expected:@"Domain of Synset (Region)"];
    [self singleTitleCase:@"member of this domain (region)" expected:@"Members of this Domain (Region)"];
    [self singleTitleCase:@"domain of synset (usage)" expected:@"Domain of Synset (Usage)"];
    [self singleTitleCase:@"member of this domain (usage)" expected:@"Members of this Domain (Usage)"];
    [self singleTitleCase:@"entailment" expected:@"Entailments"];
    [self singleTitleCase:@"cause" expected:@"Causes"];
    [self singleTitleCase:@"also see" expected:@"Also See"];
    [self singleTitleCase:@"verb group" expected:@"Verb Group"];
    [self singleTitleCase:@"similar to" expected:@"Similar To"];
    [self singleTitleCase:@"participle of verb" expected:@"Participle of Verb"];
    [self singleTitleCase:@"derived from/pertains to" expected:@"Derived From/Pertains To"];
    [self singleTitleCase:@"synonym" expected:@"Synonyms"];
    [self singleTitleCase:@"sample sentence" expected:@"Sample Sentences"];
    [self singleTitleCase:@"synset sample" expected:@"Sample Sentences"];
    [self singleTitleCase:@"verb frame" expected:@"Verb Frames"];
}

- (void)singleHelpCase:(NSString *)ptype expected:(NSString *)expected
{
    NSString* help = [PointerDictionary helpWithPointerType:ptype];
    STAssertTrue([help isEqualToString:expected], @"expected help text for \"%@\" to be \"%@\", found \"%@\"", ptype, expected, help);
}

- (void)singleTitleCase:(NSString *)ptype expected:(NSString *)expected
{
    NSString* title = [PointerDictionary titleWithPointerType:ptype];
    STAssertTrue([title isEqualToString:expected], @"expected title text for \"%@\" to be \"%@\", found \"%@\"", ptype, expected, title);    
}

@end
