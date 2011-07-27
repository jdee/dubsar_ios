//
//  FAQViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SearchBarViewController_iPad;

@interface FAQViewController_iPad : UIViewController <UIWebViewDelegate> {
    
    UIWebView *webView;
}

@property (nonatomic, assign) SearchBarViewController_iPad* searchBarViewController;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

@end
