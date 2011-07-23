//
//  Sense.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Model.h"

@class Word;

@interface Sense : Model {
    
}

@property int _id;
@property (nonatomic, retain) NSString* gloss;
@property (nonatomic, retain) NSArray* synonyms;

@property (nonatomic, retain) Word* word;

@property (nonatomic, retain) NSString* lexname;
@property int freqCnt;
@property (nonatomic, retain) NSString* marker;

+(id)senseWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(Word*)theWord;
-(id)initWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(Word*)theWord;

-(NSString*)synonymsAsString;

@end
