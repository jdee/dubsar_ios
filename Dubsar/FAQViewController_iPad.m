//
//  FAQViewController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

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
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;   
    
    NSString* errMsg = [error localizedDescription];
    UIAlertView* alertView = [[[UIAlertView alloc]initWithTitle:@"Network Error" message:errMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil]autorelease];
    [alertView show];
    
    [theWebView loadHTMLString:[NSString stringWithFormat:@"<html><body><h1 style=\"text-align: center;\">%@</h1></body></html>", errMsg ] baseURL:url];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
