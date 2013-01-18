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
    _searchBarViewController = [[[SearchBarViewController_iPad alloc]initWithNibName:@"SearchBarViewController_iPad" bundle:nil]autorelease];
    DubsarViewController_iPad* dubsarViewController = [[[DubsarViewController_iPad alloc]initWithNibName:@"DubsarViewController_iPad" bundle:nil]autorelease];
    
    _navigationController = [[DubsarNavigationController_iPad alloc]initWithRootViewController:dubsarViewController];
    _searchBarViewController.navigationController = _navigationController;
    
    _splitViewController = [[UISplitViewController alloc]init];
    _splitViewController.viewControllers = [NSArray arrayWithObjects:_searchBarViewController, _navigationController, nil];
    
    self.window.rootViewController = _splitViewController;    
    
    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    wotdUnread = false;
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [super application:application didReceiveRemoteNotification:userInfo];
    NSLog(@"push received");
    
    NSString* url = [userInfo valueForKey:@"dubsar_url"];
    if (url) {
        NSLog(@"dubsar_url: %@", url);
        
        self.wotdUrl = url;
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
        {
            self.wotdUnread = true;
            [_navigationController addWotdButton];
            
            return;
        }
        
        [self application:application openURL:[NSURL URLWithString:url]
        sourceApplication:nil annotation:nil];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.scheme compare:@"dubsar"] != NSOrderedSame) {
        NSLog(@"can't handle URL scheme %@", url.scheme);
        return NO;
    }
    
    if ([url.path hasPrefix:@"/words/"]) {
        NSLog(@"Opening %@", url);
        
        int wordId = [[url lastPathComponent] intValue];
        Word* word = [Word wordWithId:wordId name:nil partOfSpeech:POSUnknown];
        [word load];
        [_navigationController dismissViewControllerAnimated:YES completion:nil];
        WordViewController_iPad* viewController = [[[WordViewController_iPad alloc]initWithNibName:@"WordViewController_iPad" bundle:nil word:word]autorelease];
        [viewController load];
        [_navigationController pushViewController:viewController animated:YES];
        return YES;
    }
    
    return NO;
}

- (void)dealloc
{
    [_navigationController release];
    [_splitViewController release];
	[super dealloc];
}

@end
