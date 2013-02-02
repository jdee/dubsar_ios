/*
 Dubsar Dictionary Project
 Copyright (C) 2010-13 Jimmy Dee
 
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
#import "PartOfSpeechDictionary.h"
#import "PointerDictionary.h"
#import "SenseViewController_iPhone.h"
#import "SynsetViewController_iPhone.h"
#import "Pointer.h"
#import "Section.h"
#import "Sense.h"
#import "Synset.h"

@implementation SynsetViewController_iPhone
@synthesize synset;

@synthesize tableView;
@synthesize detailLabel;
@synthesize detailView;
@synthesize detailBannerLabel;
@synthesize detailGlossTextView;
@synthesize glossTextView;
@synthesize bannerHandle;
@synthesize bannerLabel;


- (void)displayPopup:(NSString*)text
{
    [detailLabel setText:text];
    [UIView transitionWithView:self.view duration:0.4 
                       options:UIViewAnimationOptionTransitionFlipFromRight 
                    animations:^{
                        self.searchBar.hidden = YES;
                        bannerLabel.hidden = YES;
                        glossTextView.hidden = YES;
                        tableView.hidden = YES;
                        detailView.hidden = NO;
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
                        glossTextView.hidden = NO;
                        tableView.hidden = NO;
                        detailView.hidden = YES;
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
        
        hasBeenDragged = false;
        
        [self adjustTitle];
        
        detailNib = [[UINib nibWithNibName:@"DetailView_iPhone" bundle:nil]retain];
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustGlossHeight) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [tableSections release];
    [detailGlossTextView release];
    synset.delegate = nil;
    [synset release];
    [tableView release];
    [detailNib release];
    [detailLabel release];
    [detailView release];
    [detailBannerLabel release];
    [glossTextView release];
    [bannerHandle release];
    [bannerLabel release];
    [super dealloc];
}

- (bool)loadedSuccessfully
{
    return synset.complete && !synset.error;
}

- (void)load
{
    if (self.loading || (synset.complete && !synset.error)) return;
    
    [synset load];
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
    [detailNib instantiateWithOwner:self options:nil];
    [detailView setHidden:YES];
    [self.view addSubview:detailView];
    
    initialLabelPosition = bannerLabel.frame.origin.y;
    currentLabelPosition = initialLabelPosition;
}

- (void)viewDidUnload
{
    [self setDetailGlossTextView:nil];
    [self setTableView:nil];
    [self setDetailLabel:nil];
    [self setDetailView:nil];
    [self setDetailBannerLabel:nil];
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

    if (synset.complete && !synset.error) {
        [self loadComplete:synset withError:nil];
    }
    else {
        [self load];
    }
}

- (void)loadComplete:(Model*)model withError:(NSString *)error
{
    self.loading = false;
    if (model != synset) return;
    
    if (error) {
        [bannerLabel setHidden:YES];
        [tableView setHidden:YES];
        [glossTextView setText:error];
        return;
    }

    [self adjustTitle];
    [self adjustBannerLabel];
    [self adjustGlossLabel];

    [tableView reloadData];
}

- (void)adjustBannerLabel
{
    NSString* text = [NSString stringWithFormat:@"<%@>", synset.lexname];
    if (synset.freqCnt > 0) {
        text = [text stringByAppendingFormat:@" freq. cnt.: %d", synset.freqCnt];
    }
    bannerLabel.text = text;
    detailBannerLabel.text = text;
}

- (void)adjustGlossLabel
{
    if (synset.preview || hasBeenDragged) return;
    
    glossTextView.text = synset.gloss;
    detailGlossTextView.text = [synset.synonymsAsString stringByAppendingFormat:@" (%@.)", [PartOfSpeechDictionary posFromPartOfSpeech:synset.partOfSpeech]];
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[UIApplication sharedApplication].delegate;
    CGSize textSize = [glossTextView.text sizeWithFont:appDelegate.dubsarNormalFont constrainedToSize:self.view.bounds.size lineBreakMode:NSLineBreakByWordWrapping];
    CGRect frame = glossTextView.frame;
    frame.size.height = textSize.height + 16.0;
    glossTextView.frame = frame;
    
    frame = bannerLabel.frame;
    frame.origin.y = glossTextView.frame.origin.y + glossTextView.frame.size.height;
    bannerLabel.frame = frame;
    
    currentLabelPosition = frame.origin.y;
    
    frame = bannerHandle.frame;
    frame.origin.y = glossTextView.frame.origin.y + glossTextView.frame.size.height + 4.0;
    bannerHandle.frame = frame;
    
    frame = tableView.frame;
    frame.origin.y = bannerLabel.frame.origin.y + bannerLabel.frame.size.height;
    frame.size.height = self.view.bounds.size.height - frame.origin.y;
    tableView.frame = frame;
}

- (void)adjustTitle
{
    if (synset.gloss) {
        self.title = [NSString stringWithFormat:@"Synset: %@", synset.gloss];
    }
    else {
        self.title = @"Synset";
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
    Section* _section = [synset.sections objectAtIndex:section];
    id _linkType = _section.linkType;
    if (_linkType == NSNull.null) return;
    
    Sense* targetSense=nil;
    
    /* SQL query */
    Pointer* pointer = [synset pointerForRowAtIndexPath:indexPath];
    if (pointer == nil) return; // error
    
    if ([_linkType isEqualToString:@"sense"]) {
        targetSense = [synset.senses objectAtIndex:indexPath.row];
        [self.navigationController pushViewController:[[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:targetSense]autorelease] animated:YES];
    }
    else if ([_linkType isEqualToString:@"sample"]) {
        [self displayPopup:pointer.targetText];
    }
    else {
        Synset* targetSynset = [Synset synsetWithId:pointer.targetId partOfSpeech:POSUnknown];
        [self.navigationController pushViewController:[[[SynsetViewController_iPhone alloc]initWithNibName:@"SynsetViewController_iPhone" bundle:nil synset:targetSynset]autorelease] animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super numberOfSectionsInTableView:theTableView];
    }
    return synset.numberOfSections;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView numberOfRowsInSection:section];
    }
    
    return ((Section*)[synset.sections objectAtIndex:section]).numRows;
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
    
    /* SQL query */
    Pointer* pointer = [synset pointerForRowAtIndexPath:indexPath];
    if (pointer == nil) {
        NSLog(@"query failed");
        return nil;
    }
    
    int section = indexPath.section;
    NSString* linkType = ((Section*)[synset.sections objectAtIndex:section]).linkType;
    
    cell = [theTableView dequeueReusableCellWithIdentifier:@"synsetPointer"];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"synsetPointer"]autorelease];
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
    Section* _section = [synset.sections objectAtIndex:section];
    return _section.header;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForFooterInSection:section];
    }
    Section* _section = [synset.sections objectAtIndex:section];
    return _section.footer;
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
    tableViewFrame.size.height = self.view.bounds.size.height - tableViewFrame.origin.y;
    tableView.frame = tableViewFrame;
    
    hasBeenDragged = true;
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
