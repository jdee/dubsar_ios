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

#import "NavButtonImage.h"

static BOOL initialized = NO;
static NSMutableDictionary* imageDictionary;

@implementation NavButtonImage

+ (NSString*)keyForSize:(CGSize)size color:(UIColor*)color
{
    CGFloat red=0, green=0, blue=0, alpha=0;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    return [NSString stringWithFormat:@"%.1fx%.1f:%02x%02x%02x%02x", size.width, size.height, (int)red*255, (int)green*255, (int)blue*255, (int)alpha*255];
}

+ (UIImage*)imageWithSize:(CGSize)size color:(UIColor *)color
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

+ (void)voidCache
{
    if (!initialized) {
        [self initialize];
    }

    [imageDictionary removeAllObjects];
}

+ (void)initialize
{
    imageDictionary = [NSMutableDictionary dictionary];
    initialized = YES;
}

+ (void)buildImageWithSize:(CGSize)size color:(UIColor*)color context:(CGContextRef)context
{
    // use CG to draw in this context and return a UIImage for use with a UIButton.
    // a/k/a FREEDOM FROM THE @!$@# GIMP!

    // transparent background
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));

    // black triangle pointing right. equilateral when width = height.
    CGContextMoveToPoint(context, size.width * 0.25, size.height * 0.212);
    CGContextAddLineToPoint(context, size.width * 0.25, size.height * 0.788);
    CGContextAddLineToPoint(context, size.width * 0.75, size.height * 0.5);

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
}

@end
