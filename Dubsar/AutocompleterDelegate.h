//
//  AutocompleterDelegate.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <Foundation/Foundation.h>


@class Autocompleter;

@protocol AutocompleterDelegate
- (void)autocompleterFinished:(Autocompleter*)theAutocompleter;
@end
