//
//  URLEncoding.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/25/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "URLEncoding.h"


@implementation NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding 
{
	return (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", CFStringConvertNSStringEncodingToEncoding(encoding));
}

@end
