//
//  Sense.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Model.h"


@interface Sense : Model {
    
}

@property int _id;
@property (nonatomic, retain) NSString* gloss;
@property (nonatomic, retain) NSArray* synonyms;

+(id)senseWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms;
-(id)initWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms;

@end
