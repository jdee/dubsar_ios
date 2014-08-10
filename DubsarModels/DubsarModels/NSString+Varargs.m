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

#import "NSString+Varargs.h"

static char* extendBuffer(char* buffer, unsigned long* buflen) {
    *buflen *= 2;
    buffer = realloc(buffer, *buflen);

    // NSLog(@"Increased buffer from %lu to %lu bytes", *buflen/2, *buflen);
    return buffer;
}

@implementation NSString(Varargs)

+ (NSString *)stringWithFormat:(NSString *)format args:(va_list)args
{
    char* buffer = NULL;
    NSString* value;
    @try {
        long l;
        long long ll;
        unsigned u;
        int i;
        unsigned long len, buflen, datalen;
        double f;
        const char* s;
        id object;
        NSString* string;

        buflen = 512;
        buffer = malloc(buflen);
        memset(buffer, 0, buflen);

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

            datalen = strlen(buffer);
            unsigned long numToCopy = p - start;

            while (datalen + numToCopy >= buflen) {
                buffer = extendBuffer(buffer, &buflen);
            }

            strncpy(buffer+datalen, start, numToCopy);
            datalen += numToCopy;
            buffer[datalen] = '\0';

            start = p;
            while (*p == '.' || *p == '*' || isdigit(*p)) ++ p;

            int discriminator = *++p;
            ++ p;

            char localFormat[16];
            strncpy(localFormat, start, p-start);
            localFormat[p-start] = '\0';
            assert(strlen(localFormat) == p-start);

            datalen = strlen(buffer);

            switch(discriminator) {
                case '%':
                    ++ p;
                    if (datalen + 1 >= buflen) {
                        buffer = extendBuffer(buffer, &buflen);
                        // NSLog(@"datalen = %lu, adding a %%", datalen);
                    }

                    buffer[datalen ++] = '%';
                    break;
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

                        // max. value of an unsigned long long = 2^64 = 16 * 2^60 = 16 * 10^18 = 1.6 * 10^19, 20 digits.
                        // max. negative value of a long long = -8 * 10^18, also 20 digits, including sign.
                        if (datalen + 20 >= buflen) {
                            buffer = extendBuffer(buffer, &buflen);
                            // NSLog(@"datalen = %lu, adding %lld", datalen, ll);
                        }

                        datalen += sprintf(buffer+datalen, localFormat, ll);
                    }
                    else {
                        l = va_arg(args, long);

                        len = strlen(localFormat);
                        localFormat[len] = *p++; // whatever comes after the l
                        localFormat[len+1] = '\0';

                        // 11 digits, including sign, in -2 * 10^9
                        if (datalen + 11 >= buflen) {
                            buffer = extendBuffer(buffer, &buflen);
                            // NSLog(@"datalen = %lu, adding %ld", datalen, l);
                        }

                        // NSLog(@"Local format (l) %s, value %ld", localFormat, l);
                        // NSLog(@"Before: \"%s\"", buffer);
                        datalen += sprintf(buffer+datalen, localFormat, l);
                        // NSLog(@"After: \"%s\"", buffer);
                    }

                    break;

                case 'u':
                    u = va_arg(args, unsigned);

                    // 10 digits in 4 * 10^9
                    if (datalen + 10 >= buflen) {
                        buffer = extendBuffer(buffer, &buflen);
                        // NSLog(@"datalen = %lu, adding %u", datalen, u);
                    }

                    datalen += sprintf(buffer+datalen, localFormat, u);
                    break;

                case 'd':
                case 'x':
                case 'o':
                    // NSLog(@"Found %%d/x/o: %s", start);
                    i = va_arg(args, int);
                    // NSLog(@"Local format (d/x/o) %s, value %d", localFormat, i);
                    // NSLog(@"Before: %s", buffer);

                    // Octal takes the most space of these. Largest negative value is -2^31 = -2 * 8^10, 12 octal digits including sign.
                    if (datalen + 12 >= buflen) {
                        buffer = extendBuffer(buffer, &buflen);
                        // NSLog(@"datalen = %lu, adding %d", datalen, i);
                    }

                    datalen += sprintf(buffer+datalen, localFormat, i);
                    // NSLog(@"After: %s", buffer);
                    break;

                case 's':
                    s = va_arg(args, const char*);

                    while (datalen + strlen(s) >= buflen) {
                        buffer = extendBuffer(buffer, &buflen);
                        // NSLog(@"datalen = %lu, adding %lu chars", datalen, strlen(s));
                    }

                    datalen += sprintf(buffer+datalen, localFormat, s);
                    break;

                case '@':
                    object = va_arg(args, id);
                    string = [NSString stringWithFormat:@"%@", object]; // in case of NSURL, etc.

                    while (datalen + strlen(string.UTF8String) >= buflen) {
                        buffer = extendBuffer(buffer, &buflen);
                        // NSLog(@"datalen = %lu, adding %lu chars", datalen, strlen(string.UTF8String));
                    }

                    assert(datalen + strlen(string.UTF8String) < buflen);
                    datalen += sprintf(buffer+datalen, "%s", string.UTF8String);
                    break;

                case 'f':
                default:
                    /*
                     if (discriminator != 'f') {
                     NSLog(@"Treating %%%c like %%f", discriminator);
                     }
                     // */

                    // -0.12345678901234567e-123
                    while (datalen + 25 >= buflen) {
                        buffer = extendBuffer(buffer, &buflen);
                        // NSLog(@"datalen = %lu, adding %f", datalen, f);
                    }
                    
                    f = va_arg(args, double);
                    datalen += sprintf(buffer+datalen, localFormat, f);
                    break;
            }
            
            buffer[datalen] = '\0';
            
            start = p;
        }
        while (start - fmt < strlen(fmt));
        
        value = @(buffer);
    }
    @catch(NSException* e)
    {
        // NSLog(@"Caught exception: %@", e);
    }
    @finally
    {
        if (buffer) free(buffer);
    }

    return value;
}

@end
