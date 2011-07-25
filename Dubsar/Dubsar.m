//
//  Dubsar.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"

const NSString* DubsarBaseUrl = @"http://dubsar-dictionary.com";
// const NSString* DubsarBaseUrl = @"http://fatman:3000";

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