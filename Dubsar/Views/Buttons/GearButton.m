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

@interface GearLayer: CALayer

@property (nonatomic) NSInteger numTeeth;
@property (nonatomic) CGFloat outerToothRatio;
@property (nonatomic) CGFloat innerToothRatio;
@property (nonatomic) CGFloat innerRingRatio;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) UIColor* color;

#define DUBSAR_GEAR_ROTATION_KEY @"GearRotation"

+ (instancetype)layer;

@end

@implementation GearLayer

+ (instancetype)layer {
    return [[self alloc] init];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (void)display
{
    const CGFloat scale = [UIScreen mainScreen].scale;
    const CGFloat width = self.bounds.size.width * scale;
    const CGFloat height = self.bounds.size.height * scale;

    const CGFloat dimension = MIN(width, height);

    const CGFloat deltaTheta = 2.0 * M_PI / (CGFloat)_numTeeth;

    CGFloat theta = -0.125 * deltaTheta;
    CGFloat radius = _outerToothRatio * dimension;

    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, 0.5*width + cos(theta)*radius, 0.5*height + sin(theta)*radius);

    for (int j=0; j<_numTeeth; ++j) {
        theta = ((CGFloat)j - 0.125) * deltaTheta;
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

    CGContextSetLineWidth(context, scale * _lineWidth);
    CGContextSetLineJoin(context, kCGLineJoinMiter);
    CGContextSetStrokeColorWithColor(context, _color.CGColor);
    CGContextSetShouldAntialias(context, true);
    CGContextStrokePath(context);

    if (_innerRingRatio <= 0.0) return;

    CGContextAddArc(context, 0.5*width, 0.5*height, _innerRingRatio*MIN(width, height), 0, 2.0*M_PI, NO);
    CGContextStrokePath(context);

    UIImage* gearImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.contents = (id)gearImage.CGImage;
}

@end

@implementation GearButton {
    GearLayer* gearLayer;
}

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
        _animating = NO;

        [self setupGearLayer];
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    gearLayer.color = self.currentTitleColor;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    gearLayer.color = self.currentTitleColor;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    gearLayer.color = self.currentTitleColor;
}

- (void)setNumTeeth:(NSUInteger)numTeeth
{
    _numTeeth = numTeeth;
    gearLayer.numTeeth = numTeeth;
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    gearLayer.lineWidth = lineWidth;
}

- (void)setInnerRingRatio:(CGFloat)innerRingRatio
{
    _innerRingRatio = innerRingRatio;
    gearLayer.innerRingRatio = innerRingRatio;
}

- (void)setInnerToothRatio:(CGFloat)innerToothRatio
{
    _innerToothRatio = innerToothRatio;
    gearLayer.innerToothRatio = innerToothRatio;
}

- (void)setOuterToothRatio:(CGFloat)outerToothRatio
{
    _outerToothRatio = outerToothRatio;
    gearLayer.outerToothRatio = outerToothRatio;
}

- (void)startAnimating
{
    self.enabled = NO;
    _animating = YES;

    [self animateOnceAround];
}

- (void)stopAnimating
{
    self.enabled = YES;
    _animating = NO;

    [gearLayer removeAnimationForKey:DUBSAR_GEAR_ROTATION_KEY];
}

- (void)setupGearLayer
{
    gearLayer = [GearLayer layer];
    gearLayer.numTeeth = _numTeeth;
    gearLayer.innerRingRatio = _innerRingRatio;
    gearLayer.innerToothRatio = _innerToothRatio;
    gearLayer.outerToothRatio = _outerToothRatio;
    gearLayer.lineWidth = _lineWidth;
    gearLayer.position = CGPointMake(0.5 * self.bounds.size.width, 0.5 * self.bounds.size.height);
    gearLayer.bounds = self.bounds;
    gearLayer.opaque = NO;
    gearLayer.backgroundColor = [UIColor clearColor].CGColor;

    gearLayer.transform = CATransform3DMakeRotation(_rotation, 0, 0, 1);

    [self.layer addSublayer:gearLayer];
}

- (void)animateOnceAround
{
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.fromValue = @(_rotation);
    animation.toValue = @(_rotation + 2.0*M_PI);
    animation.duration = 4.0;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    /*
     * Under some circumstances (like whenever this button is pressed), I cannot get the display link to fire
     * before the new VC is loaded and pushed. This has been the only way I can animate the button for an
     * indefinite amount of time. After each revolution, if it is still animating, it simply calls this
     * method again.
     */
    [CATransaction setCompletionBlock:^{
        if (_animating) {
            [self animateOnceAround];
        }
    }];

    gearLayer.transform = CATransform3DMakeRotation(_rotation + 2.0*M_PI, 0, 0, 1);
    [gearLayer addAnimation:animation forKey:DUBSAR_GEAR_ROTATION_KEY];

    [CATransaction commit];
}

@end
