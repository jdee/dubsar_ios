/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import <Foundation/Foundation.h>
#import "DubsarAppDelegate.h"

@class JSONDecoder;
@protocol LoadDelegate;

@protocol Model
@optional
/* model-specific parsing method, not implemented in base class */
-(void)parseData;
-(void)loadResults:(DubsarAppDelegate*)appDelegate;
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
@property (nonatomic) bool complete;
@property (nonatomic) bool error;
@property (nonatomic, retain) NSString* errorMessage;
@property (nonatomic, assign) id<LoadDelegate> delegate;

@property bool preview;

+(NSString*)incrementString:(NSString*)string;

-(void)load;
-(void)databaseThread:(id)appDelegate;
-(void)loadFromServer;

+(void)displayNetworkAlert:(NSString*)error;

@end
