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

#import "Augury.h"
#import "AuguryViewController_iPad.h"

@interface AuguryViewController_iPad ()

@end

@implementation AuguryViewController_iPad
@synthesize augury;
@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.augury = [NSString string];
        self.title = @"Augury";
    }
    return self;
}

- (void)augur
{
    Augury* _augury = [Augury augury];
    [_augury load];
    self.augury = [self.augury stringByAppendingFormat:@"<p>%@</p>", _augury.text];
    [self loadPage:augury];
    
}

- (void)loadPage:(NSString*)html
{
    NSString* format = @"<!DOCTYPE html><html><head><title>Augury</title></head><body style=\"background-color: #e0e0ff;\"><h1 style=\"color: #1c94c4; text-align: center; margin-top: 2ex; font: bold 18pt Trebuchet MS\">%@<script>window.scrollTo(0, document.body.scrollHeight);</script></body></html>";
    NSString* page = [NSString stringWithFormat:format, html];
    [webView loadHTMLString:page baseURL:[NSURL URLWithString:@"http://localhost/augury"]];
}

- (void)clear:(id)sender
{
    self.augury = [NSString string];
    [self loadPage:augury];
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error
{
    NSString* errMsg = [error localizedDescription];
    NSLog(@"web view fail: %@", errMsg);
}

@end
