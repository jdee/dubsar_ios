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

#import "DubsarNavigationController_iPhone.h"
#import "ForegroundViewController.h"

@interface ForegroundViewController ()

@end

@implementation ForegroundViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Dumping ground for shit that should be handled by respondsToSelector:
- (void)load
{
}

- (bool)handleWotd
{
    return false;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
}

- (void)handleTouch:(UITouch *)touch
{
}

- (void) recordOriginalFrame
{
    DubsarNavigationController_iPhone* navigationController = (DubsarNavigationController_iPhone*)self.navigationController;
    // assumes this is the top VC
    [navigationController recordOriginalFrame];
}

@end
