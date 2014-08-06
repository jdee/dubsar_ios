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

#import "DubsarModelsLogger.h"

/*
void DMLOG(NSString* format, ...)
{
    va_list args;
    va_start(args, format);

    [DubsarModelsLogger log:format args:args];

    va_end(args);
}
 */

@implementation DubsarModelsLogger

+ (void)log:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);

    [self log:format args:args];

    va_end(args);
}

+ (void)log:(NSString *)format args:(va_list)args
{
    char buffer[512];
    vsnprintf(buffer, 511, format.UTF8String, args); // vsnprintf and friends don't understand %@, and there's no equivalent to stringWithFormat: that takes a va_list.

    NSLog(@"%s", buffer);
}

@end
