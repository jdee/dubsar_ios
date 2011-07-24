//
//  Word.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Dubsar.h"
#import "Model.h"

@interface Word : Model {
}

@property int _id;
@property (nonatomic, retain) NSString* name;
@property PartOfSpeech partOfSpeech;
@property int freqCnt;

@property (nonatomic, retain) NSString* inflections;
@property (nonatomic, retain) NSMutableArray* senses;

+(id)wordWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
+(id)wordWithId:(int)theId name:(NSString*)theName posString:(NSString*)posString;
-(id)initWithId:(int)theId name:(NSString*)theName partOfSpeech:(PartOfSpeech)thePartOfSpeech;
-(id)initWithId:(int)theId name:(NSString*)theName posString:(NSString*)posString;
-(NSString*)pos;
-(NSString*)nameAndPos;

-(void)parseData;
-(void)initUrl;

@end
