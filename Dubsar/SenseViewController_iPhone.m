//
//  SenseViewController_iPhone.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/23/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "SenseViewController_iPhone.h"
#import "SynsetViewController_iPhone.h"
#import "WordViewController_iPhone.h"
#import "Sense.h"
#import "Synset.h"
#import "Word.h"

@implementation SenseViewController_iPhone
@synthesize bannerLabel;
@synthesize glossScrollView;
@synthesize glossLabel;
@synthesize tableView;
@synthesize detailLabel;
@synthesize detailView;
@synthesize sense;

- (void)displayPopup:(NSString*)text
{
    [detailLabel setText:text];
    [UIView transitionWithView:self.view duration:0.4 
        options:UIViewAnimationOptionTransitionFlipFromRight 
        animations:^{
            [self searchBar].hidden = YES;
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
            [self searchBar].hidden = NO;
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

        detailNib = [[UINib nibWithNibName:@"DetailView_iPhone" bundle:nil]retain];
    }
    return self;
}

- (void)dealloc
{
    [tableSections release];
    [sense release];
    [bannerLabel release];
    [glossLabel release];
    [tableView release];
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
    CGRect frame = CGRectMake(8.0, 4.0, 1264.0, 36.0);
    glossLabel.frame = frame;
    
    [glossScrollView setContentSize:CGSizeMake(1280,44)];
    [glossScrollView addSubview:glossLabel];
    [detailNib instantiateWithOwner:self options:nil];
    [detailView setHidden:YES];
    [self.view addSubview:detailView];
}

- (void)viewDidUnload
{
    [self setBannerLabel:nil];
    [self setGlossLabel:nil];
    [self setTableView:nil];
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
    if (model != sense) return;
    
    NSLog(@"completed loading Sense %d, %@", sense._id, sense.nameAndPos);
    NSLog(@"gloss: %@, synonyms %@", sense.gloss, sense.synonymsAsString);
    NSLog(@"lexname: %@, marker: %@, freq. cnt.: %d", sense.lexname, sense.marker, sense.freqCnt);
   
    self.title = [NSString stringWithFormat:@"Sense: %@", sense.nameAndPos];
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
    [self.navigationController pushViewController:[[[SynsetViewController_iPhone alloc]initWithNibName:@"SynsetViewController_iPhone" bundle:nil synset:sense.synset]autorelease] animated:YES];
}

- (void)loadWordView
{
    [self.navigationController pushViewController:[[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:sense.word]autorelease] animated:YES];
}

- (void)createToolbarItems
{
    UIBarButtonItem* homeItem = [[[UIBarButtonItem alloc]initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
    UIBarButtonItem* synsetItem = [[[UIBarButtonItem alloc]initWithTitle:@"Synset" style:UIBarButtonItemStyleBordered target:self action:@selector(loadSynsetView)]autorelease];
    UIBarButtonItem* wordItem = [[[UIBarButtonItem alloc]initWithTitle:@"Word" style:UIBarButtonItemStyleBordered target:self action:@selector(loadWordView)]autorelease];
    
    NSMutableArray* buttonItems = [NSMutableArray arrayWithCapacity:3];
    
    [buttonItems addObject:homeItem];
    [buttonItems addObject:synsetItem];
    [buttonItems addObject:wordItem];
    
    self.toolbarItems = buttonItems;
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
        [super tableView:theTableView accessoryButtonTappedForRowWithIndexPath:indexPath];
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
        [self.navigationController pushViewController:[[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:targetSense]autorelease] animated:YES];
    }
    else if ([_linkType isEqualToString:@"sample"]) {
        [self displayPopup:_object];
    }
    else if ([[_object objectAtIndex:0] isEqualToString:@"sense"]) {
        NSArray* pointer = _object;
        NSNumber* targetId = [pointer objectAtIndex:1];
        /* sense pointer */
        targetSense = [Sense senseWithId:targetId.intValue name:[pointer objectAtIndex:2] partOfSpeech:POSUnknown];
        NSLog(@"links to Sense %@", targetSense.nameAndPos);
        [self.navigationController pushViewController:[[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:targetSense]autorelease] animated:YES];
    }
    else {
        NSArray* pointer = _object;
        NSNumber* targetId = [pointer objectAtIndex:1];
        /* synset pointer */
        Synset* targetSynset = [Synset synsetWithId:targetId.intValue partOfSpeech:POSUnknown];
        NSLog(@"links to Synset %d", targetSynset._id);
        [self.navigationController pushViewController:[[[SynsetViewController_iPhone alloc]initWithNibName:@"SynsetViewController_iPhone" bundle:nil synset:targetSynset]autorelease] animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super numberOfSectionsInTableView:theTableView];
    }
    NSInteger n = sense && sense.complete ? tableSections.count : 1;
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
    NSInteger n = sense && sense.complete ? _collection.count : 1 ;
    NSLog(@"%d rows in section %d of table view", n, section);
    return n;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) {
        return [super tableView:theTableView cellForRowAtIndexPath:indexPath];
    }
    
    static NSString* cellType = @"sense";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;

    if (!sense || !sense.complete) {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"]autorelease];
        }
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]autorelease];
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
            cell = [theTableView dequeueReusableCellWithIdentifier:@"sensePointer"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sensePointer"]autorelease];
            }
            
            // synonyms (senses)
            cell.textLabel.text = [_object name];
            
            NSString* detailLine = [NSString string];
            
