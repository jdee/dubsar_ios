// https://stackoverflow.com/questions/392464/how-do-i-do-base64-encoding-on-iphone-sdk

@import Foundation;

@interface NSString (NSStringAdditions)

+ (NSString *) base64StringFromData:(NSData *)data;

@end
