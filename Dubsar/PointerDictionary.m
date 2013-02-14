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

#import "PointerDictionary.h"

static PointerDictionary* theDictionary = nil;

@implementation PointerDictionary

@synthesize helpDictionary;
@synthesize titleDictionary;

+ (NSString*)helpWithPointerType:(NSString *)ptype
{
    return [[PointerDictionary instance]helpWithPointerType:ptype];
}

+ (NSString*)titleWithPointerType:(NSString *)ptype
{
    return [[PointerDictionary instance]titleWithPointerType:ptype];
}

+ (PointerDictionary*)instance
{
    if (theDictionary == nil) {
        theDictionary = [[PointerDictionary alloc]init];
    }
    return theDictionary;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupHelpDictionary];
        [self setupTitleDictionary];
    }
    return self;
}

- (void)dealloc
{
    [helpDictionary release];
    [titleDictionary release];
    [super dealloc];
}

- (NSString*)helpWithPointerType:(NSString *)ptype
{
    return [helpDictionary valueForKey:ptype];
}

- (NSString*)titleWithPointerType:(NSString *)ptype
{
    return [titleDictionary valueForKey:ptype];
}

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

- (void)setupHelpDictionary
{
    helpDictionary = [[NSMutableDictionary alloc]init];
    [helpDictionary setValue:@"words opposite in meaning" forKey:@"antonym"];
    [helpDictionary setValue:@"more generic terms" forKey:@"hypernym"];
    [helpDictionary setValue:@"classes of which this is an instance" forKey:@"instance hypernym"];
    [helpDictionary setValue:@"more specific terms" forKey:@"hyponym"];
    [helpDictionary setValue:@"instances of this class" forKey:@"instance hyponym"];
    [helpDictionary setValue:@"wholes of which this is a member" forKey:@"member holonym"];
    [helpDictionary setValue:@"wholes of which this is an ingredient" forKey:@"substance holonym"];
    [helpDictionary setValue:@"wholes of which this is a part" forKey:@"part holonym"];
    [helpDictionary setValue:@"constituent members" forKey:@"member meronym"];
    [helpDictionary setValue:@"constituent substances" forKey:@"substance meronym"];
    [helpDictionary setValue:@"constituent parts" forKey:@"part meronym"];
    [helpDictionary setValue:@"general qualities" forKey:@"attribute"];
    [helpDictionary setValue:@"cognates, etc." forKey:@"derivationally related form"];
    [helpDictionary setValue:@"related topics" forKey:@"domain of synset (topic)"];
    [helpDictionary setValue:@"entries under this topic" forKey:@"member of this domain (topic)"];
    [helpDictionary setValue:@"relevant regions" forKey:@"domain of synset (region)"];
    [helpDictionary setValue:@"things relevant to this region" forKey:@"member of this domain (region)"];
    [helpDictionary setValue:@"pertinent to usage" forKey:@"domain of synset (usage)"];
    [helpDictionary setValue:@"relevant by usage" forKey:@"member of this domain (usage)"];
    [helpDictionary setValue:@"consequences" forKey:@"entailment"];
    [helpDictionary setValue:@"origins or reasons" forKey:@"cause"];
    [helpDictionary setValue:@"related entries" forKey:@"also see"];
    [helpDictionary setValue:@"related verbs" forKey:@"verb group"];
    [helpDictionary setValue:@"near in meaning, but not exact" forKey:@"similar to"];
    [helpDictionary setValue:@"root verb" forKey:@"participle of verb"];
    [helpDictionary setValue:@"source/pertinent word" forKey:@"derived from/pertains to"];
    [helpDictionary setValue:@"words that share this meaning" forKey:@"synonym"];
    [helpDictionary setValue:@"examples of usage for this word and synonyms" forKey:@"sample sentence"];
    [helpDictionary setValue:@"examples of usage" forKey:@"synset sample"];
    [helpDictionary setValue:@"generic templates for this verb sense" forKey:@"verb frame"];
}

- (void)setupTitleDictionary
{
    titleDictionary = [[NSMutableDictionary alloc]init];
    [titleDictionary setValue:@"Antonyms" forKey:@"antonym"];
    [titleDictionary setValue:@"Hypernyms" forKey:@"hypernym"];
    [titleDictionary setValue:@"Instance Hypernyms" forKey:@"instance hypernym"];
    [titleDictionary setValue:@"Hyponyms" forKey:@"hyponym"];
    [titleDictionary setValue:@"Instance Hyponyms" forKey:@"instance hyponym"];
    [titleDictionary setValue:@"Member Holonyms" forKey:@"member holonym"];
    [titleDictionary setValue:@"Substance Holonyms" forKey:@"substance holonym"];
    [titleDictionary setValue:@"Part Holonyms" forKey:@"part holonym"];
    [titleDictionary setValue:@"Member Meronyms" forKey:@"member meronym"];
    [titleDictionary setValue:@"Substance Meronyms" forKey:@"substance meronym"];
    [titleDictionary setValue:@"Part Meronyms" forKey:@"part meronym"];
    [titleDictionary setValue:@"Attributes" forKey:@"attribute"];
    [titleDictionary setValue:@"Derivationally Related Forms" forKey:@"derivationally related form"];
    [titleDictionary setValue:@"Domain of Synset (Topic)" forKey:@"domain of synset (topic)"];
    [titleDictionary setValue:@"Members of this Domain (Topic)" forKey:@"member of this domain (topic)"];
    [titleDictionary setValue:@"Domain of Synset (Region)" forKey:@"domain of synset (region)"];
    [titleDictionary setValue:@"Members of this Domain (Region)" forKey:@"member of this domain (region)"];
    [titleDictionary setValue:@"Domain of Synset (Usage)" forKey:@"domain of synset (usage)"];
    [titleDictionary setValue:@"Members of this Domain (Usage)" forKey:@"member of this domain (usage)"];
    [titleDictionary setValue:@"Entailments" forKey:@"entailment"];
    [titleDictionary setValue:@"Causes" forKey:@"cause"];
    [titleDictionary setValue:@"Also See" forKey:@"also see"];
    [titleDictionary setValue:@"Verb Group" forKey:@"verb group"];
    [titleDictionary setValue:@"Similar To" forKey:@"similar to"];
    [titleDictionary setValue:@"Participle of Verb" forKey:@"participle of verb"];
    [titleDictionary setValue:@"Derived From/Pertains To" forKey:@"derived from/pertains to"];
    [titleDictionary setValue:@"Synonyms" forKey:@"synonym"];
    [titleDictionary setValue:@"Sample Sentences" forKey:@"sample sentence"];
    [titleDictionary setValue:@"Sample Sentences" forKey:@"synset sample"];
    [titleDictionary setValue:@"Verb Frames" forKey:@"verb frame"];
}

@end
