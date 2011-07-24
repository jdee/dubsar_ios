//
//  SearchDelegate.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Model;

@protocol LoadDelegate <NSObject>

@optional
/* The SearchBarViewController_iPhone base class does
   not implement this. */
- (void)loadComplete:(Model*)model;
@end
