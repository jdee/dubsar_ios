//
//  SenseViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "DubsarViewController_iPhone.h"
#import "SenseViewController_iPhone.h"
#import "SearchBarManager_iPhone.h"
#import "SynsetViewController_iPhone.h"
#import "Sense.h"
#import "Word.h"

@implementation SenseViewController_iPhone
@synthesize searchBar;
@synthesize bannerLabel;
@synthesize glossLabel;
@synthesize tableView;
@synthesize searchBarManager;
@synthesize sense;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        sense = [theSense retain];
        sense.delegate = self;
        
        [sense load];
        self.title = [NSString stringWithFormat:@"Sense: %@", sense.nameAndPos];
        
        UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Synset"  style:UIBarButtonItemStylePlain target:self action:@selector(loadSynsetView)];
        
        self.navigationItem.rightBarButtonItem = barButtonItem;
        [self createToolbarItems];
    }
    return self;
}

- (void)dealloc
{
    [tableSections release];
    [sense release];
    [searchBarManager release];
    [searchBar release];
    [bannerLabel release];
    [glossLabel release];
    [tableView release];
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
    searchBarManager = [SearchBarManager_iPhone managerWithSearchBar:searchBar navigationController:self.navigationController];
}

- (void)viewDidUnload
{
    [self setSearchBar:nil];
    [self setBannerLabel:nil];
    [self setGlossLabel:nil];
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:NO animated:animated];
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

- (void)loadComplete:(Model*)model
{
    if (model != sense) return;
    
    [self adjustBannerLabel];
    glossLabel.text = sense.gloss;
    [self setupTableSections];
    [tableView reloadData];
}

- (void)adjustBannerLabel
{    
    NSString* text = [NSString stringWithFormat:@"<%@>", sense.lexname];
    if (sense.marker) {
        text = [text stringByAppendingString:[NSString stringWithFormat:@" (%@)", sense.marker]];
    }
    if (sense.freqCnt > 0) {
        text = [text stringByAppendingString:[NSString stringWithFormat:@" freq. cnt.: %d", sense.freqCnt]];
    }
    bannerLabel.text = text;   
}

- (void)loadSynsetView
{
    [self.navigationController pushViewController:[[SynsetViewController_iPhone alloc]initWithNibName:@"SynsetViewController_iPhone" bundle:nil synset:sense.synset] animated:YES];
}

- (void)createToolbarItems
{
    UIBarButtonItem* homeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObject:homeButtonItem];
    
    self.toolbarItems = buttonItems;
}

- (void)loadRootController
{
    [self.navigationController pushViewController:[[DubsarViewController_iPhone alloc]initWithNibName:@"DubsarViewController_iPhone" bundle:nil] animated:YES];
}

/* TableView management */

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) return nil;
    
    static NSString* cellType = @"sense";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = @"loading...";
    
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    return @"loading...";
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    return @"loading...";
}

- (void)setupTableSections
{
    
}

@end
