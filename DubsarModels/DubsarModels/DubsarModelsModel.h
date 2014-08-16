/*
 Dubsar Dictionary Project
 Copyright (C) 2010-14 Jimmy Dee
 
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

@import Foundation;

// Used by both autocompleter and search. for now, this is a convenient place to
// put this.
typedef NS_ENUM(NSInteger, DubsarModelsSearchScope) {
    DubsarModelsSearchScopeWords,
    DubsarModelsSearchScopeSynsets
};

@class DubsarModelsDatabaseWrapper;
@protocol DubsarModelsLoadDelegate;

@protocol DubsarModelsModel
@optional
/* model-specific parsing method, not implemented in base class */
-(void)parseData;
-(void)loadResults:(DubsarModelsDatabaseWrapper*)database;
@end

@interface DubsarModelsModel : NSObject <DubsarModelsModel> {
    NSMutableData* data;
    NSString* _url;
}

@property (nonatomic) NSMutableData* data;
@property (nonatomic, copy, setter=set_url:) NSString* _url;
@property (nonatomic, copy) NSString* url;
@property (nonatomic) bool complete;
@property (nonatomic) bool error;
@property (nonatomic, copy) NSString* errorMessage;
@property (nonatomic, weak) id<DubsarModelsLoadDelegate> delegate;
@property (nonatomic, readonly) DubsarModelsDatabaseWrapper* database;
@property (atomic) BOOL loading;
@property (nonatomic) BOOL callsDelegateOnMainThread;
@property (nonatomic) BOOL retriesWhenAvailable;

@property bool preview;

+(NSString*)incrementString:(NSString*)string;
+(BOOL)canRetryError:(NSError*)error;

- (void)load;
- (void)loadFromServer;
- (void)cancel;

// load in current thread; use with care.
- (void)loadSynchronous;

// for now, make this public
- (void)callDelegateSelectorOnMainThread:(SEL)action withError:(NSString*)loadError;

@end

extern const NSString* DubsarBaseUrl;
