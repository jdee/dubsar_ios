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

#import "DubsarModelsDailyWord.h"
#import "DubsarModelsLoadDelegate.h"
#import "DubsarModelsWord.h"

#define DubsarDailyWordIdKey @"DubsarDailyWordId"
#define DubsarDailyWordExpirationKey @"DubsarDailyWordExpiration"

@implementation DubsarModelsDailyWord

@synthesize fresh;
@synthesize word;
@synthesize expiration;

+ (instancetype)dailyWord
{
    return [[self alloc] init];
}

+ (void)updateWotdWithNotificationPayload:(NSDictionary *)dubsarPayload
{
    if (!dubsarPayload) return;

    NSString* type = [dubsarPayload valueForKey:@"type"];
    if (![type isEqualToString:@"wotd"]) return;

    NSURL* url = [NSURL URLWithString:[dubsarPayload valueForKey:@"url"]];
    assert([url.path hasPrefix:@"/wotd/"]);
    NSInteger wotdId = url.path.lastPathComponent.intValue;

    time_t texpiration = 0;
    NSString* sexpiration = [dubsarPayload valueForKey:@"expiration"];
    if ([sexpiration hasPrefix:@"+"]) {
        texpiration = time(0) + sexpiration.intValue;
    }
    else {
        texpiration = sexpiration.intValue;
    }

    [self updateWotdId:wotdId expiration:texpiration];
}

+ (void)updateWotdId:(NSInteger)wotdId expiration:(time_t)expiration
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
    wotd.word = [DubsarModelsWord wordWithId:wotdId name:nil partOfSpeech:DubsarModelsPartOfSpeechUnknown];
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
            NSLog(@"cached wotd expired, requesting");
        }
        
        // fresh is set to true when the wotd is not in the defaults.
        // this results in the WOTD indicator appearing in the app.
        fresh = true;
        [self loadFromServer];
        return;
    }
    
    self.complete = true;
    self.error = false;
    self.errorMessage = nil;
    
    [self.delegate loadComplete:self withError:self.errorMessage];
}

- (void)parseData
{
    NSArray* wotd = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
    NSNumber* numericId = wotd[0];
    
    word = [DubsarModelsWord wordWithId:numericId.intValue name:wotd[1] posString:wotd[2]];
    
    NSNumber* fc = wotd[3];
    word.freqCnt = fc.intValue;
    
    word.inflections = [[wotd[4] componentsSeparatedByString:@", "] mutableCopy];
    
    expiration = [wotd[5]intValue];
    
    [self saveToUserDefaults];
}

- (bool) loadFromUserDefaults
{
    NSInteger wotdId = [[NSUserDefaults standardUserDefaults] integerForKey:DubsarDailyWordIdKey];

    if (wotdId <= 0) {
        NSLog(@"User defaults value for %@: %@", DubsarDailyWordIdKey, [[NSUserDefaults standardUserDefaults] valueForKey:DubsarDailyWordIdKey]);
        return false;
    }
#ifdef DEBUG
    else {
        NSLog(@"Found wotd in user defaults, id %ld", (long)wotdId);
    }
#endif // DEBUG
    
    self.word = [DubsarModelsWord wordWithId:wotdId name:nil partOfSpeech:DubsarModelsPartOfSpeechUnknown];
    self.word.delegate = self;
    [word load];
    
    expiration = [[NSUserDefaults standardUserDefaults] integerForKey:DubsarDailyWordExpirationKey];
    
    return true;
}

- (void) saveToUserDefaults
{
    NSLog(@"Saving WOTD: ID: %lu, expiration: %ld", (unsigned long)word._id, expiration);
    [[NSUserDefaults standardUserDefaults] setInteger:word._id forKey:DubsarDailyWordIdKey];
    [[NSUserDefaults standardUserDefaults] setInteger:expiration forKey:DubsarDailyWordExpirationKey];
}

- (void)loadComplete:(DubsarModelsModel *)model withError:(NSString *)error
{
#ifdef DEBUG
    NSLog(@"Loaded WOTD");
#endif // DEBUG
    [self.delegate loadComplete:self withError:error];
}

@end
