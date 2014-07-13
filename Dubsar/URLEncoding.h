@import Foundation;

/*
 * Taken from http://madebymany.com/blog/url-encoding-an-nsstring-on-ios
 */

@interface NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding;
@end
