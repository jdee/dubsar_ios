//
//  SenseViewController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Sense.h"
#import "SenseViewController_iPad.h"
#import "Synset.h"
#import "SynsetPopoverViewController_iPad.h"
#import "SynsetViewController_iPad.h"
#import "WordPopoverViewController_iPad.h"
#import "WordViewController_iPad.h"

@implementation SenseViewController_iPad
@synthesize sense;
@synthesize tableView;
@synthesize bannerLabel;
@synthesize glossLabel;
@synthesize detailLabel;
@synthesize detailView;
@synthesize synsetButton;
@synthesize wordButton;


- (void)displayPopup:(NSString*)text
{
    [detailLabel setText:text];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromRight 
                    animations:^{
                        bannerLabel.hidden = YES;
                        // glossScrollView.hidden = YES;
                        tableView.hidden = YES;
                        detailView.hidden = NO;
                        self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
                    } completion:^(BOOL finished){
                    }];
}

- (IBAction)dismissPopup:(id)sender {
    [tableView reloadData];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromLeft 
                    animations:^{
                        bannerLabel.hidden = NO;
                        // glossScrollView.hidden = NO;
                        tableView.hidden = NO;
                        detailView.hidden = YES;
                        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
                    } completion:^(BOOL finished){                    
                    }];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.sense = theSense;
        sense.delegate = self;
        [sense load];
        
        self.title = [NSString stringWithFormat:@"Sense: %@", sense.nameAndPos];
        
        UIBarButtonItem* homeButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Home"style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
        self.navigationItem.rightBarButtonItem = homeButtonItem;
        
        detailNib = [UINib nibWithNibName:@"DetailView_iPad" bundle:nil];
        
   }
    return self;
}

- (void)dealloc
{
    [detailNib release];
    [sense release];
    [tableView release];
    [bannerLabel release];
    [glossLabel release];
    [detailLabel release];
    [detailView release];
    [synsetButton release];
    [wordButton release];
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
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setBannerLabel:nil];
    [self setGlossLabel:nil];
    [self setDetailLabel:nil];
    [self setDetailView:nil];
    [self setSynsetButton:nil];
    [self setWordButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

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
    
    Sense* targetSense=nil;
    
    if ([_linkType isEqualToString:@"sense"]) {
        targetSense = _object;
        NSLog(@"links to Sense %@", targetSense.nameAndPos);
        [self.navigationController pushViewController:[[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:targetSense] animated:YES];
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
        [self.navigationController pushViewController:[[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:targetSense] animated:YES];
    }
    else {
        NSArray* pointer = _object;
        NSNumber* targetId = [pointer objectAtIndex:1];
        /* synset pointer */
        Synset* targetSynset = [Synset synsetWithId:targetId.intValue partOfSpeech:POSUnknown];
        NSLog(@"links to Synset %d", targetSynset._id);
        [self.navigationController pushViewController:[[SynsetViewController_iPad alloc]initWithNibName:@"SynsetViewController_iPad" bundle:nil synset:targetSynset] animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    NSInteger n = sense && sense.complete ? tableSections.count : 1;
    NSLog(@"%d sections in table view", n);
    return n;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSArray* _collection = [_section valueForKey:@"collection"];
    NSInteger n = sense && sense.complete ? _collection.count : 1 ;
    NSLog(@"%d rows in section %d of table view", n, section);
    return n;
}

- (UITableViewCell*)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = sense && sense.complete ? [_section valueForKey:@"header"] : @"loading...";
    NSLog(@"header %@ for section %d", title, section);
    return title;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = sense && sense.complete ? [_section valueForKey:@"footer"] : @"";
    NSLog(@"footer \"%@\" for section %d", title, section);
    return title;
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


- (void)loadComplete:(Model *)model
{
    if (model != sense) return;
    
    [glossLabel setText:sense.gloss];
    [self adjustBannerLabel];
    [self setupTableSections];
    if (tableSections.count > 0) {
        [tableView reloadData];
    }
    else {
        [tableView setHidden:YES];
    }
}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
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

- (IBAction)showWordPopover:(id)sender 
{
    WordPopoverViewController_iPad* wordViewController = [[WordPopoverViewController_iPad alloc]initWithNibName:@"WordPopoverViewController_iPad" bundle:nil word:sense.word];
    [self displayPopoverWithViewController:wordViewController button:wordButton];
}

- (IBAction)showSynsetPopover:(id)sender 
{
    SynsetPopoverViewController_iPad* synsetViewController = [[SynsetPopoverViewController_iPad alloc]initWithNibName:@"SynsetPopoverViewController_iPad" bundle:nil synset:sense.synset];
    [self displayPopoverWithViewController:synsetViewController button:synsetButton];
}

- (void)displayPopoverWithViewController:(UIViewController *)viewController button:(UIBarButtonItem *)button
{
    UIPopoverController* controller = [[UIPopoverController alloc]initWithContentViewController:viewController];
    [controller presentPopoverFromBarButtonItem:button permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
