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
#import "WordViewController_iPhone.h"
#import "Sense.h"
#import "SenseViewController_iPhone.h"
#import "Word.h"

@implementation WordViewController_iPhone
@synthesize tableView;
@synthesize inflectionsTextView;
@synthesize word;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        word = [theWord retain];
        word.delegate = self;
        [word load];

        self.title = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];
   }
    return self;
}

- (void)dealloc
{
    word.delegate = nil;
    [word release];
    [tableView release];
    [inflectionsTextView release];
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
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setInflectionsTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (word.complete) {
        [self loadComplete:word withError:word.errorMessage];
    }
    [self setTableViewHeight];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super numberOfSectionsInTableView:theTableView];
    }
    return word && word.complete ? word.senses.count : 1;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) {
        return [super sectionIndexTitlesForTableView:theTableView];
    }
    
    NSMutableArray* titles = [NSMutableArray array];
    if (!word || !word.complete || word.senses.count < 10) {
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
    if (theTableView != tableView) {
        return [super tableView:theTableView sectionForSectionIndexTitle:title atIndex:index];
    }
    
    switch (index) {
        case 0:
            return 0;
    }
    return 5*index - 1;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForHeaderInSection:section];
    }
    
    if (!word || !word.complete) return @"loading...";
    
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

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView titleForFooterInSection:section];
    }
    return @"";
}

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (theTableView != tableView) {
        [super tableView:theTableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    [self.navigationController pushViewController:[[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:sense]autorelease] animated:YES];
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) {
        return [super tableView:theTableView numberOfRowsInSection:section];
    }
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != theTableView) {
        return [super tableView:theTableView cellForRowAtIndexPath:indexPath];
    }
    
    static NSString* cellType = @"word";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType] autorelease];
    }
    
    if (!word.complete) {
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
    
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", index+1, sense.gloss];
    cell.detailTextLabel.text = sense.synonymsAsString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    DubsarAppDelegate_iPhone* appDelegate = (DubsarAppDelegate_iPhone*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
   
    return cell;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if (model != word) return;
    
    if (error) {
        [tableView setHidden:YES];
        [inflectionsTextView setText:error];
        return;
    }
   
    [self adjustInflections];
    [self setTableViewHeight];
    
    [tableView reloadData];
}

- (void)adjustInflections
{
    if (word.freqCnt == 0 && word.inflections.length == 0) {
        inflectionsTextView.hidden = YES;
        CGRect frame = tableView.frame;
        frame.origin.y = 44.0;
        tableView.frame = frame;
        return;
    }
    
    NSString* text = [NSString string];
    if (word.freqCnt > 0) {
        text = [text stringByAppendingFormat:@"freq. cnt.: %d", word.freqCnt];
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

- (void)setTableViewHeight
{
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    
    // BUG: Where do these extra 12 points come from? Should be 212 in landscape (w/o
    // inflections)
    float maxHeight = UIInterfaceOrientationIsPortrait(orientation) ? 328.0 : 224.0 ;
    if (word.freqCnt > 0 || word.inflections.length > 0) maxHeight -= 44.0;
    
    float height = 66.0*[self numberOfSectionsInTableView:tableView];
    if (height > maxHeight) height = maxHeight;
    
    CGRect frame = tableView.frame;        
    frame.size.height = height;
    
    tableView.frame = frame;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self setTableViewHeight];
}

@end
