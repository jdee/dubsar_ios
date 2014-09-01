//
//  CryptoHelper.m
//  
//
//  Created by Jimmy Dee on 9/1/14.
//
//

@import Security;
@import DubsarModels;

enum {
    CSSM_ALGID_NONE =					0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED =			CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

#import "CryptoHelper.h"

#define DUBSAR_KEY_LENGTH_BITS 256

@interface CryptoHelper()

@property (nonatomic) NSData* key;
@property (nonatomic) NSMutableDictionary* queryParameters;

@property (nonatomic, readonly) NSData* loadKey, *createKey;

@end

@implementation CryptoHelper {
    NSString* identifier;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        identifier = [[NSBundle mainBundle].bundleIdentifier stringByAppendingString:@"bookmarks"];

        [self initQuery];
        [self initKey];
    }
    return self;
}

- (void)initKey
{
    self.key = self.loadKey;
    if (!self.key) {
        self.key = self.createKey;
    }

    assert(self.key);
}

- (void)initQuery
{
    _queryParameters = [NSMutableDictionary dictionary];
    _queryParameters[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    _queryParameters[(__bridge id)kSecAttrApplicationTag] = identifier;
    _queryParameters[(__bridge id)kSecAttrKeySizeInBits] = @(DUBSAR_KEY_LENGTH_BITS);
    _queryParameters[(__bridge id)kSecAttrEffectiveKeySize] = @(DUBSAR_KEY_LENGTH_BITS);
    _queryParameters[(__bridge id)kSecAttrCanDecrypt] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrCanEncrypt] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrCanSign] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrCanVerify] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrKeyType] = @(CSSM_ALGID_AES);
}

- (NSString *)encrypt:(NSString *)clearText
{
    return nil;
}

- (NSString *)decrypt:(NSString *)encrypted
{
    return nil;
}

- (NSData*)loadKey
{
    NSDictionary* query = @{ (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                             (__bridge id)kSecAttrApplicationTag: identifier,
                             (__bridge id)kSecAttrKeyType: @(CSSM_ALGID_AES),
                             (__bridge id)kSecReturnData: @(YES) };

    CFTypeRef returnedKey;

    OSStatus rc = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &returnedKey);
    if (rc == noErr && returnedKey) {
        return CFBridgingRelease(returnedKey);
    }

    DMWARN(@"SecItemCopyMatching returned %d", rc);
    return nil;
}

- (NSData*)createKey
{
    unsigned char* buffer = malloc(DUBSAR_KEY_LENGTH_BITS/sizeof(unsigned char)/8); // 8 bits per byte

    NSData* newKey = [[NSData alloc] initWithBytes:&buffer[0] length:DUBSAR_KEY_LENGTH_BITS/sizeof(unsigned char)/8];

    OSStatus rc;

    if ((rc=SecItemDelete((__bridge CFDictionaryRef)self.queryParameters)) != noErr && rc != errSecItemNotFound) {
        DMERROR(@"SecItemDelete returned %d", rc);
    }

    if ((rc=SecItemAdd((__bridge CFDictionaryRef)self.queryParameters, NULL)) != noErr) {
        DMERROR(@"SecItemAdd failed. Error %d", rc);
    }

    free(buffer);

    return newKey;
}

@end
