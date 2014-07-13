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

#import "Dubsar-Swift.h"
#import "Inflection.h"
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
        AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
        self.page = thePage;
        self.totalPages = 0; // set by server response
        self._url = [NSString stringWithFormat:@"/review?page=%d&auth_token=%@", thePage, appDelegate.authToken];
    }
    return self;
}

+ (id) reviewWithPage:(int)thePage
{
    return [[self alloc] initWithPage:thePage];
}

- (void) load
{
    self.complete = false;
    [self loadFromServer];
}

- (void) parseData
{
    NSDictionary* response = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:NULL];
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

-(void)loadFromServer
{
    super.url = [NSString stringWithFormat:@"%@%@", DubsarSecureUrl, _url];
    NSURL* nsurl = [NSURL URLWithString:super.url];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:nsurl];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    NSLog(@"requesting %@", super.url);
}

@end