#undef FREQ_CNT_FOR_SYNONYMS_IN_SENSE_VIEW
#ifdef FREQ_CNT_FOR_SYNONYMS_IN_SENSE_VIEW
            if ([_object respondsToSelector:@selector(freqCnt)] && [_object freqCnt] > 0) {
                detailLine = [detailLine stringByAppendingFormat:@"freq. cnt.: %d", [_object freqCnt]];
            }
#endif
            if ([_object respondsToSelector:@selector(marker)] && [_object marker]) {
                detailLine = [detailLine stringByAppendingFormat:@" (%@)", [_object marker]];
            }
            cell.detailTextLabel.text = detailLine;
        }
        else if ([_object respondsToSelector:@selector(objectAtIndex:)]) {
            cell = [theTableView dequeueReusableCellWithIdentifier:@"sensePointer"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sensePointer"]autorelease];
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
        return [super tableView:theTableView titleForFooterInSection:section];
    }
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = sense && sense.complete ? [_section valueForKey:@"header"] : @"loading...";
    NSLog(@"header %@ for section %d", title, section);
    return title;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForFooterInSection:section];
    }
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
        [section setValue:[Sense helpWithPointerType:@"synonym"]  forKey:@"footer"];
        [section setValue:sense.synonyms forKey:@"collection"];
        [section setValue:@"sense" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.verbFrames && sense.verbFrames.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Verb Frames" forKey:@"header"];
        [section setValue:[Sense helpWithPointerType:@"verb frame"] forKey:@"footer"];
        [section setValue:sense.verbFrames forKey:@"collection"];
        [section setValue:@"sample" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.samples && sense.samples.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Sample Sentences" forKey:@"header"];
        [section setValue:[Sense helpWithPointerType:@"sample sentence"] forKey:@"footer"];
        [section setValue:sense.samples forKey:@"collection"];
        [section setValue:@"sample" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.pointers && sense.pointers.count > 0) {
        NSArray* keys = [sense.pointers allKeys];
        for (int j=0; j<keys.count; ++j) {
            NSString* key = [keys objectAtIndex:j];
            NSString* title = [Sense titleWithPointerType:key];
            
            section = [NSMutableDictionary dictionary];
            [section setValue:title forKey:@"header"];
            [section setValue:[Sense helpWithPointerType:key] forKey:@"footer"];
            [section setValue:[sense.pointers valueForKey:key] forKey:@"collection"];
            [section setValue:@"pointer" forKey:@"linkType"];
            [tableSections addObject:section];
        }
    }
    
    NSLog(@"found %u table sections", tableSections.count);
}

@end
