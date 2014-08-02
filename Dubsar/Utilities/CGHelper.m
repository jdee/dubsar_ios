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

#import "CGHelper.h"

static BOOL initialized = NO;
static NSMutableDictionary* imageDictionary;

@implementation CGHelper

+ (NSString*)keyForSize:(CGSize)size firstColor:(UIColor*)firstColor secondColor:(UIColor*)secondColor
{
    CGFloat firstRed=0, firstGreen=0, firstBlue=0, firstAlpha=0;
    [firstColor getRed:&firstRed green:&firstGreen blue:&firstBlue alpha:&firstAlpha];
    CGFloat secondRed=0, secondGreen=0, secondBlue=0, secondAlpha=0;
    [secondColor getRed:&secondRed green:&secondGreen blue:&secondBlue alpha:&secondAlpha];

    return [NSString stringWithFormat:@"%.1fx%.1f:%02x%02x%02x%02x:%02x%02x%02x%02x", size.width, size.height, (int)firstRed*255, (int)firstGreen*255, (int)firstBlue*255, (int)firstAlpha*255,
            (int)secondRed*255, (int)secondGreen*255, (int)secondBlue*255, (int)secondAlpha*255];
}

+ (UIImage *)gradientImageFirstColor:(UIColor *)firstColor secondColor:(UIColor *)secondColor size:(CGSize)size startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    if (!initialized) {
        [self initialize];
    }

    NSString* imageKey = [self keyForSize:size firstColor:firstColor secondColor:secondColor];
    UIImage* storedImage = [imageDictionary objectForKey:imageKey];
    if (storedImage) return storedImage;

    size.width *= [UIScreen mainScreen].scale;
    size.height *= [UIScreen mainScreen].scale;

    UIGraphicsBeginImageContext(size);

    [self paintGradientFirstColor:firstColor secondColor:secondColor bounds:CGRectMake(0, 0, size.width, size.height) startPoint:startPoint endPoint:endPoint];

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [imageDictionary setObject:newImage forKey:imageKey];
    
    return newImage;
}

+ (void)paintGradientFirstColor:(UIColor *)firstColor secondColor:(UIColor *)secondColor bounds:(CGRect)bounds startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorRefs[2] = { firstColor.CGColor, secondColor.CGColor };
    CFArrayRef colors = CFArrayCreate(kCFAllocatorDefault, (const void**)colorRefs, 2, NULL);

    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, colors, NULL);
    CFRelease(colors);
    CFRelease(colorSpace);

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddRect(context, bounds);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    CFRelease(gradient);
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

@end
