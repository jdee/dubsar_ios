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
#import "Word.h"

@implementation Inflection
@synthesize _id;
@synthesize name;
@synthesize word;

- (id) initWithId:(int)theId name:(NSString *)theName word:(Word *)theWord
{
    self = [super init];
    if (self) {
        self.word = theWord;
        self._id = theId;
        self.name = theName;
        [self set_url:[NSString stringWithFormat:@"/inflections/%d", self._id]];
    }
    return self;
}

+ (id) inflectionWithId:(int)theId name:(NSString *)theName word:(Word *)theWord
{
    return [[[self alloc]initWithId:theId name:theName word:theWord]autorelease];
}

- (void) dealloc
{
    [word release];
    [name release];
    [super dealloc];
}

@end
