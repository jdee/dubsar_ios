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
#import "Sense.h"
#import "SenseViewController_iPad.h"
#import "Word.h"
#import "WordPopoverViewController_iPad.h"
#import "WordViewController_iPad.h"


@implementation WordPopoverViewController_iPad

@synthesize word;
@synthesize tableView=_tableView;
@synthesize inflectionsTextView;
@synthesize headerLabel;
@synthesize popoverController;
@synthesize navigationController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        word = [theWord retain];
        word.delegate = self;
        
        [self adjustTitle];
        
        UIBarButtonItem* homeButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Home"style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
        self.navigationItem.rightBarButtonItem = homeButtonItem;
        
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 154.0);
        
    }
    return self;
}

- (void)dealloc
{
    [origBg release];
    [highlightBg release];
    [origTextColor release];
    [highlightTextColor release];
    word.delegate = nil;
    [word release];
    [_tableView release];
    [inflectionsTextView release];
    [headerLabel release];
    [super dealloc];
}

- (void)load
{
    NSLog(@"loading, word is %@complete", word.complete ? @"" : @"not ");
    
    if (!word.complete) {
        [word load];
    }
}

- (IBAction)loadWord:(id)sender
{
    if (!word.complete || word.error) return;
        
    [popoverController dismissPopoverAnimated:YES];
    
    WordViewController_iPad* viewController = [[[WordViewController_iPad alloc]initWithNibName:@"WordViewController_iPad" bundle:nil word:word]autorelease];
    [viewController load];
    [navigationController pushViewController:viewController animated:YES];
    
    headerLabel.backgroundColor = origBg;
    headerLabel.textColor = origTextColor;
}

- (void)addGestureRecognizer
{
    UITapGestureRecognizer* recognizer = [[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(fireButton:)]autorelease];
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];
    
    highlightBg = [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0]retain];
    highlightTextColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0]retain];
    origBg = [headerLabel.backgroundColor retain];
    origTextColor = [headerLabel.textColor retain];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint location = [touch locationInView:self.view];
    return location.y <= headerLabel.frame.size.height;
}

- (void)fireButton:(UITapGestureRecognizer *)sender
{
    headerLabel.backgroundColor = highlightBg;
    headerLabel.textColor = highlightTextColor;
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(loadWord:)
                                   userInfo:nil
                                    repeats:NO];

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
    [self addGestureRecognizer];
    
    // If the model is already complete when I load from the NIB, either I'm being 
    // called with a mock object in a test, the response managed to come back before
    // the view was loaded, or I've been passed a complete object from a previous
    // request (start with a search, go to a word, then to one of the word's senses;
    // that word will be presented in the more popover; it's already complete).
    if (word.complete) {
        [self loadComplete:word withError:word.errorMessage];
    }
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setInflectionsTextView:nil];
    [self setHeaderLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self adjustInflections];
    [self adjustTableViewFrame];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return word.complete ? word.senses.count : 1;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)theTableView
{
    NSMutableArray* titles = [NSMutableArray array];
    if (!word || !word.complete || word.senses.count < 20) {
        return titles;
    }
    
    [titles addObject:@"top"];
    
    for (int j=4; j<word.senses.count; j += 5) {
        [titles addObject:[NSString stringWithFormat:@"%d", j+1]];
    }
    return titles;
}

- (NSInteger)tableView:(UITableView*)theTableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    switch (index) {
        case 0:
            return 0;
    }
    return 5*index - 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!word.complete) {
        return @"loading...";
    }
    
    Sense* sense = [word.senses objectAtIndex:section];
    
    NSString* textLine = [NSString string];
    if (sense.freqCnt > 0) {
        textLine = [textLine stringByAppendingFormat:@"freq. cnt.: %d", sense.freqCnt];
    }
    textLine = [textLine stringByAppendingFormat:@" <%@>", sense.lexname];
    if (sense.marker) {
        textLine = [textLine stringByAppendingFormat:@" (%@)", sense.marker];
    }
    return textLine;
}

- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellType = @"word";
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType]autorelease];
    }
    
    if (!word.complete) {
        static NSString* indicatorType = @"indicator";
        cell = [tableView dequeueReusableCellWithIdentifier:indicatorType];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:indicatorType]autorelease];
        }
        
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [indicator startAnimating];
        [cell.contentView addSubview:indicator];
        return cell;
    }    
    
    DubsarAppDelegate_iPad* appDelegate = (DubsarAppDelegate_iPad*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;

    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", index+1, sense.gloss];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    cell.detailTextLabel.text = sense.synonymsAsString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Sense* sense = [word.senses objectAtIndex:indexPath.section];
    SenseViewController_iPad* viewController = [[[SenseViewController_iPad alloc] initWithNibName:@"SenseViewController_iPad" bundle:nil sense:sense] autorelease];
    [viewController load];
  
    [popoverController dismissPopoverAnimated:YES];
    [navigationController pushViewController:viewController animated:YES];
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    NSLog(@"load complete");
    if (model != word) return;
    
    NSLog(@"correct model found");
    
    if (error) {
        NSLog(@"displaying error");
        [_tableView setHidden:YES];
        [headerLabel setText:@"ERROR"];
        [inflectionsTextView setText:error];
        return;
    }
    
    NSLog(@"popover controller received word response");
    NSLog(@"freq. cnt.: %d; inflections: \"%@\"", word.freqCnt, word.inflections);
    
    [self adjustPopoverSize];    
    [self adjustTableViewFrame];
    
    [self adjustTitle];
    [self adjustInflections];
    [_tableView reloadData];
}

- (void)adjustTableViewFrame
{
    CGRect frame = _tableView.frame;
    NSLog(@"initial table view frame: (%f, %f) %fx%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    
    // the inflections label is hidden if it would be empty
    if (word.complete && word.inflections.length == 0 && word.freqCnt == 0 && !word.error) {
        [inflectionsTextView setHidden:YES];
    }

    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    float screenHeight = UIInterfaceOrientationIsPortrait(orientation) ? 1004.0 : 748.0;
  
    float height = word.complete ? 66.0 * word.senses.count : 66.0;
    float maxHeight = screenHeight - frame.origin.y;
    
    _tableView.contentSize = CGSizeMake(frame.size.width, height);
 
    frame.origin.x = 0.0;
    frame.origin.y = inflectionsTextView.hidden ? 44.0 : 88.0;
    frame.size.width = 320;    
    frame.size.height = height < maxHeight ? height : maxHeight;

    NSLog(@"adjusting origin to %f; tableView height is %f", frame.origin.y, frame.size.height);
    NSLog(@"%d section(s) in tableView", [self numberOfSectionsInTableView:_tableView]);
    
    _tableView.frame = frame;
    NSLog(@"adjusted table view frame: (%f, %f) %fx%f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

- (void)adjustPopoverSize
{    
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    float screenHeight = UIInterfaceOrientationIsPortrait(orientation) ? 1004.0 : 748.0;
    
    float offset = (word.inflections.length == 0 && word.freqCnt == 0 && !word.error) ? 44.0 : 88.0;
    float height = offset + (word.error ? 0.0 : 66.0*word.senses.count);
    float popoverHeight = height > screenHeight ? screenHeight : height;
    
    NSLog(@"adjusting popoverHeight to %f", popoverHeight);
    
    CGSize popoverSize = CGSizeMake(320.0, popoverHeight);

    popoverController.popoverContentSize = popoverSize;
    self.contentSizeForViewInPopover = popoverSize;
}

- (void)adjustTitle
{
    NSString* title = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];
    NSLog(@"adjusting title: \"%@\"", title);
    headerLabel.text = title;
}

- (void)adjustInflections
{
    if (word.freqCnt == 0 && word.inflections.length == 0) return;
    
    NSString* text = [NSString string];
    if (word.freqCnt > 0) {
        text = [text stringByAppendingFormat:@"freq. cnt.: %d ", word.freqCnt];
        if (word.inflections.length > 0) {
            text = [text stringByAppendingString:@";"];
        }
        text = [text stringByAppendingString:@" "];
    }
    if (word.inflections.length > 0) {
        text = [text stringByAppendingFormat:@"also %@", word.inflections];
    }
    inflectionsTextView.text = text;
}


@end
