//
//  WordPopoverViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

@class Word;

@interface WordPopoverViewController_iPad : UIViewController<LoadDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    UILabel *inflectionsLabel;
    UIScrollView *inflectionsScrollView;
    UILabel *headerLabel;
}

@property (nonatomic, assign) UIPopoverController* popoverController;
@property (nonatomic, retain) Word* word;
@property (nonatomic, retain) IBOutlet UILabel *inflectionsLabel;
@property (nonatomic, retain) IBOutlet UIScrollView *inflectionsScrollView;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UILabel *headerLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord;
- (void)adjustInflections;
- (void)adjustTitle;

@end
