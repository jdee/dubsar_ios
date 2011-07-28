//
//  AutocompleterProxy.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "AutocompleterDelegate.h"
#import "AutocompleterProxy.h"


@implementation AutocompleterProxy
@synthesize delegate;

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if (delegate) [delegate autocompleterFinished:(Autocompleter*)model withError:error];
}
@end
