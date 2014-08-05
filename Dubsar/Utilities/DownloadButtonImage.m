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

static BOOL initialized = NO;
static NSMutableDictionary* imageDictionary;

@implementation DownloadButtonImage

/*
 * Makes a download button: an arrow pointing downward toward a horizontal
 * line across the bottom.
 */
+ (void)buildImageWithSize:(CGSize)size color:(UIColor*)color background:(UIColor*)backgroundColor context:(CGContextRef)context
{
    // use CG to draw in this context and return a UIImage for use with a UIButton.
    // a/k/a FREEDOM FROM THE @!$@# GIMP!

    CGContextSetAllowsAntialiasing(context, true);

    // transparent background
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

    // All strokes. Set color and line width.

    // basic line width is 1 pixel
    CGFloat lineWidth = 1.41421359 /*/[UIScreen mainScreen].scale*/;
    CGContextSetStrokeColorWithColor(context, color.CGColor);

    // Vertical line down the center. Nice and sharp with no antialiasing.
    CGContextSetShouldAntialias(context, false);
    CGContextSetLineWidth(context, lineWidth);

    CGContextMoveToPoint(context, 0.5 * size.width, 0.25 * size.height);
    CGContextAddLineToPoint(context, 0.5 * size.width, 0.65 * size.height - lineWidth);
    CGContextStrokePath(context);

    // For the arrowhead, turn on antialiasing and thicken the line a little.
    CGContextSetShouldAntialias(context, true);
    CGContextSetLineWidth(context, 1.41421359 * lineWidth);
    CGContextSetLineJoin(context, kCGLineJoinMiter);

    CGFloat fudge = 0;

    // Arrow head
    CGContextMoveToPoint(context, 0.35 * size.width + fudge, 0.50 * size.height);
    CGContextAddLineToPoint(context, 0.5 * size.width + fudge, 0.65 * size.height);
    CGContextAddLineToPoint(context, 0.65 * size.width + fudge, 0.50 * size.height);
    CGContextStrokePath(context);

    // horizontal line across the bottom. back to a sharp line.
    CGContextSetShouldAntialias(context, false);
    CGContextSetLineWidth(context, lineWidth);

    CGContextMoveToPoint(context, 0.25 * size.width, 0.75 * size.height);
    CGContextAddLineToPoint(context, 0.75 * size.width, 0.75 * size.height);
    CGContextStrokePath(context);

    // Rounded-rectangle border
    const CGFloat cornerRadius = 0.1 * sqrt(size.width * size.height); // points
    const CGFloat ratio = 0.9; // width of border to size.width
    CGContextSetShouldAntialias(context, true);
    CGContextMoveToPoint(context, ratio * size.width, ratio * size.height - cornerRadius);
    CGContextAddLineToPoint(context, ratio * size.width, (1 - ratio) * size.height + cornerRadius);
    CGContextAddArcToPoint(context, ratio * size.width, (1 - ratio) * size.height, ratio * size.width - cornerRadius, (1 - ratio) * size.height, cornerRadius);
    CGContextAddLineToPoint(context, (1 - ratio) * size.width + cornerRadius, (1 - ratio) * size.height);
    CGContextAddArcToPoint(context, (1 - ratio) * size.width, (1 - ratio) * size.height, (1 - ratio) * size.width, (1 - ratio) * size.height + cornerRadius, cornerRadius);
    CGContextAddLineToPoint(context, (1 - ratio) * size.width, ratio * size.height - cornerRadius);
    CGContextAddArcToPoint(context, (1 - ratio) * size.width, ratio * size.height, (1 - ratio) * size.width + cornerRadius, ratio * size.height, cornerRadius);
    CGContextAddLineToPoint(context, ratio * size.width - cornerRadius, ratio * size.height);
    CGContextAddArcToPoint(context, ratio * size.width, ratio * size.height, ratio * size.width, ratio * size.height - cornerRadius, cornerRadius);
    CGContextStrokePath(context);
}

+ (NSString*)keyForSize:(CGSize)size color:(UIColor*)color background:(UIColor*)backgroundColor
{
    CGFloat red=0, green=0, blue=0, alpha=0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    CGFloat bgred=0, bggreen=0, bgblue=0, bgalpha=0;
    [backgroundColor getRed:&bgred green:&bggreen blue:&bgblue alpha:&bgalpha];

    return [NSString stringWithFormat:@"%.1fx%.1f:%02x%02x%02x%02x:%02x%02x%02x%02x", size.width, size.height, (int)red*255, (int)green*255, (int)blue*255, (int)alpha*255, (int)bgred*255, (int)bggreen*255, (int)bgblue*255, (int)bgalpha*255];
}

+ (UIImage *)imageWithSize:(CGSize)size color:(UIColor *)color background:(UIColor *)backgroundColor
{
    if (!initialized) {
        [self initialize];
    }

    NSString* imageKey = [self keyForSize:size color:color background:backgroundColor];
    UIImage* storedImage = [imageDictionary objectForKey:imageKey];
    if (storedImage) return storedImage;

    // size.width *= [UIScreen mainScreen].scale;
    // size.height *= [UIScreen mainScreen].scale;

    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        UIGraphicsEndImageContext();
        return nil;
    }

    [self buildImageWithSize:size color:color background:backgroundColor context:context];

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [imageDictionary setObject:newImage forKey:imageKey];
    
    return newImage;
}

+ (void)initialize
{
    imageDictionary = [NSMutableDictionary dictionary];
    initialized = YES;
}

+ (void)voidCache
{
    if (!initialized) {
        [self initialize];
    }

    [imageDictionary removeAllObjects];
}

@end
