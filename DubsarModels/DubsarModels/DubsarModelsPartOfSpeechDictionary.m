/*
 Dubsar Dictionary Project
 Copyright (C) 2010-14 Jimmy Dee
 
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

#import "DubsarModels.h"
#import "DubsarModelsPartOfSpeechDictionary.h"

static DubsarModelsPartOfSpeechDictionary* theInstance=nil;

@implementation DubsarModelsPartOfSpeechDictionary
@synthesize dictionary;

+(DubsarModelsPartOfSpeech)partOfSpeechFromPOS:(NSString *)pos
{
    DubsarModelsPartOfSpeechDictionary* instance = [self instance];
    return [instance partOfSpeechFromPOS:pos];
}

+(DubsarModelsPartOfSpeech)partOfSpeechFrom_part_of_speech:(char const *)part_of_speech
{
    DubsarModelsPartOfSpeechDictionary* instance = [self instance];
    return [instance partOfSpeechFrom_part_of_speech:part_of_speech];
}

+(NSString*)posFromPartOfSpeech:(DubsarModelsPartOfSpeech)partOfSpeech
{
    DubsarModelsPartOfSpeechDictionary* instance = [self instance];
    return [instance posFromPartOfSpeech:partOfSpeech];
}

+(DubsarModelsPartOfSpeechDictionary*)instance
{
    if (theInstance == nil) {
        theInstance = [[DubsarModelsPartOfSpeechDictionary alloc]init];
    }
    return theInstance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self setupDictionary];
    }
    return self;
}

-(NSString*)posFromPartOfSpeech:(DubsarModelsPartOfSpeech)partOfSpeech
{
    switch (partOfSpeech) {
        case DubsarModelsPartOfSpeechAdjective:
            return @"adj";
        case DubsarModelsPartOfSpeechAdverb:
            return @"adv";
        case DubsarModelsPartOfSpeechConjunction:
            return @"conj";
        case DubsarModelsPartOfSpeechInterjection:
            return @"interj";
        case DubsarModelsPartOfSpeechNoun:
            return @"n";
        case DubsarModelsPartOfSpeechPreposition:
            return @"prep";
        case DubsarModelsPartOfSpeechPronoun:
            return @"pron";
        case DubsarModelsPartOfSpeechVerb:
            return @"v";
        default:
            return @"<unknown>";
    }
}

-(DubsarModelsPartOfSpeech)partOfSpeechFromPOS:(NSString*)pos
{
    NSNumber* number = [dictionary valueForKey:pos];
    return number.intValue;
}

-(DubsarModelsPartOfSpeech)partOfSpeechFrom_part_of_speech:(char const *)part_of_speech
{
    NSString* key = @(part_of_speech);
    NSNumber* number = [verboseDictionary valueForKey:key];
    return number.intValue;
}

-(void)setupDictionary
{
    DMLOG(@"%@", @"setting up part of speech dictionary");
    dictionary = [[NSMutableDictionary alloc]init];
    verboseDictionary = [[NSMutableDictionary alloc]init];

    [self setValue:DubsarModelsPartOfSpeechAdjective forKey:@"adj"];
    [self setValue:DubsarModelsPartOfSpeechAdverb forKey:@"adv"];
    [self setValue:DubsarModelsPartOfSpeechConjunction forKey:@"conj"];
    [self setValue:DubsarModelsPartOfSpeechInterjection forKey:@"interj"];
    [self setValue:DubsarModelsPartOfSpeechNoun forKey:@"n"];
    [self setValue:DubsarModelsPartOfSpeechPreposition forKey:@"prep"];
    [self setValue:DubsarModelsPartOfSpeechPronoun forKey:@"pron"];
    [self setValue:DubsarModelsPartOfSpeechVerb forKey:@"v"];
    
    [self setVerboseValue:DubsarModelsPartOfSpeechAdjective forKey:@"adjective"];
    [self setVerboseValue:DubsarModelsPartOfSpeechAdverb forKey:@"adverb"];
    [self setVerboseValue:DubsarModelsPartOfSpeechConjunction forKey:@"conjunction"];
    [self setVerboseValue:DubsarModelsPartOfSpeechInterjection forKey:@"interjection"];
    [self setVerboseValue:DubsarModelsPartOfSpeechNoun forKey:@"noun"];
    [self setVerboseValue:DubsarModelsPartOfSpeechPreposition forKey:@"preposition"];
    [self setVerboseValue:DubsarModelsPartOfSpeechPronoun forKey:@"pronoun"];
    [self setVerboseValue:DubsarModelsPartOfSpeechVerb forKey:@"verb"];
}

-(void)setValue:(DubsarModelsPartOfSpeech)partOfSpeech forKey:(NSString *)pos
{
    NSNumber* number = [NSNumber numberWithInt:partOfSpeech];
    [dictionary setValue:number forKey:pos];
}

-(void)setVerboseValue:(DubsarModelsPartOfSpeech)partOfSpeech forKey:(NSString *)part_of_speech
{
    NSNumber* number = [NSNumber numberWithInt:partOfSpeech];
    [verboseDictionary setValue:number forKey:part_of_speech];
}

@end
