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
@import UIKit;

#import "DubsarModelsDatabase.h"
#import "DubsarModelsInflection.h"
#import "DubsarModelsWord.h"

@implementation DubsarModelsInflection
@synthesize _id;
@synthesize name;
@synthesize word;

- (instancetype) initWithId:(int)theId name:(NSString *)theName word:(DubsarModelsWord *)theWord
{
    self = [super init];
    if (self) {
        DubsarModelsDatabase* database = [DubsarModelsDatabase instance];
        self.word = theWord;
        self._id = theId;
        self.name = theName;
        [self set_url:[NSString stringWithFormat:@"/inflections/%d?auth_token=%@", self._id, database.authToken]];
    }
    return self;
}

+ (instancetype) inflectionWithId:(int)theId name:(NSString *)theName word:(DubsarModelsWord *)theWord
{
    return [[self alloc]initWithId:theId name:theName word:theWord];
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
