//
//  WordViewController.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "WordViewController.h"

#import "SearchBarManager.h"
#import "Word.h"

@implementation WordViewController
@synthesize searchBarManager;
@synthesize searchBar;
@synthesize pageLabel;
@synthesize viewController=_viewController;
@synthesize word;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil viewController:(UIViewController *)theViewController word:(Word *)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _viewController = theViewController;
        word = [theWord retain];
        word.delegate = self;
        [word load];
    }
    return self;
}

- (void)dealloc
{
    [word release];
    [searchBarManager release];
    [_viewController release];
    [pageLabel release];
    [searchBar release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    pageLabel.text = word.nameAndPos;
    searchBarManager = [SearchBarManager managerWithSearchBar:searchBar viewController:_viewController];
}

- (void)viewDidUnload
{
    [self setPageLabel:nil];
    [self setSearchBar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarSearchButtonClicked:theSearchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar 
{
    [searchBarManager searchBarCancelButtonClicked:theSearchBar];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar*)theSearchBar
{
    [searchBarManager searchBarTextDidBeginEditing:theSearchBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarTextDidEndEditing:theSearchBar];
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    [searchBarManager searchBar:theSearchBar textDidChange:theSearchText];
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [searchBarManager searchBar:theSearchBar shouldChangeTextInRange:range
                       replacementText:text];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    
    return NO;
}

- (IBAction)dismiss:(id)sender
{
    [_viewController dismissModalViewControllerAnimated:YES];
}

- (void)loadComplete:(id)model
{
    
}

@end
