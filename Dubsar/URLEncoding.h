//
//  URLEncoding.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/25/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 * Taken from http://madebymany.com/blog/url-encoding-an-nsstring-on-ios
 */

@interface NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
@end
