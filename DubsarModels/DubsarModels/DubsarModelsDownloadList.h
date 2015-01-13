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

#import "DubsarModelsModel.h"

#define DUBSAR_DOWNLOAD_PREFIX @"dubsar-wn"

/*
 * DEBT: It's pretty clear that this needs to become a full-fledged model on its own. It will have to override
 * most of the NSURLConnection handling, but it can take advantage of a lot of the machinery that's in this
 * framework, like the reachability stuff, which will work perfectly well even if the zip is downloaded from
 * a completely different network interface from the REST service.
 */
@interface DubsarModelsDownload : NSObject
@property (nonatomic, copy) NSString* name;
@property (nonatomic) NSDictionary* properties;

@property (nonatomic, readonly) NSUInteger zippedSize;
@property (nonatomic, readonly) NSUInteger unzippedSize;
@property (nonatomic, readonly) int version;

+ (int)versionFromDownloadName:(NSString*)name;

@end

@interface DubsarModelsDownloadList : DubsarModelsModel

@property (nonatomic) NSArray* downloads;

@end
