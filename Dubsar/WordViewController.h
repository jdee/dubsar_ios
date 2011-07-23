//
//  WordViewController.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoadDelegate.h"

@class SearchBarManager;
@class Word;

@interface WordViewController : UIViewController <LoadDelegate> {
    
    UILabel *pageLabel;
    UISearchBar *searchBar;
}

@property (nonatomic, retain) Word* word;
@property (nonatomic, retain) SearchBarManager* searchBarManager;
@property (nonatomic, retain) UIViewController* viewController;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;
@property (nonatomic, retain) IBOutlet UILabel *pageLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewController:(UIViewController*)theViewController word:(Word*)theWord;
- (IBAction)dismiss:(id)sender;

@end
