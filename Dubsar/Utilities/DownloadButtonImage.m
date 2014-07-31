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

+ (NSString*)keyForSize:(CGSize)size color:(UIColor*)color
{
    CGFloat red=0, green=0, blue=0, alpha=0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return [NSString stringWithFormat:@"%.1fx%.1f:%02x%02x%02x%02x", size.width, size.height, (int)red*255, (int)green*255, (int)blue*255, (int)alpha*255];
}

+ (UIImage *)imageWithSize:(CGSize)size color:(UIColor *)color
{
    if (!initialized) {
        [self initialize];
    }

    NSString* imageKey = [self keyForSize:size color:color];
    UIImage* storedImage = [imageDictionary objectForKey:imageKey];
    if (storedImage) return storedImage;

    size.width *= [UIScreen mainScreen].scale;
    size.height *= [UIScreen mainScreen].scale;

    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        UIGraphicsEndImageContext();
        return nil;
    }

    [self buildImageWithSize:size color:color context:context];

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

/*
 * Makes a download button: an arrow pointing downward toward a horizontal
 * line across the bottom.
 */
+ (void)buildImageWithSize:(CGSize)size color:(UIColor*)color context:(CGContextRef)context
{
    // use CG to draw in this context and return a UIImage for use with a UIButton.
    // a/k/a FREEDOM FROM THE @!$@# GIMP!

    // transparent background
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

    // All strokes. Set color and line width.
    CGFloat lineWidth = 0.03 * sqrt(size.width * size.height);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, lineWidth);

    // Vertical line down the center
    CGContextMoveToPoint(context, 0.5 * size.width, 0.2 * size.height);
    CGContextAddLineToPoint(context, 0.5 * size.width, 0.7 * size.height);
    CGContextStrokePath(context);

    // Left half of arrow head
    CGContextMoveToPoint(context, 0.35 * size.width, 0.55 * size.height);
    CGContextAddLineToPoint(context, 0.5 * size.width, 0.7 * size.height);
    CGContextStrokePath(context);

    // Right half of arrow head
    CGContextMoveToPoint(context, 0.65 * size.width, 0.55 * size.height);
    CGContextAddLineToPoint(context, 0.5 * size.width, 0.7 * size.height);
    CGContextStrokePath(context);

    // Horizontal line across the bottom
    CGContextMoveToPoint(context, 0.2 * size.width, 0.8 * size.height);
    CGContextAddLineToPoint(context, 0.8 * size.width, 0.8 * size.height);
    CGContextStrokePath(context);
}

@end
