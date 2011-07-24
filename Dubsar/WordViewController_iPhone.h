//
//  WordViewController.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

@class SearchBarManager_iPhone;
@class Word;

@interface WordViewController_iPhone : UIViewController <LoadDelegate> {
    
    UILabel *inflectionsLabel;
    UISearchBar *searchBar;
    UITableView *tableView;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) Word* word;
@property (nonatomic, retain) SearchBarManager_iPhone* searchBarManager;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UILabel *inflectionsLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord;

-(void)adjustInflections;

- (void)createToolbarItems;
- (void)loadRootController;
- (void)displayLicense;

@end
