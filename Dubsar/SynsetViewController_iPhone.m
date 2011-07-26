//
//  SynsetViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "SenseViewController_iPhone.h"
#import "SynsetViewController_iPhone.h"
#import "Sense.h"
#import "Synset.h"

@implementation SynsetViewController_iPhone
@synthesize synset;

@synthesize bannerLabel;
@synthesize tableView;
@synthesize glossLabel;
@synthesize glossScrollView;
@synthesize detailLabel;
@synthesize detailView;


- (void)displayPopup:(NSString*)text
{
    [detailLabel setText:text];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromRight 
                    animations:^{
                        self.searchBar.hidden = YES;
                        bannerLabel.hidden = YES;
                        glossScrollView.hidden = YES;
                        tableView.hidden = YES;
                        detailView.hidden = NO;
                        self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
                        self.navigationController.toolbar.barStyle = UIBarStyleBlackOpaque;
                        UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleBlackOpaque;
                   } completion:^(BOOL finished){
                    }];
}

- (IBAction)dismissPopup:(id)sender {
    [tableView reloadData];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromLeft 
                    animations:^{
                        self.searchBar.hidden = NO;
                        bannerLabel.hidden = NO;
                        glossScrollView.hidden = NO;
                        tableView.hidden = NO;
                        detailView.hidden = YES;
                        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
                        self.navigationController.toolbar.barStyle = UIBarStyleDefault;
                        UIApplication.sharedApplication.statusBarStyle = UIStatusBarStyleDefault;
                   } completion:^(BOOL finished){
                        
                    }];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil synset:(Synset *)theSynset
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        synset = [theSynset retain];
        synset.delegate = self;
        [synset load];
        
        [self adjustTitle];
        
        detailNib = [UINib nibWithNibName:@"DetailView_iPhone" bundle:nil];
    }
    return self;
}

- (void)dealloc
{
    [synset release];
    [bannerLabel release];
    [tableView release];
    [glossLabel release];
    [glossScrollView release];
    [detailNib release];
    [detailLabel release];
    [detailView release];
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
    [glossScrollView setContentSize:CGSizeMake(1280,44)];
    [glossScrollView addSubview:glossLabel];
    [detailNib instantiateWithOwner:self options:nil];
    [detailView setHidden:YES];
    [self.view addSubview:detailView];
}

- (void)viewDidUnload
{
    [self setBannerLabel:nil];
    [self setTableView:nil];
    [self setGlossLabel:nil];
    [self setGlossScrollView:nil];
    [self setDetailLabel:nil];
    [self setDetailView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.searchBar.hidden = NO;
    bannerLabel.hidden = NO;
    glossScrollView.hidden = NO;
    tableView.hidden = NO;
    detailView.hidden = YES;
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.toolbar.barStyle = UIBarStyleDefault;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:animated];
}

- (void)loadComplete:(Model*)model
{
    if (model != synset) return;
    [self adjustTitle];
    [self adjustBannerLabel];
    [self adjustGlossLabel];
    [self setupTableSections];
    [tableView reloadData];
}

- (void)adjustBannerLabel
{
    NSString* text = [NSString stringWithFormat:@"<%@>", synset.lexname];
    if (synset.freqCnt > 0) {
        text = [text stringByAppendingFormat:@" freq. cnt.: %d", synset.freqCnt];
    }
    bannerLabel.text = text;
}

- (void)adjustGlossLabel
{
    glossLabel.text = synset.gloss;
}

- (void)adjustTitle
{
    if (synset.gloss) {
        self.title = [NSString stringWithFormat:@"Synset: %@", synset.gloss];
    }
    else {
        self.title = [NSString stringWithString:@"Synset"];
    }
}

