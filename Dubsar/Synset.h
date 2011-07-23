//
//  Synset.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Model.h"


@interface Synset : Model {
    
}

@property int _id;
@property (nonatomic, retain) NSString* gloss;
@property (nonatomic, retain) NSString* lexname;

+(id)synsetWithId:(int)theId gloss:(NSString*)theGloss;
-(id)initWithId:(int)theId gloss:(NSString*)theGloss;
-(void)parseData;

@end
