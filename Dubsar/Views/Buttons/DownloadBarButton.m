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
        _borderLayer = [CALayer layer];
        _borderLayer.opaque = NO;
        _borderLayer.backgroundColor = [UIColor clearColor].CGColor;
        _borderLayer.position = CGPointMake(0.5 * self.bounds.size.width, 0.5 * self.bounds.size.height);
        _borderLayer.bounds = CGRectMake(0, 0, 0.75 * self.bounds.size.width, 0.75 * self.bounds.size.height);

        _borderLayer.cornerRadius = 0.1 * sqrt(self.bounds.size.width * self.bounds.size.height);
        _borderLayer.borderColor = self.currentTitleColor.CGColor;
        _borderLayer.borderWidth = 1.0;

        [self.layer addSublayer:_borderLayer];

        [self addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [DownloadButtonImage buildImageWithSize:self.bounds.size color:self.currentTitleColor background:self.backgroundColor context:UIGraphicsGetCurrentContext()];
    _borderLayer.borderColor = self.currentTitleColor.CGColor;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)buttonPressed:(UIButton*)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([_target respondsToSelector:_action]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_target performSelector:_action withObject:_barButtonItem];
        });
    }
#pragma clang diagnostic pop
}

@end
