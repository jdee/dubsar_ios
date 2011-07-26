//
//  AutocompleterProxy.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "AutocompleterDelegate.h"
#import "LoadDelegate.h"

@protocol AutocompleterDelegate;

@interface AutocompleterProxy : NSObject<LoadDelegate> {
    
}
@property (nonatomic, assign) id<AutocompleterDelegate> delegate;
@end
