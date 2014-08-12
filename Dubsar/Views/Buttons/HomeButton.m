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

#import "HomeButton.h"

@implementation HomeButton

- (void)drawRect:(CGRect)rect {
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, self.currentTitleColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetLineJoin(context, kCGLineJoinMiter);

    CGContextSetShouldAntialias(context, true);
    CGContextMoveToPoint(context, 0.2*width, 0.5*height);
    CGContextAddLineToPoint(context, 0.5*width, 0.2*height);
    CGContextAddLineToPoint(context, 0.8*width, 0.5*height);
    CGContextAddLineToPoint(context, 0.7*width, 0.5*height);
    CGContextAddLineToPoint(context, 0.7*width, 0.8*height);
    CGContextAddLineToPoint(context, 0.57*width, 0.8*height);
    CGContextAddLineToPoint(context, 0.57*width, 0.57*height);
    CGContextAddLineToPoint(context, 0.43*width, 0.57*height);
    CGContextAddLineToPoint(context, 0.43*width, 0.8*height);
    CGContextAddLineToPoint(context, 0.3*width, 0.8*height);
    CGContextAddLineToPoint(context, 0.3*width, 0.5*height);
    CGContextAddLineToPoint(context, 0.2*width, 0.5*height);
    CGContextAddLineToPoint(context, 0.5*width, 0.2*height);
    CGContextStrokePath(context);
}

@end
