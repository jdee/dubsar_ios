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
@property int freqCnt;
@property (nonatomic, retain) NSMutableArray* samples;
@property (nonatomic, retain) NSMutableArray* senses;
@property (nonatomic, retain) NSMutableDictionary* pointers;


+(id)synsetWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech;
+(id)synsetWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(id)initWithId:(int)theId partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(id)initWithId:(int)theId gloss:(NSString*)theGloss partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(void)parseData;
-(void)parsePointers:(NSArray*)response;

@end
