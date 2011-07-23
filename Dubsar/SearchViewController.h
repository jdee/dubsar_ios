//
//  SearchViewController.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/20/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <pthread.h>

#import <UIKit/UIKit.h>

#import "LoadDelegate.h"

@class SearchBarManager;
@class Search;

@interface SearchViewController : UIViewController <LoadDelegate> {

    UILabel *_pageLabel;
}

@property (nonatomic, retain) Search* search;
@property (nonatomic, retain) IBOutlet UILabel *pageLabel;
@property (nonatomic, retain) SearchBarManager* searchBarManager;
@property (nonatomic, retain) NSString* searchText;
@property (nonatomic, retain) UISearchDisplayController* searchDisplayController;
@property (nonatomic, retain) UIViewController* viewController;

- (IBAction)dismiss:(id)sender;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil text:(NSString*)theSearchText viewController:(UIViewController*)theViewController;
- (void)adjustPageLabel;

@end
