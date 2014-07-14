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

#import "DubsarModels/DubsarModelsModel.h"

@interface DubsarModelsSearch : DubsarModelsModel {
    NSString* term;
    NSMutableArray* _results;
}

@property (nonatomic) BOOL matchCase;
@property (nonatomic) bool isWildCard;
@property (nonatomic, copy) NSString* title;
@property (nonatomic, copy) NSString* term;
@property (nonatomic, strong) NSMutableArray* results;
@property (nonatomic) int currentPage;
@property (nonatomic) int totalPages;
@property (nonatomic) int seqNum;

/*
 * Indicates whether the search result contains an exact match.
 * Some searches (anything involving wildcards or when currentPage > 1) 
 * cannot result in exact matches. If this property is true, the first
 * word in the results will either have a name property equal to the
 * search term or an inflection with a name property equal to the
 * search term.
 */
@property bool exact;

+(instancetype)searchWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase;
-(instancetype)initWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase seqNum:(int)theSeqNum;
+(instancetype)searchWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase page:(int)page;
-(instancetype)initWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase page:(int)page seqNum:(int)theSeqNum;
+(instancetype)searchWithWildcard:(NSString*)regexp page:(int)page title:(NSString*)theTitle;
-(instancetype)initWithWildcard:(NSString*)regexp page:(int)page title:(NSString*)theTitle seqNum:(int)theSeqNum;

-(DubsarModelsSearch*)newSearchForPage:(int)page;

-(void)loadWildcardResults:(DubsarModelsDatabaseWrapper*)appDelegate;
-(void)loadFulltextResults:(DubsarModelsDatabaseWrapper*)appDelegate;

@end
