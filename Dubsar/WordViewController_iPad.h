//
//  WordViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

@class Word;

@interface WordViewController_iPad : UIViewController<LoadDelegate, UITableViewDataSource, UITableViewDelegate> {
    
    UILabel *inflectionsLabel;
}

@property (nonatomic, retain) Word* word;
@property (nonatomic, retain) IBOutlet UILabel *inflectionsLabel;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord;

@end
