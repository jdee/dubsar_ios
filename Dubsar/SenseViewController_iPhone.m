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

#import "DubsarAppDelegate_iPhone.h"
#import "Pointer.h"
#import "PointerDictionary.h"
#import "SenseViewController_iPhone.h"
#import "SynsetViewController_iPhone.h"
#import "WordViewController_iPhone.h"
#import "Section.h"
#import "Sense.h"
#import "Synset.h"
#import "Word.h"

@implementation SenseViewController_iPhone
@synthesize tableView;
@synthesize detailLabel;
@synthesize detailView;
@synthesize detailBannerLabel;
@synthesize detailGlossTextView;
@synthesize bannerHandle;
@synthesize bannerLabel;
@synthesize glossTextView;
@synthesize sense;

- (void)displayPopup:(NSString*)text
{
    [detailLabel setText:text];
    [UIView transitionWithView:self.view duration:0.4 
        options:UIViewAnimationOptionTransitionFlipFromRight 
        animations:^{
            [self searchBar].hidden = YES;
            bannerLabel.hidden = YES;
            glossTextView.hidden = YES;
            tableView.hidden = YES;
            detailView.hidden = NO;
        } completion:nil];
}

- (IBAction)dismissPopup:(id)sender {
    [tableView reloadData];
    [UIView transitionWithView:self.view duration:0.4 
        options:UIViewAnimationOptionTransitionFlipFromLeft 
        animations:^{
            [self searchBar].hidden = NO;
            bannerLabel.hidden = NO;
            glossTextView.hidden = NO;
            tableView.hidden = NO;
            detailView.hidden = YES;
        } completion:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil sense:(Sense*)theSense
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        sense = [theSense retain];
        sense.delegate = self;
        
        tableSections = nil;
        self.title = [NSString stringWithFormat:@"Sense: %@", sense.nameAndPos];

        detailNib = [[UINib nibWithNibName:@"DetailView_iPhone" bundle:nil]retain];
    }
    return self;
}

- (void)dealloc
{
    [tableSections release];
    sense.delegate = nil;
    [sense release];
    [tableView release];
    [detailNib release];
    [detailLabel release];
    [detailView release];
    [detailBannerLabel release];
    [detailGlossTextView release];
    [glossTextView release];
    [bannerHandle release];
    [bannerLabel release];
    [super dealloc];
}

- (bool)loadedSuccessfully
{
    return sense.complete && !sense.error;
}

- (void)load
{
    if (self.loading || (sense.complete && !sense.error)) return;
    
    [sense load];

    self.loading = true;
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
    
    initialLabelPosition = bannerLabel.frame.origin.y;
    currentLabelPosition = initialLabelPosition;
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setDetailLabel:nil];
    [self setDetailView:nil];
    [self setDetailBannerLabel:nil];
    [self setDetailGlossTextView:nil];
    [self setGlossTextView:nil];
    [self setBannerHandle:nil];
    [self setBannerLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.searchBar.hidden = NO;
    bannerLabel.hidden = NO;
    glossTextView.hidden = NO;
    tableView.hidden = NO;
    detailView.hidden = YES;
    if (sense.complete && !sense.error) {
        [self loadComplete:sense withError:nil];
    }
    else {
        [self load];
    }
        
}

