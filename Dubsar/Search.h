//
//  Search.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JSONDecoder;
@protocol LoadDelegate;

@interface Search : NSObject {
    JSONDecoder* decoder;
    NSString* term;
    NSString* _url;
    NSMutableData* data;
    NSURLConnection* connection;
    NSMutableArray* _results;
}

@property (nonatomic, retain) NSString* term;
@property bool complete;
@property (nonatomic, retain) NSMutableArray* results;
@property (nonatomic, assign) id<LoadDelegate> delegate;

+(id)searchWithTerm:(NSString*)theTerm;
-(id)initWithTerm:(NSString*)theTerm;
-(void)parseData;
-(void)load;

-(void)connectionDidFinishLoading:(NSURLConnection *)connection;
-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData *)data;


@end
