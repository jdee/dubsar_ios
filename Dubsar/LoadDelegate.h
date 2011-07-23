//
//  SearchDelegate.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Search;

@protocol LoadDelegate <NSObject>

- (void)loadComplete:(id)model;
@end
