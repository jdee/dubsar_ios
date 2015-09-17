/*
 Dubsar Dictionary Project
 Copyright (C) 2010-15 Jimmy Dee

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
// DEBT: Should I/can I just ditch the kSecAttrKeyType here, since I only have one type of key?
enum {
    CSSM_ALGID_NONE           =                   0x00000000L,
    CSSM_ALGID_VENDOR_DEFINED = CSSM_ALGID_NONE + 0x80000000L,
    CSSM_ALGID_AES
};

#import "AESKey.h"

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

- (instancetype)init
{
    self = [super init];
    return self;
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
    self.key = self.loadKey;
    if (!self.key) {
        self.key = self.createKey;
    }

    assert(self.key);

}

- (BOOL)rekey
{
    if (![self deleteKey]) return NO;

    self.key = self.createKey;
    return YES;
}

- (void)initQuery
{
    _queryParameters = [NSMutableDictionary dictionary];
    _queryParameters[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    _queryParameters[(__bridge id)kSecAttrApplicationTag] = _identifier;
    _queryParameters[(__bridge id)kSecAttrKeyType] = @(CSSM_ALGID_AES);
    _queryParameters[(__bridge id)kSecAttrKeySizeInBits] = @(kCCKeySizeAES256 * 8);
    _queryParameters[(__bridge id)kSecAttrEffectiveKeySize] = @(kCCKeySizeAES256 * 8);
    _queryParameters[(__bridge id)kSecAttrCanDecrypt] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrCanEncrypt] = (__bridge id)(kCFBooleanTrue);
    _queryParameters[(__bridge id)kSecAttrCanSign] = (__bridge id)(kCFBooleanFalse);
    _queryParameters[(__bridge id)kSecAttrCanVerify] = (__bridge id)(kCFBooleanFalse);
}

- (NSData *)encrypt:(NSData *)clearText
{
    size_t outputSize = 2 * kCCBlockSizeAES128 + clearText.length; // another kCCBlockSizeAES128 for the iv
    unsigned char* output = malloc(outputSize);

    size_t movedSize = 0;
    SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, output);

    const unsigned char* bytes = (const unsigned char*)self.key.bytes;
    DMTRACE(@"Encrypting %ld bytes into %zu-byte buffer", (long)clearText.length, outputSize);
    DMTRACE(@"Using key:");
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[16], bytes[17], bytes[18], bytes[19], bytes[20], bytes[21], bytes[22], bytes[23]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[24], bytes[25], bytes[26], bytes[27], bytes[28], bytes[29], bytes[30], bytes[31]);
    DMTRACE(@"Clear text:");
    DMDUMP(clearText);

    CCCryptorStatus status = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, bytes, kCCKeySizeAES256, output, clearText.bytes, clearText.length, output+kCCBlockSizeAES128, outputSize-kCCBlockSizeAES128, &movedSize);
    if (status != kCCSuccess) {
        DMERROR(@"CCCrypt(encrypt) returned %d", status);
        free(output);
        return nil;
    }

    NSData* data = [NSData dataWithBytes:output length:movedSize+kCCBlockSizeAES128];

    DMTRACE(@"Encrypted:");
    DMDUMP(data);

    free(output);
    return data;
}

- (NSData *)decrypt:(NSData *)cipherText
{
    size_t movedSize = 0;
    size_t outputSize = kCCBlockSizeAES128 + cipherText.length;
    unsigned char* output = malloc(outputSize);

    const unsigned char* bytes = (const unsigned char*)self.key.bytes;
    DMTRACE(@"Decrypting %ld bytes into %zu-byte buffer", (long)cipherText.length, outputSize);
    DMTRACE(@"Using key:");
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[16], bytes[17], bytes[18], bytes[19], bytes[20], bytes[21], bytes[22], bytes[23]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[24], bytes[25], bytes[26], bytes[27], bytes[28], bytes[29], bytes[30], bytes[31]);
    DMTRACE(@"Cipher text:");
    DMDUMP(cipherText);

    CCCryptorStatus status = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, bytes, kCCKeySizeAES256, cipherText.bytes, cipherText.bytes+kCCBlockSizeAES128, cipherText.length-kCCBlockSizeAES128, output, outputSize, &movedSize);
    if (status != kCCSuccess) {
        DMERROR(@"CCCrypt(decrypt) returned %d", status);
        free(output);
        return nil;
    }

    NSData* result = [NSData dataWithBytes:output length:movedSize];

    DMTRACE(@"Decrypted:");
    DMDUMP(result);

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

        if (length != kCCKeySizeAES256) {
            CFRelease(returnedKey);
            if ((rc=SecItemDelete((__bridge CFDictionaryRef)query)) != noErr) {
                DMERROR(@"Error deleting key: %d", rc);
            }
            return nil;
        }

        const unsigned char* bytes = (const unsigned char*)CFDataGetBytePtr(cfdata);

        DMTRACE(@"Loaded key:");
        DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7]);
        DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]);
        DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[16], bytes[17], bytes[18], bytes[19], bytes[20], bytes[21], bytes[22], bytes[23]);
        DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", bytes[24], bytes[25], bytes[26], bytes[27], bytes[28], bytes[29], bytes[30], bytes[31]);

        NSData* returnValue = [NSData dataWithBytes:bytes length:length];
        CFRelease(returnedKey);

        DMDEBUG(@"Loaded %d-bit AES key from keychain.", returnValue.length*8);
        return returnValue;
    }

    if (rc != errSecItemNotFound) {
        DMWARN(@"SecItemCopyMatching returned %d", rc);
    }

    return nil;
}

- (NSData*)createKey
{
    unsigned char* buffer = malloc(kCCKeySizeAES256);
    OSStatus rc;
    if ((rc=SecRandomCopyBytes(kSecRandomDefault, kCCKeySizeAES256, buffer)) != noErr) {
        DMERROR(@"Failed to generate random key: %d", rc);
    }

    [self deleteKey];

    NSData* newKey = [[NSData alloc] initWithBytes:&buffer[0] length:kCCKeySizeAES256];
    self.queryParameters[(__bridge id)kSecValueData] = newKey;

    if ((rc=SecItemAdd((__bridge CFDictionaryRef)self.queryParameters, NULL)) != noErr) {
        DMERROR(@"SecItemAdd failed. Error %d", rc);
    }

    DMTRACE(@"Generated new key:");
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5], buffer[6], buffer[7]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", buffer[8], buffer[9], buffer[10], buffer[11], buffer[12], buffer[13], buffer[14], buffer[15]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", buffer[16], buffer[17], buffer[18], buffer[19], buffer[20], buffer[21], buffer[22], buffer[23]);
    DMTRACE(@"%02x %02x %02x %02x %02x %02x %02x %02x", buffer[24], buffer[25], buffer[26], buffer[27], buffer[28], buffer[29], buffer[30], buffer[31]);

    free(buffer);

    DMTRACE(@"Wrote %ld-bit AES key to keychain.", newKey.length*8);

    return newKey;
}

- (BOOL)deleteKey
{
    self.key = nil;

    NSDictionary* query = @{ (__bridge id)kSecClass: (__bridge id)kSecClassKey,
                             (__bridge id)kSecAttrApplicationTag: _identifier,
                             (__bridge id)kSecAttrKeyType: @(CSSM_ALGID_AES) };

    OSStatus rc;
    if ((rc=SecItemDelete((__bridge CFDictionaryRef)query)) != noErr && rc != errSecItemNotFound) {
        DMERROR(@"SecItemDelete returned %d", rc);
        return NO;
    }
    return YES;
}

@end
