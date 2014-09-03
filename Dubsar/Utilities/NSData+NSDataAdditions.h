// https://stackoverflow.com/questions/392464/how-do-i-do-base64-encoding-on-iphone-sdk

@import Foundation;

@class NSString;

@interface NSData (NSDataAdditions)

+ (NSData *) base64DataFromString:(NSString *)string;

@end
