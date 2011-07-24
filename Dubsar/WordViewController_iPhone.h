//
//  WordViewController_iPhone.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "SearchBarViewController_iPhone.h"

@class Word;

@interface WordViewController_iPhone : SearchBarViewController_iPhone {
    
    UILabel *inflectionsLabel;
    UITableView *tableView;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@property (nonatomic, retain) Word* word;
@property (nonatomic, retain) IBOutlet UILabel *inflectionsLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word*)theWord;

-(void)adjustInflections;

@end
