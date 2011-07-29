/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
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

#import "Search.h"
#import "JSONKit.h"
#import "URLEncoding.h"
#import "Word.h"

@implementation Search

@synthesize results;
@synthesize term;
@synthesize matchCase;


+(id)searchWithTerm:(id)theTerm matchCase:(BOOL)mustMatchCase
{
    return [[[self alloc]initWithTerm:theTerm matchCase:mustMatchCase]autorelease];
}

-(id)initWithTerm:(NSString *)theTerm matchCase:(BOOL)mustMatchCase
{
    NSLog(@"constructing search for \"%@\"", theTerm);
    
    self = [super init];
    if (self) {   
        matchCase = mustMatchCase;
        term = [theTerm retain];
        results = nil;
        
        NSString* __url = [NSString stringWithFormat:@"/?term=%@", [term urlEncodeUsingEncoding:NSUTF8StringEncoding]];
        if (matchCase) __url = [__url stringByAppendingString:@"&match=case"];
        [self set_url:__url];
    }
    return self;
}

-(void)dealloc
{    
    [term release];
    [results release];

    [super dealloc];
}

- (void)parseData
{        
    NSArray* response = [[self decoder] objectWithData:[self data]];
    NSArray* list = [response objectAtIndex:1];
    
    results = [[NSMutableArray arrayWithCapacity:list.count]retain];
    NSLog(@"request for \"%@\" returned %d results", [response objectAtIndex:0], list.count);
    int j;
    for (j=0; j<list.count; ++j) {
        NSArray* entry = [list objectAtIndex:j];
        
        NSNumber* numericId = [entry objectAtIndex:0];
        NSString* name = [entry objectAtIndex:1];
        NSString* posString = [entry objectAtIndex:2];
        
        [results insertObject:[Word wordWithId:numericId.intValue name:name posString:posString] atIndex:j];
    }
}

@end
