/*
 Dubsar Dictionary Project
 Copyright (C) 2010-14 Jimmy Dee

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

@import Security;
@import DubsarModels;

#import <CommonCrypto/CommonCrypto.h> // not @import CommonCrypto

// From Apple's CryptoExercise sample. This seems to be arbitrary, but what the hell?
enum {
    CSSM_ALGID_NONE =					0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED =			CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

#import "AESKey.h"

// Would prefer 256, but this seems to be what's available.
#define DUBSAR_KEY_LENGTH_BITS 128

@interface AESKey()

@property (nonatomic) NSData* key;
@property (nonatomic) NSMutableDictionary* queryParameters;

@property (nonatomic, readonly) NSData* loadKey, *createKey;

@end

@implementation AESKey

+ (instancetype)keyWithIdentifier:(NSString *)identifier
{
    return [[self alloc] initWithIdentifier:identifier];
}

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _identifier = identifier;

        [self initQuery];
        [self initKey];
    }
    return self;
}

- (void)initKey
{
    // force creation of a new key
    // [self deleteKey];

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
    _queryParameters[(__bridge id)kSecAttrApplicationTag] = _identifier;
    _queryParameters[(__bridge id)kSecAttrKeySizeInBits] = @(DUBSAR_KEY_LENGTH_BITS);
    _queryParameters[(__bridge id)kSecAttrEffectiveKeySize] = @(DUBSAR_KEY_LENGTH_BITS);
    _queryParameters[(__bridge id)kSecAttrCanDecrypt] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrCanEncrypt] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrCanSign] = (__bridge id)(kCFBooleanFalse);
    _queryParameters[(__bridge id)kSecAttrCanVerify] = (__bridge id)(kCFBooleanFalse);
    _queryParameters[(__bridge id)kSecAttrKeyType] = @(CSSM_ALGID_AES);
}

- (NSData *)encrypt:(NSData *)clearText
{
    uint8_t iv[16];
    SecRandomCopyBytes(kSecRandomDefault, sizeof(iv), iv);

    size_t outputSize = DUBSAR_KEY_LENGTH_BITS/sizeof(unsigned char)/8 + clearText.length + sizeof(iv);
    unsigned char* output = malloc(outputSize);

    size_t movedSize = 0;
    memcpy(output, iv, sizeof(iv));

    CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, (__bridge const void *)self.key, DUBSAR_KEY_LENGTH_BITS/8, iv, clearText.bytes, clearText.length, output+sizeof(iv), outputSize-sizeof(iv), &movedSize);
    if (status != kCCSuccess) {
        DMERROR(@"CCCrypt(encrypt) returned %d", status);
        free(output);
        return nil;
    }

    NSData* data = [NSData dataWithBytes:output length:movedSize+sizeof(iv)];

    free(output);
    return data;
}

- (NSData *)decrypt:(NSData *)cipherText
{
    size_t movedSize = 0;
    size_t outputSize = DUBSAR_KEY_LENGTH_BITS/sizeof(unsigned char)/8 + cipherText.length;
    unsigned char* output = malloc(outputSize);

    DMTRACE(@"Decrypting %ld bytes into %zu-byte buffer", (long)cipherText.length, outputSize);

    CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, (__bridge const void*)self.key, DUBSAR_KEY_LENGTH_BITS/8, cipherText.bytes, cipherText.bytes+16, cipherText.length-16, output, outputSize, &movedSize);
    if (status != kCCSuccess) {
        DMERROR(@"CCCrypt(decrypt) returned %d", status);
        free(output);
        return nil;
    }

    NSData* result = [NSData dataWithBytes:output length:movedSize];
    free(output);
    return result;
}

- (NSData*)loadKey
{
    NSDictionary* query = @{ (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                             (__bridge id)kSecAttrApplicationTag: _identifier,
                             (__bridge id)kSecAttrKeyType: @(CSSM_ALGID_AES),
                             (__bridge id)kSecReturnData: @(YES) };

    CFTypeRef returnedKey;

    OSStatus rc = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &returnedKey);
    if (rc == noErr && returnedKey) {
        CFDataRef cfdata = (CFDataRef)returnedKey;
        CFIndex length = CFDataGetLength(cfdata);

        DMTRACE(@"Keychain data length: %d", length);

        if (length == 0) {
            CFRelease(returnedKey);
            if ((rc=SecItemDelete((__bridge CFDictionaryRef)query)) != noErr) {
                DMERROR(@"Error deleting empty key: %d", rc);
            }
            return nil;
        }

        const void* bytes = CFDataGetBytePtr(cfdata);
        NSData* returnValue = [NSData dataWithBytes:bytes length:length];
        CFRelease(returnedKey);

        DMDEBUG(@"Loaded %d-bit AES key from keychain", returnValue.length*8);
        return returnValue;
    }

    if (rc != errSecItemNotFound) {
        DMWARN(@"SecItemCopyMatching returned %d", rc);
    }

    return nil;
}

- (NSData*)createKey
{
    unsigned char* buffer = malloc(DUBSAR_KEY_LENGTH_BITS/sizeof(unsigned char)/8); // 8 bits per byte
    OSStatus rc;
    if ((rc=SecRandomCopyBytes(kSecRandomDefault, DUBSAR_KEY_LENGTH_BITS/sizeof(unsigned char)/8, buffer)) != noErr) {
        DMERROR(@"Failed to generate random key: %d", rc);
    }

    [self deleteKey];

    NSData* newKey = [[NSData alloc] initWithBytes:&buffer[0] length:DUBSAR_KEY_LENGTH_BITS/sizeof(unsigned char)/8];
    self.queryParameters[(__bridge id)kSecValueData] = newKey;

    if ((rc=SecItemAdd((__bridge CFDictionaryRef)self.queryParameters, NULL)) != noErr) {
        DMERROR(@"SecItemAdd failed. Error %d", rc);
    }

    free(buffer);

    DMDEBUG(@"Wrote %ld-bit AES key to keychain", newKey.length*8);

    return newKey;
}

- (void)deleteKey
{
    OSStatus rc;
    if ((rc=SecItemDelete((__bridge CFDictionaryRef)self.queryParameters)) != noErr && rc != errSecItemNotFound) {
        DMERROR(@"SecItemDelete returned %d", rc);
    }
}

@end
