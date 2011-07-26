//
//  DubsarAppDelegate_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DubsarAppDelegate.h"

@class DubsarViewController_iPad;

@interface DubsarAppDelegate_iPad : DubsarAppDelegate {
    
    UISplitViewController *_splitViewController;
}

@property (nonatomic, retain) DubsarViewController_iPad* dubsarViewController;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;

@end
