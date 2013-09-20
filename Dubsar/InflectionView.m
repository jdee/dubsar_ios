/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee

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

#import "InflectionView.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

@implementation InflectionView
@synthesize word;

- (id)initWithFrame:(CGRect)frame word:(Word *)theWord
{
    self = [super initWithFrame:frame];
    if (self) {
        self.word = theWord;
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (void)load
{
    [self loadHTMLString:self.htmlInflections baseURL:nil];
}

- (NSString *)htmlInflections
{
    NSString* html = @"<!DOCTYPE html><html><body style='color:#f85400; background-color:#000; font: bold 12pt Trebuchet MS'><h3>Other forms for ";
    html = [html stringByAppendingFormat:@"%@</h3>", word.nameAndPos];

    if (word.freqCnt > 0) {
        html = [html stringByAppendingFormat:@"<p>freq. cnt.: %d</p>", word.freqCnt];
    }

    html = [html stringByAppendingString:@"<ul style='list-style: none;'>"];

    int j;
    for (j=0;j<word.inflections.count; ++j) {
        NSString* inflection = [word.inflections objectAtIndex:j];
        html = [html stringByAppendingFormat:@"<li>%@</li>", inflection];
    }

    html = [html stringByAppendingString:@"</ul></body></html>"];
    return html;
}

@end
