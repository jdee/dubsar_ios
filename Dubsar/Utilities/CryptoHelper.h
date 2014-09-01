//
//  CryptoHelper.h
//  
//
//  Created by Jimmy Dee on 9/1/14.
//
//

@import Foundation;

@interface CryptoHelper : NSObject

- (NSString*)encrypt:(NSString*)clearText;
- (NSString*)decrypt:(NSString*)encrypted;

@end
