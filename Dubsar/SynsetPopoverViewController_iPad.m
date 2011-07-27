//
//  SynsetPopoverViewController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//


#import "Sense.h"
#import "Synset.h"
#import "SynsetPopoverViewController_iPad.h"


@implementation SynsetPopoverViewController_iPad
@synthesize synset;
@synthesize tableView;
@synthesize bannerLabel;
@synthesize glossLabel;
@synthesize detailLabel;
@synthesize detailView;
@synthesize headerLabel;
@synthesize glossScrollView;


- (void)displayPopup:(NSString*)text
{
    [detailLabel setText:text];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromRight 
                    animations:^{
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
        self.synset = theSynset;
        synset.delegate = self;
        [synset load];
        
        [self adjustTitle];
        
        UIBarButtonItem* homeButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Home"style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
        self.navigationItem.rightBarButtonItem = homeButtonItem;
        
        detailNib = [UINib nibWithNibName:@"PopoverDetailView_iPad" bundle:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [detailLabel release];
    [detailView release];
    [synset release];
    [tableView release];
    [bannerLabel release];
    [glossLabel release];
    [headerLabel release];
    [glossScrollView release];
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
    [detailNib instantiateWithOwner:self options:nil];
    [detailView setHidden:YES];
    [self.view addSubview:detailView];

    CGRect frame = CGRectMake(8.0, 8.0, 687.0, 21.0);
    glossLabel.frame = frame;
    
    [glossScrollView setContentSize:CGSizeMake(1280,44)];
    [glossScrollView addSubview:glossLabel];
}

- (void)viewDidUnload
{
    [self setDetailLabel:nil];
    [self setDetailView:nil];
    [self setTableView:nil];
    [self setBannerLabel:nil];
    [self setGlossLabel:nil];
    [self setHeaderLabel:nil];
    [self setGlossScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
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
        headerLabel.text = [NSString stringWithFormat:@"Synset: %@", synset.gloss];
    }
    else {
        headerLabel.text = [NSString stringWithString:@"Synset"];
    }
}

/* TableView management */

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self followTableLink:indexPath];
}

- (void)tableView:(UITableView *)theTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
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
    
    if ([_linkType isEqualToString:@"sample"]) {
        [self displayPopup:_object];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    NSInteger n = synset && synset.complete ? tableSections.count : 1;
    NSLog(@"%d sections in table view", n);
    return n;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSArray* _collection = [_section valueForKey:@"collection"];
    NSInteger n = synset && synset.complete ? _collection.count : 1 ;
    NSLog(@"%d rows in section %d of table view", n, section);
    return n;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
        
        NSLog(@"set text %@ at section %d, row %d", cell.textLabel.text, section, row);
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = synset && synset.complete ? [_section valueForKey:@"header"] : @"loading...";
    NSLog(@"header %@ for section %d", title, section);
    return title;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
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