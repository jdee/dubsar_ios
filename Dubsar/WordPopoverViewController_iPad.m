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
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite]autorelease];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [indicator startAnimating];
        [cell.contentView addSubview:indicator];
        return cell;
    }
    
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", index+1, sense.gloss];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (sense.synonyms.count > 0) {
        cell.detailTextLabel.text = sense.synonymsAsString;
    }
    
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
    
    [self adjustTableViewFrame];
    [self adjustPopoverSize];    
    
    [self adjustTitle];
    [self adjustInflections];
    [_tableView reloadData];
}

- (void)adjustTableViewFrame
{
    CGRect frame = _tableView.frame;
    
    // the inflections label is hidden if it would be empty
    if (word.inflections.length == 0 && word.freqCnt == 0) {
        [inflectionsTextView setHidden:YES];
        frame.origin.y = 37.0;
    }
    
    _tableView.frame = frame;

}

- (void)adjustPopoverSize
{
    CGSize popoverSize = self.view.frame.size;
    
    float offset = (word.inflections.length == 0 && word.freqCnt == 0) ? 37.0 : 81.0;
    float popoverHeight = offset + 66.0*word.senses.count;
    popoverSize.height = popoverHeight > 1100.0 ? 1100.0 : popoverHeight;

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
