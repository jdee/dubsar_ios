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

#import "IntroViewController_iPad.h"

@interface IntroViewController_iPad ()

@end

@implementation IntroViewController_iPad
@synthesize webView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [webView loadHTMLString:[self htmlForAuguryIntro] baseURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)htmlForAuguryIntro
{
    return
        @"<!DOCTYPE html>"
        "<html>"
            "<body style='color:#1c94c4; background-color:#fff; font: bold 12pt Trebuchet MS; text-align: center;'>"
                "Augury was one of the main occupations of the ancient <em>dubsar</em>, "
                "cataloging omens in order to predict the future. The Dubsar app now also speaks "
                "mysteriously when asked, using WordNet&reg;&apos;s generic verb frames and "
                "randomly-selected words to construct arbitrary sentences. Tap the Augur button "
                "to try it. See the FAQ for further information."
            "</body>"
        "</html>";
}

@end
