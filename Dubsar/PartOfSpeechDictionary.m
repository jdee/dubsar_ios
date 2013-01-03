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

#import "PartOfSpeechDictionary.h"

static PartOfSpeechDictionary* theInstance=nil;

@implementation PartOfSpeechDictionary
@synthesize dictionary;

+(PartOfSpeech)partOfSpeechFromPOS:(NSString *)pos
{
    PartOfSpeechDictionary* instance = [self instance];
    return [instance partOfSpeechFromPOS:pos];
}

+(PartOfSpeech)partOfSpeechFrom_part_of_speech:(char const *)part_of_speech
{
    PartOfSpeechDictionary* instance = [self instance];
    return [instance partOfSpeechFrom_part_of_speech:part_of_speech];
}

+(NSString*)posFromPartOfSpeech:(PartOfSpeech)partOfSpeech
{
    PartOfSpeechDictionary* instance = [self instance];
    return [instance posFromPartOfSpeech:partOfSpeech];
}

+(PartOfSpeechDictionary*)instance
{
    if (theInstance == nil) {
        theInstance = [[PartOfSpeechDictionary alloc]init];
    }
    return theInstance;
}

-(id)init
{
    self = [super init];
    if (self) {
        [self setupDictionary];
    }
    return self;
}

-(void)dealloc
{
    [dictionary release];
    [super dealloc];
}

-(NSString*)posFromPartOfSpeech:(PartOfSpeech)partOfSpeech
{
    switch (partOfSpeech) {
        case POSAdjective:
            return @"adj";
        case POSAdverb:
            return @"adv";
        case POSConjunction:
            return @"conj";
        case POSInterjection:
            return @"interj";
        case POSNoun:
            return @"n";
        case POSPreposition:
            return @"prep";
        case POSPronoun:
            return @"pron";
        case POSVerb:
            return @"v";
        default:
            return @"<unknown>";
    }
}

-(PartOfSpeech)partOfSpeechFromPOS:(NSString*)pos
{
    NSNumber* number = [dictionary valueForKey:pos];
    return number.intValue;
}

-(PartOfSpeech)partOfSpeechFrom_part_of_speech:(char const *)part_of_speech
{
    NSString* key = [NSString stringWithCString:part_of_speech encoding:NSUTF8StringEncoding];
    NSNumber* number = [verboseDictionary valueForKey:key];
    return number.intValue;
}

-(void)setupDictionary
{
    NSLog(@"setting up part of speech dictionary");
    dictionary = [[NSMutableDictionary alloc]init];
    verboseDictionary = [[NSMutableDictionary alloc]init];

    [self setValue:POSAdjective forKey:@"adj"];
    [self setValue:POSAdverb forKey:@"adv"];
    [self setValue:POSConjunction forKey:@"conj"];
    [self setValue:POSInterjection forKey:@"interj"];
    [self setValue:POSNoun forKey:@"n"];
    [self setValue:POSPreposition forKey:@"prep"];
    [self setValue:POSPronoun forKey:@"pron"];
    [self setValue:POSVerb forKey:@"v"];
    
    [self setVerboseValue:POSAdjective forKey:@"adjective"];
    [self setVerboseValue:POSAdverb forKey:@"adverb"];
    [self setVerboseValue:POSConjunction forKey:@"conjunction"];
    [self setVerboseValue:POSInterjection forKey:@"interjection"];
    [self setVerboseValue:POSNoun forKey:@"noun"];
    [self setVerboseValue:POSPreposition forKey:@"preposition"];
    [self setVerboseValue:POSPronoun forKey:@"pronoun"];
    [self setVerboseValue:POSVerb forKey:@"verb"];
}

-(void)setValue:(PartOfSpeech)partOfSpeech forKey:(NSString *)pos
{
    NSNumber* number = [NSNumber numberWithInt:partOfSpeech];
    [dictionary setValue:number forKey:pos];
}

-(void)setVerboseValue:(PartOfSpeech)partOfSpeech forKey:(NSString *)part_of_speech
{
    NSNumber* number = [NSNumber numberWithInt:partOfSpeech];
    [verboseDictionary setValue:number forKey:part_of_speech];
}

@end
