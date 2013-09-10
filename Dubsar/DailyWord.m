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

#import "DailyWord.h"
#import "JSONkit.h"
#import "LoadDelegate.h"
#import "Word.h"

#define DubsarDailyWordIdKey @"com.dubsar-dictionary.Dubsar.wotdId"
#define DubsarDailyWordExpirationKey @"com.dubsar-dictionary.Dubsar.wotdExpiration"

@implementation DailyWord

@synthesize fresh;
@synthesize word;
@synthesize expiration;

+ (id)dailyWord
{
    return [[[DailyWord alloc] init] autorelease];
}

+ (void)updateWotdId:(int)wotdId expiration:(time_t)expiration
{
    if (expiration < time(NULL)) {
        /*
         * Notifications hang around as long as the user wants in some cases. If the
         * expiration passed in is in the past (which can happen if they tap one from
         * several days ago), ignore this.
         */
        return;
    }

    DailyWord* wotd = [DailyWord dailyWord];
    wotd.word = [Word wordWithId:wotdId name:nil partOfSpeech:POSUnknown];
    wotd.expiration = expiration;
    [wotd saveToUserDefaults];   
}

+ (void)resetWotd
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DubsarDailyWordIdKey];
}

- (id)init
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

- (void)dealloc
{
    [word release];
    [super dealloc];
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
    NSArray* wotd = [[self decoder] objectWithData:[self data]];
    NSNumber* numericId = [wotd objectAtIndex:0];
    
    word = [[Word wordWithId:numericId.intValue name:[wotd objectAtIndex:1] posString:[wotd objectAtIndex:2]]retain];
    
    NSNumber* fc = [wotd objectAtIndex:3];
    word.freqCnt = fc.intValue;
    
    word.inflections = [[[[wotd objectAtIndex:4] componentsSeparatedByString:@", "] mutableCopy] autorelease];
    
    expiration = [[wotd objectAtIndex:5]intValue];
    
    [self saveToUserDefaults];
}

- (bool) loadFromUserDefaults
{
    int wotdId = [[NSUserDefaults standardUserDefaults] integerForKey:DubsarDailyWordIdKey];

    if (wotdId <= 0) {
        NSLog(@"User defaults value for %@: %@", DubsarDailyWordIdKey, [[NSUserDefaults standardUserDefaults] valueForKey:DubsarDailyWordIdKey]);
        return false;
    }
#ifdef DEBUG
    else {
        NSLog(@"Found wotd in user defaults, id %d", wotdId);
    }
#endif // DEBUG
    
    self.word = [Word wordWithId:wotdId name:nil partOfSpeech:POSUnknown];
    self.word.delegate = self;
    [word load];
    
    expiration = [[NSUserDefaults standardUserDefaults] integerForKey:DubsarDailyWordExpirationKey];
    
    return true;
}

- (void) saveToUserDefaults
{
    NSLog(@"Saving WOTD: ID: %d, expiration: %ld", word._id, expiration);
    [[NSUserDefaults standardUserDefaults] setInteger:word._id forKey:DubsarDailyWordIdKey];
    [[NSUserDefaults standardUserDefaults] setInteger:expiration forKey:DubsarDailyWordExpirationKey];
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
#ifdef DEBUG
    NSLog(@"Loaded WOTD");
#endif // DEBUG
    [self.delegate loadComplete:self withError:error];
}

@end
