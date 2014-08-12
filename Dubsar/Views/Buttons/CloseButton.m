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

#import "CloseButton.h"

@implementation CloseButton

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    const CGFloat width = self.bounds.size.width;
    const CGFloat height = self.bounds.size.height;

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, self.currentTitleColor.CGColor);
    CGContextSetLineWidth(context, 1.0);
    CGContextSetShouldAntialias(context, true);

    CGContextMoveToPoint(context, 0.2*width, 0.2*height);
    CGContextAddLineToPoint(context, 0.8*width, 0.8*height);
    CGContextStrokePath(context);

    CGContextMoveToPoint(context, 0.8*width, 0.2*height);
    CGContextAddLineToPoint(context, 0.2*width, 0.8*height);
    CGContextStrokePath(context);
}

@end
