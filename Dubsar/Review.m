/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
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

#import "Inflection.h"
#import "JSONKit.h"
#import "Review.h"
#import "Word.h"

@implementation Review
@synthesize inflections;
@synthesize page;
@synthesize totalPages;

- (id) initWithPage:(int)thePage
{
    self = [super init];
    if (self) {
        self.page = thePage;
        self.totalPages = 0; // set by server response
        self._url = [NSString stringWithFormat:@"/review?page=%d", thePage];
    }
    return self;
}

+ (id) reviewWithPage:(int)thePage
{
    return [[[self alloc] initWithPage:thePage] autorelease];
}

- (void) load
{
    [self loadFromServer];
}

- (void) parseData
{
    NSDictionary* response = [[self decoder] objectWithData:[self data]];
    NSArray* _inflections = [response valueForKey:@"inflections"];
    
    self.totalPages = [[response valueForKey:@"total_pages"]intValue];
    
    self.inflections = [NSMutableArray arrayWithCapacity:_inflections.count];
    for (int j=0; j<_inflections.count; ++j) {
        NSDictionary* _inflection = [_inflections objectAtIndex:j];
        NSDictionary* _word = [_inflection valueForKey:@"word"];
        
        int wordId = [[_word valueForKey:@"id"] intValue];
        NSString* wordName = [_word valueForKey:@"name"];
        NSString* pos = [_word valueForKey:@"pos"];
        
        Word* word = [Word wordWithId:wordId name:wordName posString:pos];
        
        int _id = [[_inflection valueForKey:@"id"] intValue];
        NSString* name = [_inflection valueForKey:@"name"];
        
        Inflection* inflection = [Inflection inflectionWithId:_id name:name word:word];
        [inflections addObject:inflection];
    }
}

@end
