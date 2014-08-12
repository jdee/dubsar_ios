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

#import "Dubsar-Swift.h"
#import "UIApplication+NetworkRefCount.h"
#import "Bookmark.h"

@implementation Bookmark

- (instancetype)initWithUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        _url = url;
        [self getModelforURL];
        assert(_model);
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:Bookmark.class]) {
        return NO;
    }

    Bookmark* bookmark = object;
    return [_url isEqual:bookmark.url];
}

- (void)setUrl:(NSURL *)url
{
    _url = url;
    [self getModelforURL];
}

- (void)getModelforURL
{
    NSString* path = _url.path;
    NSArray* components = [path componentsSeparatedByString:@"/"];

    assert(((NSString*)components[0]).length == 0); // starts with /

    if (![components[1] isEqualToString:@"words"]) {
        return;
    }

    int wordId = ((NSString*)components[2]).intValue;
    _model = [DubsarModelsWord wordWithId:wordId name:nil partOfSpeech:DubsarModelsPartOfSpeechUnknown];
}

- (void)loadComplete:(DubsarModelsModel *)model withError:(NSString *)error
{
    [_manager bookmarkLoaded:self];
}

- (void)networkLoadFinished:(DubsarModelsModel *)model
{
    [[UIApplication sharedApplication] stopUsingNetwork];
}

- (void)networkLoadStarted:(DubsarModelsModel *)model
{
    [[UIApplication sharedApplication] startUsingNetwork];
}

@end
