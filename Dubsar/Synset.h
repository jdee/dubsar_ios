//
//  Synset.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "Model.h"


@interface Synset : Model {
    
}

@property int _id;
@property (nonatomic, retain) NSString* gloss;
@property PartOfSpeech partOfSpeech;
@property (nonatomic, retain) NSString* lexname;
@property (nonatomic, retain) NSMutableArray* samples;
@property (nonatomic, retain) NSMutableArray* senses;

+(id)synsetWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(id)initWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(void)parseData;

@end
