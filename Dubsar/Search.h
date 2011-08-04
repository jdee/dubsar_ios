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

#import "Model.h"

@interface Search : Model {
    NSString* term;
    NSMutableArray* _results;
}

@property (nonatomic) BOOL matchCase;
@property (nonatomic) bool isWildCard;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* term;
@property (nonatomic, retain) NSMutableArray* results;
@property (nonatomic) int currentPage;
@property (nonatomic) int totalPages;
@property (nonatomic) int seqNum;

+(id)searchWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase;
-(id)initWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase seqNum:(int)theSeqNum;
+(id)searchWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase page:(int)page;
-(id)initWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase page:(int)page seqNum:(int)theSeqNum;
+(id)searchWithWildcard:(NSString*)regexp page:(int)page title:(NSString*)theTitle;
-(id)initWithWildcard:(NSString*)regexp page:(int)page title:(NSString*)theTitle seqNum:(int)theSeqNum;

-(void)parseData;

-(Search*)newSearchForPage:(int)page;

@end
