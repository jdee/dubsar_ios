//
//  Autocompleter.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/24/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Model.h"


@interface Autocompleter : Model {
    NSString* term;
    NSMutableArray* _results;    
}

@property (nonatomic) BOOL matchCase;
@property (nonatomic) NSInteger seqNum;
@property (nonatomic, retain) NSString* term;
@property (nonatomic, retain) NSMutableArray* results;

+(id)autocompleterWithTerm:(NSString*)theTerm matchCase:(BOOL)mustMatchCase;

-(id)initWithTerm:(NSString*)theTerm seqNum:(NSInteger)theSeqNum matchCase:(BOOL)mustMatchCase;
-(void)parseData;

@end
