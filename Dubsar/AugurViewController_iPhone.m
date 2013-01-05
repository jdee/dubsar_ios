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

#import "AugurViewController_iPhone.h"
#import "Word.h"

@interface AugurViewController_iPhone ()

@end

@implementation AugurViewController_iPhone

@synthesize auguryWebView;
@synthesize augury;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.augury = [NSString string];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self augur:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) augur:(id)sender
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)UIApplication.sharedApplication.delegate;

    int frameId = rand()%170 + 36;
    int verbId = rand()%11531 + 145054;
    
    Word *word = [Word wordWithId:verbId name:nil partOfSpeech:POSVerb];
    [word loadResults:appDelegate];

    NSString* sql = [NSString stringWithFormat:@"SELECT frame FROM verb_frames WHERE id = %d",
                     frameId];
    int rc;
    sqlite3_stmt* statement;
    NSLog(@"preparing statement \"%@\"", sql);
    if ((rc=sqlite3_prepare_v2(appDelegate.database, [sql cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, NULL)) != SQLITE_OK) {
        NSLog(@"sqlite3_prepare_v2: %d", rc);
        return;
    }
    
    NSString* frameFormat = nil;
    if ((rc=sqlite3_step(statement)) == SQLITE_ROW) {
        char const* _frame = (char const*)sqlite3_column_text(statement, 0);
        frameFormat = [NSString stringWithCString:_frame encoding:NSUTF8StringEncoding];
    }
    else {
        NSLog(@"failed to find verb frame %d", rc);
        sqlite3_finalize(statement);
        return;
    }
    sqlite3_finalize(statement);
    
    NSString* wordLink = [NSString stringWithFormat:@"<a style='text-decoration: none;' href='dubsar://iPhone/words/%d'>%@</a>",
                          verbId, word.name];
    
    /*
     * The selected verb frames are all xxx %s xxx, so we convert the NSString word.name to
     * a C string and use it with the verb frame as a format.
     */
    NSString* _augury = [NSString stringWithFormat:frameFormat, [wordLink cStringUsingEncoding:NSUTF8StringEncoding]];

    self.augury = [augury stringByAppendingFormat:@"<p>%@</p>", _augury];
    
    [self loadPage:augury];
}

- (IBAction) dismiss:(id)sender
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending) {
        // iOS 5.0+
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
        // iOS 4.x
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

- (IBAction) clear:(id)sender
{
    self.augury = [NSString string];
    [self loadPage:augury];
}

- (void)loadPage:(NSString*)html
{
    NSString* format = @"<!DOCTYPE html><html><head><title>Augury</title></head><body style=\"background-color: #e0e0ff;\"><h1 style=\"color: #1c94c4; text-align: center; margin-top: 2ex; font: bold 18pt Trebuchet MS\">%@<script>window.scrollTo(0, document.body.scrollHeight);</script></body></html>";
    NSString* page = [NSString stringWithFormat:format, html];
    [auguryWebView loadHTMLString:page baseURL:[NSURL URLWithString:@"http://localhost/augury"]];
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error
{
    NSString* errMsg = [error localizedDescription];
    NSLog(@"web view fail: %@", errMsg);
}

@end
