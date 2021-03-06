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

@import DubsarModels;

#import "KeyboardHelper.h"

@implementation KeyboardHelper

+ (CGFloat)keyboardSizeFromNotification:(NSNotification *)notification
{
    /*
     * Can prob. still do this in Swift, but it was causing problems.
     */
    NSDictionary* userInfo = notification.userInfo;
    NSNumber* frameEndValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize size = frameEndValue.CGRectValue.size;

    CGFloat height = 0;
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        height = size.height;
    }
    else {
        height = size.width;
    }

    DMTRACE(@"Keyboard height is %f", height);

    return height;
}

@end
