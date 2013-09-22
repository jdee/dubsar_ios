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

#import "DubsarAppDelegate_iPad.h"
#import "DubsarNavigationController_iPad.h"
#import "DubsarViewController_iPad.h"
#import "SearchBarViewController_iPad.h"
#import "Sense.h"
#import "SenseViewController_iPad.h"
#import "Synset.h"
#import "SynsetViewController_iPad.h"
#import "Word.h"
#import "WordViewController_iPad.h"

@implementation DubsarAppDelegate_iPad

@synthesize navigationController = _navigationController;
@synthesize splitViewController = _splitViewController;
@synthesize searchBarViewController = _searchBarViewController;
@synthesize wotdUrl;
@synthesize wotdUnread;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    _searchBarViewController = [[SearchBarViewController_iPad alloc]initWithNibName:@"SearchBarViewController_iPad" bundle:nil];
    DubsarViewController_iPad* dubsarViewController = [[DubsarViewController_iPad alloc]initWithNibName:@"DubsarViewController_iPad" bundle:nil];
    
    _navigationController = [[DubsarNavigationController_iPad alloc]initWithRootViewController:dubsarViewController];
    _searchBarViewController.navigationController = _navigationController;
    
    _splitViewController = [[UISplitViewController alloc]init];
    _splitViewController.viewControllers = [NSArray arrayWithObjects:_searchBarViewController, _navigationController, nil];
    
    self.window.rootViewController = _splitViewController;    
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)addWotdButton
{
    [_navigationController addWotdButton];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.scheme compare:@"dubsar"] != NSOrderedSame) {
        return [super application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    
    if ([url.path hasPrefix:@"/wotd/"]) {
#ifdef DEBUG
        NSLog(@"Opening %@", url);
#endif // DEBUG
        
        int wordId = [[url lastPathComponent] intValue];
        Word* word = [Word wordWithId:wordId name:nil partOfSpeech:POSUnknown];
        [word load];
        
        WordViewController_iPad* viewController = [[WordViewController_iPad alloc]initWithNibName:@"WordViewController_iPad" bundle:nil word:word title:@"Word of the Day"];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    if ([url.path hasPrefix:@"/words/"]) {
#ifdef DEBUG
        NSLog(@"Opening %@", url);
#endif // DEBUG
        
        int wordId = [[url lastPathComponent] intValue];
        Word* word = [Word wordWithId:wordId name:nil partOfSpeech:POSUnknown];
        [word load];

        WordViewController_iPad* viewController = [[WordViewController_iPad alloc]initWithNibName:@"WordViewController_iPad" bundle:nil word:word title:nil];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    if ([url.path hasPrefix:@"/senses/"]) {
#ifdef DEBUG
        NSLog(@"Opening %@", url);
#endif // DEBUG
        
        int senseId = [[url lastPathComponent] intValue];
        Sense* sense = [Sense senseWithId:senseId name:nil partOfSpeech:POSUnknown];
        [sense load];

        SenseViewController_iPad* viewController = [[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:sense];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    if ([url.path hasPrefix:@"/synsets/"]) {
#ifdef DEBUG
        NSLog(@"Opening %@", url);
#endif // DEBUG
        
        int synsetId = [[url lastPathComponent] intValue];
        Synset* synset = [Synset synsetWithId:synsetId partOfSpeech:POSUnknown];
        
        SynsetViewController_iPad* viewController = [[SynsetViewController_iPad alloc]initWithNibName:@"SynsetViewController_iPad" bundle:nil synset:synset];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    return NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [super applicationDidBecomeActive:application];

    /*
     * Necessary on the iPad, not on the iPhone.
     */
    [self.navigationController.topViewController viewWillAppear:NO];
}

@end
