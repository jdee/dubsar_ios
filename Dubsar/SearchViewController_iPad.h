//
//  SearchViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoadDelegate;
@class Search;

@interface SearchViewController_iPad : UIViewController<LoadDelegate> {
    
    UITableView *tableView;
}

@property (nonatomic, retain) Search* search;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString*)text matchCase:(BOOL)matchCase;

@end
