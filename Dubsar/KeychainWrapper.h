// http://developer.apple.com/library/ios/#documentation/Security/Conceptual/keychainServConcepts/iPhoneTasks/iPhoneTasks.html
#import <UIKit/UIKit.h>

//Define an Objective-C wrapper class to hold Keychain Services code.
@interface KeychainWrapper : NSObject

@property (nonatomic, strong) NSMutableDictionary *keychainData;
@property (nonatomic, strong) NSMutableDictionary *genericQuery;
@property (nonatomic, copy) NSString* identifier;

- (id)initWithIdentifier:(NSString*)theIdentifier requestClass:(CFTypeRef)requestClass;

- (void)mySetObject:(id)inObject forKey:(id)key;
- (id)myObjectForKey:(id)key;
- (void)resetKeychainItem;

@end
