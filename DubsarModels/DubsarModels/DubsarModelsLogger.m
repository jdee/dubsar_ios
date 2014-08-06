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

@interface NSString(Dubsar)
+ (NSString*)stringWithFormat:(NSString*)format args:(va_list)args;
@end

@implementation NSString(Dubsar)

+ (NSString *)stringWithFormat:(NSString *)format args:(va_list)args
{
    long l;
    long long ll;
    unsigned u;
    int i, len, buflen;
    double f;
    const char* s;
    id object;
    NSString* string;

    char buffer[512];
    memset(buffer, 0, sizeof(buffer));

    const char* fmt = format.UTF8String;
    const char* p = fmt;
    const char* start = p;

    do {
        // NSLog(@"Checking at start: \"%.12s\"", start);
        p = strchr(start, '%');
        if (!p) {
            strcat(buffer, start);
            break;
        }

        buflen = strlen(buffer);
        strncpy(buffer+buflen, start, p-start);
        buflen += p - start;
        buffer[buflen] = '\0';

        start = p;
        while (*p == '.' || *p == '*' || isdigit(*p)) ++ p;

        int discriminator = *++p;
        ++ p;

        char localFormat[16];
        strncpy(localFormat, start, p-start);
        localFormat[p-start] = '\0';
        assert(strlen(localFormat) == p-start);

        buflen = strlen(buffer);

        switch(discriminator) {
            case 'z': // might need review
            case 'l':
                // NSLog(@"Found %%l: %s", start);
                if (p[0] == 'l') {
                    ll = va_arg(args, long long);

                    len = strlen(localFormat);
                    localFormat[len] = *p++; // l
                    localFormat[len+1] = *p++; // after the second l
                    localFormat[len+2] = '\0';

                    // NSLog(@"Local format (ll) %s, value %lld", localFormat, ll);

                    buflen += sprintf(buffer+buflen, localFormat, ll);
                }
                else {
                    l = va_arg(args, long);

                    len = strlen(localFormat);
                    localFormat[len] = *p++; // whatever comes after the l
                    localFormat[len+1] = '\0';

                    // NSLog(@"Local format (l) %s, value %ld", localFormat, l);
                    // NSLog(@"Before: \"%s\"", buffer);
                    buflen += sprintf(buffer+buflen, localFormat, l);
                    // NSLog(@"After: \"%s\"", buffer);
                }

                break;

            case 'u':
                u = va_arg(args, unsigned);
                buflen += sprintf(buffer+buflen, localFormat, u);
                break;

            case 'd':
            case 'x':
            case 'o':
                // NSLog(@"Found %%d/x/o: %s", start);
                i = va_arg(args, int);
                // NSLog(@"Local format (d/x/o) %s, value %d", localFormat, i);
                // NSLog(@"Before: %s", buffer);
                buflen += sprintf(buffer+buflen, localFormat, i);
                // NSLog(@"After: %s", buffer);
                break;

            case 's':
                s = va_arg(args, const char*);
                buflen += sprintf(buffer+buflen, localFormat, s);
                break;

            case '@':
                object = va_arg(args, id);
                string = (NSString*)object; // what about NSURL and the like?

                buflen += sprintf(buffer+buflen, "%s", string.UTF8String);
                break;

            case 'f':
            default:
                /*
                if (discriminator != 'f') {
                    NSLog(@"Treating %%%c like %%f", discriminator);
                }
                // */

                f = va_arg(args, double);
                buflen += sprintf(buffer+buflen, localFormat, f);
                break;
        }

        buffer[buflen] = '\0';
        
        start = p;
    }
    while (start - fmt < strlen(fmt));
    
    return @(buffer);
}

@end

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
    NSString* s = [NSString stringWithFormat:format args:args];
    NSLog(@"%@", s);
}

@end
