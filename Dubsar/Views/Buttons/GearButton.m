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

#import "GearButton.h"

@implementation GearButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _numTeeth = 8;
        _rotation = 0.0;
        _innerRingRatio = 0.18;
        _innerToothRatio = 0.25;
        _outerToothRatio = 0.3;
        _lineWidth = 1.0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    [self drawGearPath:context];

    CGContextSetLineWidth(context, _lineWidth);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetStrokeColorWithColor(context, self.currentTitleColor.CGColor);
    CGContextSetShouldAntialias(context, true);
    CGContextStrokePath(context);

    if (_innerRingRatio <= 0.0) return;

    const CGFloat width = self.bounds.size.width;
    const CGFloat height = self.bounds.size.height;
    CGContextAddArc(context, 0.5*width, 0.5*height, _innerRingRatio*MIN(width, height), 0, 2.0*M_PI, NO);
    CGContextStrokePath(context);
}

- (void)drawGearPath:(CGContextRef)context
{
    const CGFloat width = self.bounds.size.width;
    const CGFloat height = self.bounds.size.height;

    const CGFloat dimension = MIN(width, height);

    const CGFloat deltaTheta = 2.0 * M_PI / (CGFloat)_numTeeth;

    CGFloat theta = -0.125 * deltaTheta + _rotation;
    CGFloat radius = _outerToothRatio * dimension;

    CGContextMoveToPoint(context, 0.5*width + cos(theta)*radius, 0.5*height + sin(theta)*radius);

    for (int j=0; j<_numTeeth; ++j) {
        theta = ((CGFloat)j - 0.125) * deltaTheta + _rotation;
        radius = _outerToothRatio * dimension;

        CGContextAddArc(context, 0.5 * width, 0.5 * height, radius, theta, theta + 0.25 * deltaTheta, NO);

        theta += 0.5 * deltaTheta;
        radius = _innerToothRatio * dimension;

        CGContextAddLineToPoint(context, cos(theta)*radius + 0.5 * width, sin(theta)*radius + 0.5 * height);
        CGContextAddArc(context, 0.5 * width, 0.5 * height, radius, theta, theta + 0.25 * deltaTheta, NO);

        theta += 0.5 * deltaTheta;
        radius = _outerToothRatio * dimension;

        CGContextAddLineToPoint(context, cos(theta)*radius + 0.5 * width, sin(theta)*radius + 0.5 * height);
    }

    CGContextAddArc(context, 0.5 * width, 0.5 * height, radius, theta, theta + 0.25 * deltaTheta, NO);
}

@end