- (void)loadComplete:(Model*)model withError:(NSString *)error
{
    self.loading = false;

    if (model != sense) return;
    
    if (error) {
        [bannerLabel setHidden:YES];
        [tableView setHidden:YES];
        [glossTextView setText:error];
        [self.navigationController.toolbar setItems:[NSArray arrayWithObject:    [[[UIBarButtonItem alloc]initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease]]];

        return;
    }
    
    NSLog(@"completed loading Sense %d, %@", sense._id, sense.nameAndPos);
    NSLog(@"gloss: %@, synonyms %@", sense.gloss, sense.synonymsAsString);
    NSLog(@"lexname: %@, marker: %@, freq. cnt.: %d", sense.lexname, sense.marker, sense.freqCnt);
   
    self.title = [NSString stringWithFormat:@"Sense: %@", sense.nameAndPos];
    [self adjustBannerLabel];
    glossTextView.text = sense.gloss;
    detailGlossTextView.text = sense.gloss;
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
    detailBannerLabel.text = text;
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
    
    Section* _section = [sense.sections objectAtIndex:section];
    id _linkType = _section.linkType;
    if (_linkType == NSNull.null) return;
    
    Sense* targetSense=nil;
    
    /* SQL query */
    Pointer* pointer = [sense pointerForRowAtIndexPath:indexPath];
    if (pointer == nil) return; // error
    
    if ([_linkType isEqualToString:@"sense"]) {
        targetSense = [sense.synonyms objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:[[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:targetSense]autorelease] animated:YES];
    }
    else if ([_linkType isEqualToString:@"sample"]) {
        [self displayPopup:pointer.targetText];
    }
    else if ([pointer.targetType isEqualToString:@"Sense"]) {
        /* sense pointer */
        targetSense = [Sense senseWithId:pointer.targetId nameAndPos:pointer.targetText];
        [self.navigationController pushViewController:[[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:targetSense]autorelease] animated:YES];
    }
    else {
        /* synset pointer */
        Synset* targetSynset = [Synset synsetWithId:pointer.targetId partOfSpeech:POSUnknown];
        [self.navigationController pushViewController:[[[SynsetViewController_iPhone alloc]initWithNibName:@"SynsetViewController_iPhone" bundle:nil synset:targetSynset]autorelease] animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super numberOfSectionsInTableView:theTableView];
    }
    int n = [sense numberOfSections];
    NSLog(@"found %d sections", n);
    return n;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView numberOfRowsInSection:section];
    }

    return ((Section*)[sense.sections objectAtIndex:section]).numRows;
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
        NSLog(@"sense is not complete");
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
    
    /* SQL query */
    Pointer* pointer = [sense pointerForRowAtIndexPath:indexPath];
    if (pointer == nil) {
        NSLog(@"query failed");
        return nil;
    }
    
    int section = indexPath.section;
    NSString* linkType = ((Section*)[sense.sections objectAtIndex:section]).linkType;
    
    cell = [theTableView dequeueReusableCellWithIdentifier:@"sensePointer"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"sensePointer"]autorelease];
    }
    cell.textLabel.text = pointer.targetText;
    // NSLog(@"rendering cell for %@ at section %d, row %d", pointer.targetText, indexPath.section, indexPath.row);
    
    cell.detailTextLabel.text = pointer.targetGloss;
    
    if ([linkType isEqualToString:@"sample"]) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
    
    // NSLog(@"cell text at section %d, row %d is %@", indexPath.section, indexPath.row, cell.textLabel.text);
    
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForHeaderInSection:section];
    }
    Section* _section = [sense.sections objectAtIndex:section];
    return _section.header;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForFooterInSection:section];
    }
    Section* _section = [sense.sections objectAtIndex:section];
    return _section.footer;
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

- (void)addGestureRecognizers
{
    [super addGestureRecognizers];
    
    UITapGestureRecognizer* recognizer = [[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture:)]autorelease];
    recognizer.delegate = self;
    recognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:recognizer];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:self.view];    
    CGPoint translate = [sender translationInView:self.view];
    
    switch (sender.state) {
        default:
            currentLabelPosition = bannerLabel.frame.origin.y;
            bannerHandle.hidden = YES;
            break;
        case UIGestureRecognizerStateBegan:
            if (location.y < glossTextView.frame.origin.y + glossTextView.frame.size.height ||
                location.y > tableView.frame.origin.y) break;
            bannerHandle.hidden = NO;
        case UIGestureRecognizerStateChanged:
            if (location.y < glossTextView.frame.origin.y + glossTextView.frame.size.height ||
                location.y > tableView.frame.origin.y) break;
            [self translateViewContents:translate];
            break;
    }
}

- (void)translateViewContents:(CGPoint)translate {
    float position = currentLabelPosition + translate.y;
    if (position < initialLabelPosition) position = initialLabelPosition;
    
    CGRect bannerFrame = bannerLabel.frame;
    bannerFrame.origin.y = position;
    bannerLabel.frame = bannerFrame;
    bannerHandle.frame = bannerFrame;
    
    CGRect glossFrame = glossTextView.frame;
    glossFrame.size.height = position - 4.0 - glossFrame.origin.y;
    glossTextView.frame = glossFrame;
    
    CGRect tableViewFrame = tableView.frame;
    tableViewFrame.origin.y = position + bannerFrame.size.height + 4.0;
    tableView.frame = tableViewFrame;
    
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender
{
    switch (sender.state) {
        default:
            break;
        case UIGestureRecognizerStateRecognized:
        case UIGestureRecognizerStateFailed:
            bannerHandle.hidden = YES;
            break;
    }
}

- (void)handleTouch:(UITouch*)touch
{
    CGPoint location = [touch locationInView:self.view];
    if (location.y >= glossTextView.frame.origin.y + glossTextView.frame.size.height &&
        location.y <= tableView.frame.origin.y) {
        switch (touch.phase) {
            case UITouchPhaseBegan:
                bannerHandle.hidden = NO;
                break;

            /* Why don't we receive these events? I have to have a tap handler too to make this work right */
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled:
                bannerHandle.hidden = YES;
                break;
            default:
                break;
        }
    }
}

@end
