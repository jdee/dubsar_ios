//
//  Model.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JSONDecoder;
@protocol LoadDelegate;

@protocol Model
@optional
/* model-specific parsing method, not implemented in base class */
-(void)parseData;
@end

@interface Model : NSObject <Model> {
    JSONDecoder* decoder;
    NSURLConnection* connection;
    NSMutableData* data;
    NSString* _url;
}

@property (nonatomic, retain) JSONDecoder* decoder;
@property (nonatomic, retain) NSMutableData* data;
@property (nonatomic, retain, setter=set_url:) NSString* _url;
@property (nonatomic, retain) NSString* url;
@property bool complete;
@property (nonatomic, assign) id<LoadDelegate> delegate;

-(void)load;
+(void)displayNetworkAlert:(NSString*)error;

@end