/* TableView management */

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) {
        [super tableView:theTableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    [self followTableLink:indexPath];
}

- (void)tableView:(UITableView *)theTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) {
        [super tableView:theTableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    [self followTableLink:indexPath];   
}

- (void)followTableLink:(NSIndexPath *)indexPath
{
    
    int section = indexPath.section;
    int row = indexPath.row;
    
    NSLog(@"selected section %d, row %d", section, row);
    
    NSDictionary* _section = [tableSections objectAtIndex:section];
    id _linkType = [_section valueForKey:@"linkType"];
    NSLog(@"linkType is %@", _linkType);
    if (_linkType == NSNull.null) return;
    
    NSArray* _collection = [_section valueForKey:@"collection"];
    id _object = [_collection objectAtIndex:row];
    
    Sense* targetSense=nil;
    
    if ([_linkType isEqualToString:@"sense"]) {
        targetSense = _object;
        NSLog(@"links to Sense %@", targetSense.nameAndPos);
        [self.navigationController pushViewController:[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:targetSense] animated:YES];
    }
    else if ([_linkType isEqualToString:@"sample"]) {
        [self displayPopup:_object];
    }
    else {
        NSArray* pointer = _object;
        NSNumber* targetId = [pointer objectAtIndex:1];
        /* synset pointer */
        Synset* targetSynset = [Synset synsetWithId:targetId.intValue partOfSpeech:POSUnknown];
        NSLog(@"links to Synset %d", targetSynset._id);
        [self.navigationController pushViewController:[[SynsetViewController_iPhone alloc]initWithNibName:@"SynsetViewController_iPhone" bundle:nil synset:targetSynset] animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super numberOfSectionsInTableView:theTableView];
    }
    NSInteger n = synset && synset.complete ? tableSections.count : 1;
    NSLog(@"%d sections in table view", n);
    return n;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView numberOfRowsInSection:section];
    }
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSArray* _collection = [_section valueForKey:@"collection"];
    NSInteger n = synset && synset.complete ? _collection.count : 1 ;
    NSLog(@"%d rows in section %d of table view", n, section);
    return n;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) {
        return [super tableView:theTableView cellForRowAtIndexPath:indexPath];
    }
    
    static NSString* cellType = @"synset";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (!synset || !synset.complete) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"]autorelease];
        }
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
        [cell.contentView addSubview:indicator];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [indicator startAnimating];
        return cell;
    }
    else {
        int section = indexPath.section;
        int row = indexPath.row;
        NSDictionary* _section = [tableSections objectAtIndex:section];
        NSArray* _collection = [_section valueForKey:@"collection"];
        id _object = [_collection objectAtIndex:row];
        bool hasLinks = [_section valueForKey:@"linkType"] != NSNull.null;
        NSString* linkType = nil;
        if (hasLinks) linkType = [_section valueForKey:@"linkType"];
       
        if ([_object respondsToSelector:@selector(name)]) {
            cell = [theTableView dequeueReusableCellWithIdentifier:@"synsetPointer"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"synsetPointer"]autorelease];
            }
            
            cell.textLabel.text = [_object name];
            NSString* detailLine = [NSString string];
            if ([_object respondsToSelector:@selector(freqCnt)] && [_object freqCnt] > 0) {
                detailLine = [detailLine stringByAppendingFormat:@"freq. cnt.: %d", [_object freqCnt]];
            }
            if ([_object respondsToSelector:@selector(marker)] && [_object marker]) {
                detailLine = [detailLine stringByAppendingFormat:@" (%@)", [_object marker]];
            }
            cell.detailTextLabel.text = detailLine;
        }
        else if ([_object respondsToSelector:@selector(objectAtIndex:)]) {
            cell = [theTableView dequeueReusableCellWithIdentifier:@"synsetPointer"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"synsetPointer"]autorelease];
            }
            
            // pointers
            cell.textLabel.text = [_object objectAtIndex:2];
            cell.detailTextLabel.text = [_object objectAtIndex:3];
        }
        else {
            // must be a string
            cell.textLabel.text = _object;
        }
        
        if ([linkType isEqualToString:@"sample"]) {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        NSLog(@"set text %@ at section %d, row %d", cell.textLabel.text, section, row);
    }
    
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForHeaderInSection:section];
    }
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = synset && synset.complete ? [_section valueForKey:@"header"] : @"loading...";
    NSLog(@"header %@ for section %d", title, section);
    return title;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForFooterInSection:section];
    }
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = synset && synset.complete ? [_section valueForKey:@"footer"] : @"";
    NSLog(@"footer \"%@\" for section %d", title, section);
    return title;
}

- (void)setupTableSections
{
    NSLog(@"entering setupTableSection");
    tableSections = [[NSMutableArray array]retain];
    NSMutableDictionary* section;
    if (synset.senses && synset.senses.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Synonyms" forKey:@"header"];
        [section setValue:[Sense helpWithPointerType:@"synonym"] forKey:@"footer"];
        [section setValue:synset.senses forKey:@"collection"];
        [section setValue:@"sense" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (synset.samples && synset.samples.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Sample Sentences" forKey:@"header"];
        [section setValue:[Sense helpWithPointerType:@"sample sentence"] forKey:@"footer"];
        [section setValue:synset.samples forKey:@"collection"];
        [section setValue:@"sample" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (synset.pointers && synset.pointers.count > 0) {
        NSArray* keys = [synset.pointers allKeys];
        for (int j=0; j<keys.count; ++j) {
            NSString* key = [keys objectAtIndex:j];
            NSString* title = [Sense titleWithPointerType:key];
            
            section = [NSMutableDictionary dictionary];
            [section setValue:title forKey:@"header"];
            [section setValue:[Sense helpWithPointerType:key] forKey:@"footer"];
            [section setValue:[synset.pointers valueForKey:key] forKey:@"collection"];
            [section setValue:@"pointer" forKey:@"linkType"];
            [tableSections addObject:section];
        }
    }
    
    NSLog(@"found %u table sections", tableSections.count);
}
@end
