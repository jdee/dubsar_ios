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
@dynamic zippedSize, unzippedSize;

+ (int)versionFromDownloadName:(NSString *)name
{
    DubsarModelsDownload* dl = [[self alloc] init];
    dl.name = name;
    return dl.version;
}

- (NSUInteger)zippedSize
{
    return ((NSNumber*)_properties[@"zipped"]).integerValue;
}

- (NSUInteger)unzippedSize
{
    return ((NSNumber*)_properties[@"unzipped"]).integerValue;
}

- (int)version
{
    if (![_name hasPrefix:DUBSAR_DOWNLOAD_PREFIX]) {
        return 0;
    }

    // /^dubsar-wn3.1-([0-9]+)$/
    return ((NSString*)[_name componentsSeparatedByString:@"-"].lastObject).intValue;
}
@end

@implementation DubsarModelsDownloadList

- (instancetype)init
{
    self = [super init];
    if (self) {
        _url = @"/downloads";
        self.retriesWhenAvailable = YES;
    }
    return self;
}

- (void)load
{
    [self loadFromServer];
}

- (void)parseData
{
    NSArray* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];

    NSMutableArray* dls = [NSMutableArray array];

    for (NSDictionary* dl in response) {
#ifndef DEBUG
        if (dl[@"dev"]) continue;
#endif // DEBUG
        DubsarModelsDownload* download = [[DubsarModelsDownload alloc] init];
        download.name = dl[@"name"];
        NSMutableDictionary* props = [dl mutableCopy];
        [props removeObjectForKey:@"name"];
        download.properties = props;

        [dls addObject:download];
    }

    _downloads = dls;
}

@end
