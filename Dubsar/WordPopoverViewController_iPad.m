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
#import "Sense.h"
#import "SenseViewController_iPad.h"
#import "Word.h"
#import "WordPopoverViewController_iPad.h"


@implementation WordPopoverViewController_iPad

@synthesize word;
@synthesize tableView=_tableView;
@synthesize headerLabel;
@synthesize inflectionsTextView;
@synthesize popoverController;
@synthesize navigationController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        word = [theWord retain];
        word.delegate = self;
        
        [self adjustTitle];
        
        UIBarButtonItem* homeButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Home"style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
        self.navigationItem.rightBarButtonItem = homeButtonItem;
        
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 147.0);
        
    }
    return self;
}

- (void)dealloc
{
    word.delegate = nil;
    [word release];
    [_tableView release];
    [headerLabel release];
    [inflectionsTextView release];
    [super dealloc];
}

- (void)load
{
    [word load];
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
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setHeaderLabel:nil];
    [self setInflectionsTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self adjustInflections];
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
    if (model != word) return;
    
    if (error) {
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
    if (word.inflections.length > 0 || word.freqCnt > 0) return ;
    
    // the inflections label is hidden if it would be empty
    [inflectionsTextView setHidden:YES];
    
    CGRect frame = _tableView.frame;
    frame.origin.y -= 44.0;
    float height = 66.0 * word.senses.count;
    if (frame.origin.y + height <= self.contentSizeForViewInPopover.height) {
        frame.size.height = height;
    }
    else {
        frame.size.height = self.contentSizeForViewInPopover.height - frame.origin.y;
    }
    
    _tableView.contentSize = CGSizeMake(frame.size.width, height);
    NSLog(@"adjusting origin to %f; tableView height is %f", frame.origin.y, frame.size.height);
    NSLog(@"%d section(s) in tableView", [self numberOfSectionsInTableView:_tableView]);
    
    _tableView.frame = frame;

}

- (void)adjustPopoverSize
{
    CGSize popoverSize = self.view.frame.size;
    
    float offset = (word.inflections.length == 0 && word.freqCnt == 0) ? 37.0 : 81.0;
    float popoverHeight = offset + 66.0*word.senses.count;
    popoverSize.height = popoverHeight > 1004.0 ? 1004.0 : popoverHeight;
    
    NSLog(@"adjusting popoverHeight to %f", popoverHeight);

    popoverController.popoverContentSize = popoverSize;
    self.contentSizeForViewInPopover = popoverSize;
}

- (void)adjustTitle
{
    headerLabel.text = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];   
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
