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

#import "Dubsar.h"

const NSString* DubsarBaseUrl = @"http://dubsar-dictionary.com";
// const NSString* DubsarBaseUrl = @"http://fatman:3001";

PartOfSpeech partOfSpeechFromPos(NSString* pos)
{
    if ([pos isEqualToString:@"adj"]) {
        return POSAdjective;
    }
    else if ([pos isEqualToString:@"adv"]) {
        return POSAdverb;
    }
    else if ([pos isEqualToString:@"conj"]) {
        return POSConjunction;
    }
    else if ([pos isEqualToString:@"interj"]) {
        return POSInterjection;
    }
    else if ([pos isEqualToString:@"n"]) {
        return POSNoun;
    }
    else if ([pos isEqualToString:@"prep"]) {
        return POSPreposition;
    }
    else if ([pos isEqualToString:@"pron"]) {
        return POSPronoun;
    }
    else if ([pos isEqualToString:@"v"]) {
        return POSVerb;
    }
    
    return POSUnknown;
}