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

#import "DubsarAppDelegate_iPhone.h"
#import "DubsarNavigationController_iPhone.h"
#import "DubsarViewController_iPhone.h"
#import "WordViewController_iPhone.h"
#import "Word.h"

@implementation DubsarAppDelegate_iPhone

@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    DubsarViewController_iPhone *rootViewController = [[DubsarViewController_iPhone alloc]
                                              initWithNibName:@"DubsarViewController_iPhone" bundle:nil];
    _navigationController = [[[DubsarNavigationController_iPhone alloc]initWithRootViewController:rootViewController]autorelease];
    [rootViewController release];
    
    UIColor* tint = [UIColor colorWithRed:0.110 green:0.580 blue:0.769 alpha:1.0];
    _navigationController.navigationBar.tintColor = tint;
    _navigationController.toolbar.tintColor = tint;
   
    [self.window setRootViewController:_navigationController];

    [super application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    UIViewController* controller = _navigationController.topViewController;
    if ([controller respondsToSelector:@selector(load)]) {
        [controller load];
    }
    [super applicationWillEnterForeground:application];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.scheme compare:@"dubsar"] != NSOrderedSame) {
        NSLog(@"can't handle URL scheme %@", url.scheme);
        return NO;
    }
    
    if ([url.path hasPrefix:@"/words/"]) {
        int wordId = [[url lastPathComponent] intValue];
        Word* word = [Word wordWithId:wordId name:nil partOfSpeech:POSUnknown];
        [word load];
        [_navigationController dismissViewControllerAnimated:YES completion:nil];
        [_navigationController pushViewController:[[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:word]autorelease] animated:YES];
        return YES;
    }
    
    return NO;
}

- (void)dealloc
{
    [_navigationController release];
	[super dealloc];
}

@end
