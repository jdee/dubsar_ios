//
//  Search.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Model.h"

@interface Search : Model {
    NSString* term;
    NSMutableArray* _results;
}

@property (nonatomic) BOOL matchCase;
@property (nonatomic, retain) NSString* term;
@property (nonatomic, retain) NSMutableArray* results;

+(id)searchWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase;
-(id)initWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase;
-(void)parseData;

@end
