/*
 Dubsar Dictionary Project
 Copyright (C) 2010-11 Jimmy Dee
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#import "DubsarAppDelegate_iPad.h"
#import "PointerDictionary.h"
#import "Sense.h"
#import "SenseViewController_iPad.h"
#import "Synset.h"
#import "SynsetViewController_iPad.h"
#import "WordPopoverViewController_iPad.h"
#import "WordViewController_iPad.h"
#import "Word.h"

@implementation SenseViewController_iPad
@synthesize detailGlossTextView;
@synthesize glossTextView;
@synthesize sense;
@synthesize tableView;
@synthesize bannerLabel;
@synthesize detailLabel;
@synthesize detailView;
@synthesize senseToolbar;
@synthesize moreButton;
@synthesize mainView;
@synthesize detailBannerLabel;


- (void)displayPopup:(NSString*)text
{
    [detailLabel setText:text];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        mainView.hidden = YES;    
                        detailView.hidden = NO;
                    } completion:nil];
}

- (IBAction)dismissPopup:(id)sender {
    [tableView reloadData];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromLeft 
                    animations:^{
                        mainView.hidden = NO;
                        detailView.hidden = YES;
                    } completion:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.sense = theSense;
        sense.delegate = self;
        
        self.title = [NSString stringWithFormat:@"Sense: %@", sense.nameAndPos];
        
        detailNib = [[UINib nibWithNibName:@"DetailView_iPad" bundle:nil]retain];

        popoverController = nil;
    }
    return self;
}

- (void)load
{
    [sense load];
}

- (void)dealloc
{
    [tableSections release];
    [popoverController release];
    [detailNib release];
    sense.delegate = nil;
    [sense release];
    [tableView release];
    [bannerLabel release];
    [detailLabel release];
    [detailView release];
    [moreButton release];
    [mainView release];
    [senseToolbar release];
    [detailBannerLabel release];
    [glossTextView release];
    [detailGlossTextView release];
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
    [self setDetailLabel:nil];
    [self setDetailView:nil];
    [self setMoreButton:nil];
    [self setMainView:nil];
    [self setSenseToolbar:nil];
    [self setDetailBannerLabel:nil];
    [self setGlossTextView:nil];
    [self setDetailGlossTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (sense.complete) {
        [self loadComplete:sense withError:sense.errorMessage];
    }
}
        
- (void)viewDidDisappear:(BOOL)animated
{
    mainView.hidden = NO;
    detailView.hidden = YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (popoverWasVisible) {
        [popoverController presentPopoverFromRect:moreButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    popoverWasVisible = popoverController.popoverVisible;
    [popoverController dismissPopoverAnimated:YES];       
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
    
    NSDictionary* _section = [tableSections objectAtIndex:section];
    id _linkType = [_section valueForKey:@"linkType"];
    if (_linkType == NSNull.null) return;
    
    NSArray* _collection = [_section valueForKey:@"collection"];
    id _object = [_collection objectAtIndex:row];
    
    Sense* targetSense=nil;
    SenseViewController_iPad* senseViewController;    

    if ([_linkType isEqualToString:@"sense"]) {
        targetSense = _object;
        senseViewController = [[[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:targetSense]autorelease];
        [senseViewController load];
        [self.navigationController pushViewController:senseViewController animated:YES];
    }
    else if ([_linkType isEqualToString:@"sample"]) {
        [self displayPopup:_object];
    }
    else if ([[_object objectAtIndex:0] isEqualToString:@"sense"]) {
        NSArray* pointer = _object;
        NSNumber* targetId = [pointer objectAtIndex:1];
        /* sense pointer */
        targetSense = [Sense senseWithId:targetId.intValue name:[pointer objectAtIndex:2] partOfSpeech:POSUnknown];
        senseViewController = [[[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:targetSense]autorelease];
        [senseViewController load];
        [self.navigationController pushViewController:senseViewController animated:YES];
    }
    else {
        NSArray* pointer = _object;
        NSNumber* targetId = [pointer objectAtIndex:1];
        /* synset pointer */
        Synset* targetSynset = [Synset synsetWithId:targetId.intValue partOfSpeech:POSUnknown];
        SynsetViewController_iPad* synsetViewController = [[[SynsetViewController_iPad alloc]initWithNibName:@"SynsetViewController_iPad" bundle:nil synset:targetSynset]autorelease];
        [synsetViewController load];
        [self.navigationController pushViewController:synsetViewController animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    NSInteger n = sense && sense.complete ? tableSections.count : 1;
    return n;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSArray* _collection = [_section valueForKey:@"collection"];
    NSInteger n = sense && sense.complete ? _collection.count : 1 ;
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
    }
    
    DubsarAppDelegate_iPad* appDelegate = (DubsarAppDelegate_iPad*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
   
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = sense && sense.complete ? [_section valueForKey:@"header"] : @"loading...";
    return title;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary* _section = [tableSections objectAtIndex:section];
    NSString* title = sense && sense.complete ? [_section valueForKey:@"footer"] : @"";
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
    detailBannerLabel.text = text;
}


- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if (model != sense) return;
    
    if (error) {
        [bannerLabel setHidden:YES];
        [moreButton setHidden:YES];
        [tableView setHidden:YES];
        [senseToolbar setHidden:YES];
        [glossTextView setText:error];
        return;
    }

    NSString* gloss = sense.gloss;
    // gloss = [gloss stringByAppendingFormat:@" (in %@)", glossTextView.font.fontName];
    [glossTextView setText:gloss];
    [detailGlossTextView setText:sense.gloss];
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
    tableSections = [[NSMutableArray array]retain];
    NSMutableDictionary* section;
    if (sense.synonyms && sense.synonyms.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Synonyms" forKey:@"header"];
        [section setValue:[PointerDictionary helpWithPointerType:@"synonym"]  forKey:@"footer"];
        [section setValue:sense.synonyms forKey:@"collection"];
        [section setValue:@"sense" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.verbFrames && sense.verbFrames.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Verb Frames" forKey:@"header"];
        [section setValue:[PointerDictionary helpWithPointerType:@"verb frame"] forKey:@"footer"];
        [section setValue:sense.verbFrames forKey:@"collection"];
        [section setValue:@"sample" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.samples && sense.samples.count > 0) {
        section = [NSMutableDictionary dictionary];
        [section setValue:@"Sample Sentences" forKey:@"header"];
        [section setValue:[PointerDictionary helpWithPointerType:@"sample sentence"] forKey:@"footer"];
        [section setValue:sense.samples forKey:@"collection"];
        [section setValue:@"sample" forKey:@"linkType"];
        [tableSections addObject:section];
    }
    
    if (sense.pointers && sense.pointers.count > 0) {
        NSArray* keys = [sense.pointers allKeys];
        for (int j=0; j<keys.count; ++j) {
            NSString* key = [keys objectAtIndex:j];
            NSString* title = [PointerDictionary titleWithPointerType:key];
            
            section = [NSMutableDictionary dictionary];
            [section setValue:title forKey:@"header"];
            [section setValue:[PointerDictionary helpWithPointerType:key] forKey:@"footer"];
            [section setValue:[sense.pointers valueForKey:key] forKey:@"collection"];
            [section setValue:@"pointer" forKey:@"linkType"];
            [tableSections addObject:section];
        }
    }
}

- (IBAction)showWordView:(id)sender 
{
    WordViewController_iPad* wordViewController = [[[WordViewController_iPad alloc]initWithNibName:@"WordViewController_iPad" bundle:nil word:sense.word]autorelease];
    [wordViewController load];
    [self.navigationController pushViewController:wordViewController animated:YES];
}

- (IBAction)showSynsetView:(id)sender 
{
    SynsetViewController_iPad* synsetViewController = [[[SynsetViewController_iPad alloc]initWithNibName:@"SynsetViewController_iPad" bundle:nil synset:sense.synset]autorelease];
    [synsetViewController load];
    [self.navigationController pushViewController:synsetViewController animated:YES];
}

- (IBAction)morePopover:(id)sender 
{
    WordPopoverViewController_iPad* wordViewController;
    if (popoverController == nil) {        
        wordViewController = [[[WordPopoverViewController_iPad alloc]initWithNibName:@"WordPopoverViewController_iPad" bundle:nil word:sense.word]autorelease];
        [wordViewController load];
        
        popoverController = [[[UIPopoverController alloc]initWithContentViewController:wordViewController]retain];
        wordViewController.popoverController = popoverController;
        wordViewController.navigationController = self.navigationController;
    }
    else {
        wordViewController = (WordPopoverViewController_iPad*)popoverController.contentViewController;
        NSLog(@"popover already loaded for %@", wordViewController.word.name);
    }
    
    UIView* senderView = (UIView*)sender;
    [popoverController presentPopoverFromRect:senderView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
