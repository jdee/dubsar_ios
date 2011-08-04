/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
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

#import "Dubsar.h"
#import "FAQViewController_iPad.h"

@implementation FAQViewController_iPad
@synthesize webView;
@synthesize url;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Dubsar Mobile FAQ";
        NSString *_url = @"http://m.dubsar-dictionary.com/m_faq";
        url = [[NSURL URLWithString:_url]retain];    
        ready = false;
    }
    return self;
}

- (void)dealloc
{
    [url release];
    [webView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
     
    // [self displayMessage:@"loading..." url:[NSURL URLWithString:@"about:blank"]];
    [self displayMessage:@"loading..." url:url];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];    
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
    if (!ready) return ;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    if (!ready) {
        NSURLRequest* request = [NSURLRequest requestWithURL:url];
        [webView loadRequest:request];
        ready = true;
        return;
    }

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
    
    NSString* errMsg = [error localizedDescription];
    UIAlertView* alertView = [[[UIAlertView alloc]initWithTitle:@"Network Error" message:errMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease];
    [alertView show];
    [self displayMessage:errMsg url:url];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)displayMessage:(NSString*)text url:(NSURL *)baseUrl
{
    // NSURL* baseUrl = [NSURL URLWithString:@""];
    [webView loadHTMLString:[NSString stringWithFormat:@"<html><body style=\"background-color: #e0e0ff;\"><h1 style=\"color: #1c94c4; text-align: center; margin-top: 2ex; font: bold 24pt Trebuchet MS;\">%@</h1></body></html>", text ] baseURL:baseUrl];
    
}

@end
