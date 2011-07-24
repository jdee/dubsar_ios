//
//  Sense.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "Model.h"

@class Synset;
@class Word;

@interface Sense : Model {
    
}

@property int _id;
@property (nonatomic, retain) NSString* name;
@property PartOfSpeech partOfSpeech;
@property (nonatomic, retain) NSString* gloss;
@property (nonatomic, retain) NSMutableArray* synonyms;

@property (nonatomic, retain) Synset* synset;
@property (nonatomic, retain) Word* word;

@property (nonatomic, retain) NSString* lexname;
@property int freqCnt;
@property (nonatomic, retain) NSString* marker;

@property (nonatomic, retain) NSMutableArray* verbFrames;
@property (nonatomic, retain) NSMutableArray* samples;
@property (nonatomic, retain) NSMutableDictionary* pointers;

+(NSString*)titleWithPointerType:(NSString*)ptype;
+(NSString*)helpWithPointerType:(NSString*)ptype;

+(id)senseWithId:(int)theId name:(NSString*)theName synset:(Synset*)theSynset;
+(id)senseWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
+(id)senseWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(Word*)theWord;
-(id)initWithId:(int)theId name:(NSString*)theName synset:(Synset*)theSynset;
-(id)initWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(id)initWithId:(int)theId gloss:(NSString*)theGloss synonyms:(NSArray*)theSynonyms word:(Word*)theWord;

-(NSString*)pos;
-(NSString*)nameAndPos;
-(void)initUrl;
-(void)parsePointers:(NSArray*)response;

-(NSString*)synonymsAsString;

@end
