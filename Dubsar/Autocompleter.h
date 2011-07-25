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

@property (nonatomic, retain) NSString* term;
@property (nonatomic, retain) NSMutableArray* results;

-(id)initWithTerm:(NSString*)theTerm;
-(void)parseData;

@end
