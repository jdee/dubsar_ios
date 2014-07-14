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

#import "DubsarModelsAutocompleterDelegate.h"
#import "DubsarModelsAutocompleterProxy.h"

@implementation DubsarModelsAutocompleterProxy
@synthesize delegate;

- (void)loadComplete:(DubsarModelsModel *)model withError:(NSString *)error
{
    if (delegate) [delegate autocompleterFinished:(DubsarModelsAutocompleter*)model withError:error];
}
@end
