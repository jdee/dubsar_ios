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

#import "PushWrapper.h"

@interface PushWrapper()

+ (UIUserNotificationCategory*) wotdCategory;

@end

@implementation PushWrapper

+ (void)register
{
    /*
     * Make sure this is a dynamic check at runtime. When I do this in Swift, the app crashes on iOS 7 looking for UIUserNotificationSettings.
     * Though, that was back around Beta2. Not sure any more.
     */

    UIApplication* theApplication = [UIApplication sharedApplication];

    if ([theApplication respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // iOS 8
        NSSet *categories = [NSSet setWithObject:[self wotdCategory]];
        [theApplication registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:categories]];
        [theApplication registerForRemoteNotifications];
    }
    else {
        // iOS 7 and below
        [theApplication registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeSound];
    }
}

+ (UIUserNotificationCategory *)wotdCategory
{
    UIMutableUserNotificationCategory* category = [[UIMutableUserNotificationCategory alloc] init];
    category.identifier = @"wotd";

    UIMutableUserNotificationAction* viewAction = [[UIMutableUserNotificationAction alloc] init];
    viewAction.identifier = @"view";
    viewAction.authenticationRequired = YES;
    viewAction.activationMode = UIUserNotificationActivationModeForeground;
    viewAction.destructive = NO;
    viewAction.title = @"View";

    UIMutableUserNotificationAction* bookmarkAction = [[UIMutableUserNotificationAction alloc] init];
    bookmarkAction.identifier = @"bookmark";
#ifdef DEBUG
    bookmarkAction.authenticationRequired = YES; // for keychain
#else
    bookmarkAction.authenticationRequired = NO;
#endif // DEBUG
    bookmarkAction.activationMode = UIUserNotificationActivationModeBackground;
    bookmarkAction.destructive = NO;
    bookmarkAction.title = @"Bookmark";

    [category setActions:@[viewAction, bookmarkAction] forContext:UIUserNotificationActionContextDefault];
    
    return category;
}

@end
