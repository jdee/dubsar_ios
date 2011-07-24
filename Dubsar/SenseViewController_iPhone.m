//
//  SenseViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "LicenseViewController_iPhone.h"
#import "SenseViewController_iPhone.h"
#import "SearchBarManager_iPhone.h"
#import "SynsetViewController_iPhone.h"
#import "WordViewController_iPhone.h"
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
        tableSections = nil;
        self.title = [NSString stringWithFormat:@"Sense: %@", sense.nameAndPos];
        
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
    
    NSLog(@"completed loading Sense %d, %@", sense._id, sense.nameAndPos);
    NSLog(@"gloss: %@, synonyms %@", sense.gloss, sense.synonymsAsString);
    NSLog(@"lexname: %@, marker: %@, freq. cnt.: %d", sense.lexname, sense.marker, sense.freqCnt);
    
    [self adjustBannerLabel];
    glossLabel.text = sense.gloss;
    [self setupTableSections];
    if (tableSections.count > 0) {
        [tableView reloadData];
    }
    else {
        [tableView setHidden:YES];
    }
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

- (void)loadWordView
{
    [self.navigationController pushViewController:[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:sense.word] animated:YES];
}

- (void)createToolbarItems
{
    UIBarButtonItem* homeButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)];
    
    UIBarButtonItem* wordButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Word"  style:UIBarButtonItemStyleBordered target:self action:@selector(loadWordView)];
    UIBarButtonItem* synsetButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Synset"  style:UIBarButtonItemStyleBordered target:self action:@selector(loadSynsetView)];
   
    NSMutableArray* buttonItems = [NSMutableArray arrayWithObject:homeButtonItem];
    [buttonItems addObject:wordButtonItem];
    [buttonItems addObject:synsetButtonItem];
    
    self.toolbarItems = buttonItems;
}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

/* TableView management */

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) return;
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    NSLog(@"selected section %d, row %d", section, row);
    
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* _linkType = [_section valueForKey:@"linkType"];
    NSLog(@"linkType is %@", _linkType);
    if (_linkType == nil) return;
    
    NSArray* _collection = [_section valueForKey:@"collection"];
    
    /* only synonyms for now */
    Sense* targetSense = [_collection objectAtIndex:row];
    NSLog(@"links to Sense %@", targetSense.nameAndPos);
    [self.navigationController pushViewController:[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:targetSense] animated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) return 0;    
    NSInteger n = sense && sense.complete ? tableSections.count : 1;
    NSLog(@"%d sections in table view", n);
    return n;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) return 0;    
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSArray* _collection = [_section valueForKey:@"collection"];
    NSInteger n = sense && sense.complete ? _collection.count : 1 ;
    NSLog(@"%d rows in section %d of table view", n, section);
    return n;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) return nil;
    
    static NSString* cellType = @"sense";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (!sense || !sense.complete) {
        cell.textLabel.text = @"loading...";
    }
    else {
        int section = indexPath.section;
        int row = indexPath.row;
        NSDictionary* _section = [tableSections objectAtIndex:section];
        NSArray* _collection = [_section valueForKey:@"collection"];
        id _object = [_collection objectAtIndex:row];
        bool hasLinks = [_section valueForKey:@"linkType"] != nil;
        
        if ([_object respondsToSelector:@selector(name)]) {
            cell.textLabel.text = [_object name];
        }
        else {
            // must be a string
            cell.textLabel.text = _object;
        }
        
        if (hasLinks) cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        NSLog(@"set text %@ at section %d, row %d", cell.textLabel.text, section, row);
    }
    
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != tableView) return @"";
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = sense && sense.complete ? [_section valueForKey:@"header"] : @"loading...";
    NSLog(@"header %@ for section %d", title, section);
    return title;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    if (theTableView != tableView) return @"";
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = sense && sense.complete ? [_section valueForKey:@"footer"] : @"";
    NSLog(@"footer \"%@\" for section %d", title, section);
    return title;
}

- (void)setupTableSections
{
    NSLog(@"entering setupTableSection");
    tableSections = [[NSMutableArray array]retain];
    NSMutableDictionary* section;
    if (sense.synonyms && sense.synonyms.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Synonyms" forKey:@"header"];
        [section setValue:@"" forKey:@"footer"];
        [section setValue:sense.synonyms forKey:@"collection"];
        [section setValue:@"sense" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.verbFrames && sense.verbFrames.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Verb Frames" forKey:@"header"];
        [section setValue:@"" forKey:@"footer"];
        [section setValue:sense.verbFrames forKey:@"collection"];
        [section setValue:nil forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.samples && sense.samples.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Sample Sentences" forKey:@"header"];
        [section setValue:@"" forKey:@"footer"];
        [section setValue:sense.samples forKey:@"collection"];
        [section setValue:nil forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    NSLog(@"found %u table sections", tableSections.count);
}

@end
