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

#import "DownloadButtonImage.h"
#import "DownloadBarButton.h"

@implementation DownloadBarButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([UIScreen mainScreen].scale > 1.0) {
            _borderLayer = [CALayer layer];
            _borderLayer.opaque = NO;
            _borderLayer.backgroundColor = [UIColor clearColor].CGColor;
            _borderLayer.position = CGPointMake(0.5 * self.bounds.size.width, 0.5 * self.bounds.size.height);
            _borderLayer.bounds = CGRectMake(0, 0, 0.75 * self.bounds.size.width, 0.75 * self.bounds.size.height);

            _borderLayer.cornerRadius = 0.1 * sqrt(self.bounds.size.width * self.bounds.size.height);
            _borderLayer.borderColor = self.currentTitleColor.CGColor;
            _borderLayer.borderWidth = 1.0;
        }

        [self.layer addSublayer:_borderLayer];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [DownloadButtonImage buildImageWithSize:self.bounds.size color:self.currentTitleColor background:self.backgroundColor context:UIGraphicsGetCurrentContext()];
    _borderLayer.borderColor = self.currentTitleColor.CGColor;
}

@end
