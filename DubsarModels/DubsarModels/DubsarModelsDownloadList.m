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

#import "DubsarModelsDownloadList.h"

@implementation DubsarModelsDownload
@end

@implementation DubsarModelsDownloadList

- (instancetype)init
{
    self = [super init];
    if (self) {
        _url = @"/downloads";
    }
    return self;
}

- (void)load
{
    [self loadFromServer];
}

- (void)parseData
{
    NSDictionary* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];

    NSEnumerator* keyEnumerator = response.keyEnumerator;
    NSString* key;

    NSMutableArray* dls = [NSMutableArray array];

    while ((key=keyEnumerator.nextObject)) {
        NSDictionary* properties = response[key];

        DubsarModelsDownload* download = [[DubsarModelsDownload alloc] init];
        download.name = key;
        download.properties = properties;

        [dls addObject:download];
    }

    _downloads = dls;
}

@end
