//
//  FAQViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FAQViewController_iPhone : UIViewController <UIWebViewDelegate> {
    
    UIWebView *webView;
}

@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
- (IBAction)dismiss:(id)sender;

@end
