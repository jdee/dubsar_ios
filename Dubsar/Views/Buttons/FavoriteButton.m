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

#import "FavoriteButton.h"

@implementation FavoriteButton

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.selected) {
        [self drawFilled:context];
    }
    else {
        [self drawEmpty:context];
    }
}

- (void)drawEmpty:(CGContextRef)context
{
    [self drawStarPath:context];

    CGContextSetStrokeColorWithColor(context, self.currentTitleColor.CGColor);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetShouldAntialias(context, true);
    CGContextStrokePath(context);
}

- (void)drawFilled:(CGContextRef)context
{
    [self drawStarPath:context];
    CGContextSetFillColorWithColor(context, _fillColor.CGColor);
    CGContextFillPath(context);

    [self drawEmpty:context];
}

- (void)drawStarPath:(CGContextRef)context
{
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    CGContextMoveToPoint   (context, 0.500*width, 0.215*height);
    CGContextAddLineToPoint(context, 0.429*width, 0.433*height);
    CGContextAddLineToPoint(context, 0.200*width, 0.433*height);
    CGContextAddLineToPoint(context, 0.385*width, 0.567*height);
    CGContextAddLineToPoint(context, 0.315*width, 0.785*height);
    CGContextAddLineToPoint(context, 0.500*width, 0.650*height);
    CGContextAddLineToPoint(context, 0.685*width, 0.785*height);
    CGContextAddLineToPoint(context, 0.615*width, 0.567*height);
    CGContextAddLineToPoint(context, 0.800*width, 0.433*height);
    CGContextAddLineToPoint(context, 0.571*width, 0.433*height);
    CGContextAddLineToPoint(context, 0.500*width, 0.215*height);

    // repeat the first leg for better mitering.
    CGContextAddLineToPoint(context, 0.429*width, 0.433*height);
}

@end
