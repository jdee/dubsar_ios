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

@import Foundation;

typedef NS_ENUM(NSInteger, DubsarModelsLogLevel) {
    DubsarModelsLogLevelNone,
    DubsarModelsLogLevelError,
    DubsarModelsLogLevelWarn,
    DubsarModelsLogLevelInfo,
    DubsarModelsLogLevelDebug,
    DubsarModelsLogLevelTrace
};

@interface DubsarModelsLogger : NSObject

@property (atomic) DubsarModelsLogLevel logLevel;

+ (DubsarModelsLogger volatile*)instance;

+ (void)logFile:(const char*)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString*)format,...;
+ (void)logFile:(const char*)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString*)format args:(va_list)args;

- (void)logFile:(const char*)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString*)format,...;
- (void)logFile:(const char*)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString*)format args:(va_list)args;

@end

#ifdef DEBUG
#define DMLOG(...) [DubsarModelsLogger logFile:__FILE__ line:__LINE__ level:DubsarModelsLogLevelTrace format:__VA_ARGS__]
#define DMTRACE(...) DMLOG(__VA_ARGS__)
#define DMDEBUG(...) [DubsarModelsLogger logFile:__FILE__ line:__LINE__ level:DubsarModelsLogLevelDebug format:__VA_ARGS__]
#define DMINFO(...) [DubsarModelsLogger logFile:__FILE__ line:__LINE__ level:DubsarModelsLogLevelInfo format:__VA_ARGS__]
#define DMWARN(...) [DubsarModelsLogger logFile:__FILE__ line:__LINE__ level:DubsarModelsLogLevelWarn format:__VA_ARGS__]
#define DMERROR(...) [DubsarModelsLogger logFile:__FILE__ line:__LINE__ level:DubsarModelsLogLevelError format:__VA_ARGS__]
#else
#define DMLOG(...)
#define DMTRACE(...)
#define DMDEBUG(...)
#define DMINFO(...)
#define DMWARN(...)
#define DMERROR(...)
#endif // DEBUG
