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

#import "ForwardStack.h"

@implementation ForwardStack

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        stack = [[NSMutableArray array]retain];
    }
    
    return self;
}

- (void)dealloc
{
    [stack release];
    [super dealloc];
}

- (void)pushViewController:(UIViewController *)viewController
{
    [stack addObject:viewController];
}

- (UIViewController*)popViewController
{
    UIViewController* viewController = self.topViewController;
    [stack removeLastObject];
    return viewController;
}

- (UIViewController*)topViewController
{
    return stack.lastObject;
}

- (void)clear
{
    [stack removeAllObjects];
}

- (unsigned int)count
{
    return stack.count;
}

@end
