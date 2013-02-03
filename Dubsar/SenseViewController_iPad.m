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

#import "DubsarAppDelegate_iPad.h"
#import "PointerDictionary.h"
#import "Pointer.h"
#import "Section.h"
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
@synthesize bannerHandle;
@synthesize sense;
@synthesize tableView;
@synthesize bannerLabel;
@synthesize detailLabel;
@synthesize detailView;
@synthesize senseToolbar;
@synthesize moreButton;
@synthesize mainView;
@synthesize detailBannerLabel;
@synthesize actualNavigationController;

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
        self.actualNavigationController = nil;
        hasBeenDragged = false;
    }
    return self;
}

- (void)load
{
    [bannerLabel setHidden:sense.preview];
    [moreButton setHidden:sense.preview];
    [senseToolbar setHidden:sense.preview];

    [tableView setHidden:NO];
    [sense load];
}

- (void)dealloc
{
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
    [bannerHandle release];
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
    
    currentLabelPosition = initialLabelPosition = bannerLabel.frame.origin.y;
    [self addGestureRecognizers];
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
    [self setBannerHandle:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (sense.complete && !sense.error) {
        [self loadComplete:sense withError:nil];
    }
    else if (sense.complete) {
        // try again
        sense.complete = sense.error = false;
        [self load];
    }
    if (actualNavigationController == nil) self.actualNavigationController = self.navigationController;
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
    
    [self adjustGlossHeight];
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
    
    Section* _section = [sense.sections objectAtIndex:section];
    id _linkType = _section.linkType;
    if (_linkType == NSNull.null) return;
    
    Sense* targetSense=nil;
    
    /* SQL query */
    Pointer* pointer = [sense pointerForRowAtIndexPath:indexPath];
    if (pointer == nil) return; // error
    
    NSLog(@"Table view row tapped. actualNavigationController is%s nil", actualNavigationController == nil ? "" : " not");

    SenseViewController_iPad* senseViewController;
    if ([_linkType isEqualToString:@"sense"]) {
        targetSense = [sense.synonyms objectAtIndex:indexPath.row];
        senseViewController = [[[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:targetSense]autorelease];
        [senseViewController load];
        [actualNavigationController pushViewController:senseViewController animated:YES];
    }
    else if ([_linkType isEqualToString:@"sample"]) {
        if (!sense.preview) [self displayPopup:pointer.targetText];
    }
    else if ([pointer.targetType isEqualToString:@"Sense"]) {
        /* sense pointer */
        targetSense = [Sense senseWithId:pointer.targetId nameAndPos:pointer.targetText];
        senseViewController = [[[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:targetSense]autorelease];
        [senseViewController load];
        [actualNavigationController pushViewController:senseViewController animated:YES];
    }
    else {
        /* synset pointer */
        Synset* targetSynset = [Synset synsetWithId:pointer.targetId partOfSpeech:POSUnknown];
        SynsetViewController_iPad* synsetViewController = [[[SynsetViewController_iPad alloc]initWithNibName:@"SynsetViewController_iPad" bundle:nil synset:targetSynset]autorelease];
        [synsetViewController load];
        [actualNavigationController pushViewController:synsetViewController animated:YES];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    return sense.numberOfSections;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    return ((Section*)[sense.sections objectAtIndex:section]).numRows;
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
        if (sense.preview) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    DubsarAppDelegate_iPad* appDelegate = (DubsarAppDelegate_iPad*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
    
    // NSLog(@"cell text at section %d, row %d is %@", indexPath.section, indexPath.row, cell.textLabel.text);
    
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    Section* _section = [sense.sections objectAtIndex:section];
    return _section.header;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    Section* _section = [sense.sections objectAtIndex:section];
    return _section.footer;
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
    bannerLabel.hidden = sense.preview;
    detailBannerLabel.text = text;
}

- (void)adjustGlossHeight
{
    if (sense.preview || hasBeenDragged) return;
    
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
    
    frame = moreButton.frame;
    frame.origin.y = bannerHandle.frame.origin.y;
    moreButton.frame = frame;
    
    frame = tableView.frame;
    frame.origin.y = bannerLabel.frame.origin.y + bannerLabel.frame.size.height;
    frame.size.height = self.view.bounds.size.height - frame.origin.y;
    tableView.frame = frame;
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
    glossTextView.hidden = sense.preview;
    [self adjustBannerLabel];
    [tableView reloadData];
    [self adjustGlossHeight];
}

- (void)loadRootController
{
    [actualNavigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)showWordView:(id)sender 
{
    WordViewController_iPad* wordViewController = [[[WordViewController_iPad alloc]initWithNibName:@"WordViewController_iPad" bundle:nil word:sense.word title:nil]autorelease];
    [wordViewController load];
    [actualNavigationController pushViewController:wordViewController animated:YES];
}

- (IBAction)showSynsetView:(id)sender 
{
    SynsetViewController_iPad* synsetViewController = [[[SynsetViewController_iPad alloc]initWithNibName:@"SynsetViewController_iPad" bundle:nil synset:sense.synset]autorelease];
    [synsetViewController load];
    [actualNavigationController pushViewController:synsetViewController animated:YES];
}

- (IBAction)morePopover:(id)sender 
{
    WordPopoverViewController_iPad* wordViewController;
    if (popoverController == nil) {
        NSLog(@"creating popover, word is %@complete", sense.word.complete ? @"" : @"not ");
        
        wordViewController = [[[WordPopoverViewController_iPad alloc]initWithNibName:@"WordPopoverViewController_iPad" bundle:nil word:sense.word]autorelease];
        [wordViewController load];
        
        popoverController = [[[UIPopoverController alloc]initWithContentViewController:wordViewController]retain];
        wordViewController.popoverController = popoverController;
        wordViewController.navigationController = self.actualNavigationController;
    }
    else {
        wordViewController = (WordPopoverViewController_iPad*)popoverController.contentViewController;
        NSLog(@"popover already loaded for %@", wordViewController.word.name);
    }
    
    UIView* senderView = (UIView*)sender;
    [popoverController presentPopoverFromRect:senderView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)addGestureRecognizers
{
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
                location.y > tableView.frame.origin.y ||
                CGRectContainsPoint(moreButton.frame, location)) break;
            bannerHandle.hidden = NO;
        case UIGestureRecognizerStateChanged:
            if (location.y < glossTextView.frame.origin.y + glossTextView.frame.size.height ||
                location.y > tableView.frame.origin.y ||
                CGRectContainsPoint(moreButton.frame, location)) break;
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
    
    CGRect buttonFrame = moreButton.frame;
    buttonFrame.origin.y = position;
    moreButton.frame = buttonFrame;
    
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
        location.y <= tableView.frame.origin.y &&
        !CGRectContainsPoint(moreButton.frame, location)) {
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
