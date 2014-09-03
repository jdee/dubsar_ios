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
#import "NSString+Varargs.h"

@implementation DubsarModelsLogger

+ (DubsarModelsLogger volatile *)instance
{
    static volatile DubsarModelsLogger* _instance;
    if (!_instance) {
        _instance = [[self alloc] init];
    }
    return _instance;
}

+ (void)dump:(NSData *)data level:(DubsarModelsLogLevel)level
{
    [[self instance] dump:data level:level];
}

+ (void)logLevel:(DubsarModelsLogLevel)level message:(NSString *)message
{
    [[self instance] logLevel:level message:message];
}

+ (void)logFile:(const char *)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);

    [[self instance] logFile:file line:line level:level format:format args:args];

    va_end(args);
}

+ (void)logFile:(const char *)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString *)format args:(va_list)args
{
    [[self instance] logFile:file line:line level:level format:format args:args];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
#ifdef DEBUG
        _logLevel = DubsarModelsLogLevelDebug;
#else
        _logLevel = DubsarModelsLogLevelNone;
#endif // DEBUG
    }
    return self;
}

- (void)dump:(NSData *)data level:(DubsarModelsLogLevel)level
{
    if (level > self.logLevel) return;

    [self logLevel:level message:[NSString stringWithFormat:@"%lu bytes", (unsigned long)data.length]];

    const unsigned char* bytes = (const unsigned char*)data.bytes;
    size_t length = data.length;
    const int numPerLine = 8;
    const int pad = 8;

    while (length > 0) {
        int numToDump = MIN(numPerLine, length);

        char line[256];
        line[0] = '\0';

        for (int j=0; j<numToDump; ++j) {
            unsigned char c = bytes[j];
            sprintf(line+strlen(line), "%02x ", c);
        }

        int numToAdd = pad + 3*(numPerLine - numToDump);
        sprintf(line+strlen(line), "%*s", numToAdd, " ");

        for (int j=0; j<numToDump; ++j) {
            unsigned char c = bytes[j];
            sprintf(line+strlen(line), "%c", isprint(c) ? c : '.');
        }

        [self logLevel:level message:@(line)];

        length -= numToDump;
        bytes += numToDump;
    }
}

- (void)logLevel:(DubsarModelsLogLevel)level message:(NSString *)message
{
    [self logFile:NULL line:0 level:level format:@"%@", message];
}

- (void)logFile:(const char*)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);

    [self logFile:file line:line level:level format:format args:args];

    va_end(args);
}

- (void)logFile:(const char*)file line:(unsigned long)line level:(DubsarModelsLogLevel)level format:(NSString *)format args:(va_list)args
{
    if (level <= DubsarModelsLogLevelNone || level > self.logLevel) return;

    static const char* cLevels[] = { "NONE ", "ERROR", "WARN ", "INFO ", "DEBUG", "TRACE" };
    const char* cLevel = cLevels[level];

    NSString* s = [NSString stringWithFormat:format args:args];
    if (file) {
        NSLog(@"%s|%s:%lu|%@", cLevel, [self strippedFile:file], line, s);
    }
    else {
        NSLog(@"%s|%@", cLevel, s);
    }
}

- (const char*)strippedFile:(const char*)file
{
    // NSLog(@"file: %s", file);
    const char* slash = strchr(file, '/');
    if (!slash) return file;

    // NSLog(@"found slash");

    while (slash) {
        const char* next = strchr(slash+1, '/');

        if (!next) return file;

        char component[256];
        strncpy(component, slash+1, next-slash-1);
        component[next-slash-1] = '\0';
        // NSLog(@"component: %s", component);

        if (!strcmp(component, "dubsar_ios")) return ++next;
        
        slash = next;
    }

    return file;
}

@end
