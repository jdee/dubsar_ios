/*
 Dubsar Dictionary Project
 Copyright (C) 2010-15 Jimmy Dee
 
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
#import "DubsarModelsDailyWord.h"
#import "DubsarModelsLoadDelegate.h"
#import "DubsarModelsWord.h"

#define DubsarDailyWordIdKey @"DubsarDailyWordId"
#define DubsarDailyWordExpirationKey @"DubsarDailyWordExpiration"
#define DubsarDailyWordNameKey @"DubsarDailyWordName"
#define DubsarDailyWordPosKey @"DubsarDailyWordPos"

@implementation DubsarModelsDailyWord

@synthesize fresh;
@synthesize word;
@synthesize expiration;

+ (instancetype)dailyWord
{
    return [[self alloc] init];
}

+ (void)updateWotdWithNotificationPayload:(NSDictionary *)notification
{
    NSDictionary* dubsarPayload = notification[@"dubsar"];
    if (!dubsarPayload) return;

    NSString* type = dubsarPayload[@"type"];
    if (![type isEqualToString:@"wotd"]) return;

    NSURL* url = [NSURL URLWithString:dubsarPayload[@"url"]];
    assert([url.path hasPrefix:@"/wotd/"]);
    NSInteger wotdId = url.path.lastPathComponent.intValue;

    time_t texpiration = 0;
    // DEBT: This is no longer an NSString to be converted, so we lose the + sign at the
    // beginning that's used to indicate relative expiration times. Change to a nonnumeric
    // introducer, like R60 instead of +60. Only interesting during testing though.
    NSNumber* sexpiration = dubsarPayload[@"expiration"];
    texpiration = sexpiration.intValue;

    NSDictionary* aps = notification[@"aps"];
    NSString* alert = aps[@"alert"];

    NSString* nameAndPos = [alert substringFromIndex:@"Word of the day: ".length];

    NSArray* components;
    if ([nameAndPos rangeOfString:@","].location == NSNotFound) {
        // name (pos.)
        components = [nameAndPos componentsSeparatedByString:@" ("];
    }
    else {
        // name, pos.
        components = [nameAndPos componentsSeparatedByString:@", "];
    }

    NSString* name = components[0];
    NSString* posComponent = components[1];
    NSString* pos = [posComponent substringToIndex:[posComponent rangeOfString:@"."].location];
    DubsarModelsPartOfSpeech partOfSpeech = [DubsarModelsPartOfSpeechDictionary partOfSpeechFromPOS:pos];

    [self updateWotdId:wotdId expiration:texpiration name:name partOfSpeech:partOfSpeech];
}

+ (void)updateWotdId:(NSInteger)wotdId expiration:(time_t)expiration name:(NSString*)name partOfSpeech:(DubsarModelsPartOfSpeech)partOfSpeech
{
    if (expiration < time(NULL)) {
        /*
         * Notifications hang around as long as the user wants in some cases. If the
         * expiration passed in is in the past (which can happen if they tap one from
         * several days ago), ignore this.
         */
        return;
    }

    DubsarModelsDailyWord* wotd = [DubsarModelsDailyWord dailyWord];
    wotd.word = [DubsarModelsWord wordWithId:wotdId name:name partOfSpeech:partOfSpeech];
    wotd.expiration = expiration;
    [wotd saveToUserDefaults];   
}

+ (void)resetWotd
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DubsarDailyWordIdKey];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self set_url:@"/wotd"];
        word = nil;
        fresh = false;
        expiration = 0;
    }
    
    return self;
}

- (void)load
{
    if (![self loadFromUserDefaults] || !expiration || expiration <= time(0)) {
        
        if (expiration && expiration <= time(0)) {
            DMINFO(@"cached wotd expired, requesting");
        }
        
        // fresh is set to true when the wotd is not in the defaults.
        // this results in the WOTD indicator appearing in the app.
        fresh = true;
        [self loadFromServer];
    }
}

- (void)parseData
{
    NSArray* wotd = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    NSNumber* numericId = wotd[0];
    
    word = [DubsarModelsWord wordWithId:numericId.intValue name:wotd[1] posString:wotd[2]];
    DMINFO(@"Received WOTD response: %@", word.nameAndPos);
    
    NSNumber* fc = wotd[3];
    word.freqCnt = fc.intValue;
    
    word.inflections = [[wotd[4] componentsSeparatedByString:@", "] mutableCopy];
    
    expiration = [wotd[5]intValue];
    
    [self saveToUserDefaults];
}

- (bool)loadFromUserDefaults
{
    NSInteger wotdId = [[NSUserDefaults standardUserDefaults] integerForKey:DubsarDailyWordIdKey];

    if (wotdId <= 0) {
        DMWARN(@"User defaults value for %@: %@", DubsarDailyWordIdKey, [[NSUserDefaults standardUserDefaults] valueForKey:DubsarDailyWordIdKey]);
        return false;
    }
    else {
        DMTRACE(@"Found wotd in user defaults, id %ld", (long)wotdId);
    }

    NSString* name = [[NSUserDefaults standardUserDefaults] valueForKey:DubsarDailyWordNameKey];
    NSString* pos = [[NSUserDefaults standardUserDefaults] valueForKey:DubsarDailyWordPosKey];
    
    self.word = [DubsarModelsWord wordWithId:wotdId name:name posString:pos];
    self.word.delegate = self;

    self.complete = true;
    self.error = false;
    self.errorMessage = nil;

    expiration = [[NSUserDefaults standardUserDefaults] integerForKey:DubsarDailyWordExpirationKey];

    if (!name) {
        DMWARN(@"WOTD name not found in user defaults.");
        return false;
    }

    [self.delegate loadComplete:self withError:nil];

    return true;
}

- (void)saveToUserDefaults
{
    DMDEBUG(@"Saving WOTD: ID: %lu, expiration: %ld", (unsigned long)word._id, expiration);
    [[NSUserDefaults standardUserDefaults] setInteger:word._id forKey:DubsarDailyWordIdKey];
    [[NSUserDefaults standardUserDefaults] setInteger:expiration forKey:DubsarDailyWordExpirationKey];
    [[NSUserDefaults standardUserDefaults] setValue:word.name forKey:DubsarDailyWordNameKey];
    [[NSUserDefaults standardUserDefaults] setValue:word.pos forKey:DubsarDailyWordPosKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.dubsar-dictionary.Dubsar.Documents"];
    if (userDefaults) {
        [userDefaults setObject:[NSString stringWithFormat:@"dubsar:///wotd/%lu", (unsigned long)word._id] forKey:@"wotdURL"];
        [userDefaults setObject:[NSString stringWithFormat:@"%@, %@.", word.name, word.pos] forKey:@"wotdText"];
        [userDefaults setBool:YES forKey:@"wotdUpdated"];
        DMDEBUG(@"Updated user defaults for Word of the Day extension");
    }
    else {
        DMERROR(@"Could not get shared user defaults suite");
    }
}

- (void)loadComplete:(DubsarModelsModel *)model withError:(NSString *)error
{
    DMDEBUG(@"Loaded WOTD");
    [self.delegate loadComplete:self withError:error];
}

@end
