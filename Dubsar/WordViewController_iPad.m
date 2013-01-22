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
#import "InflectionsViewController_iPad.h"
#import "Sense.h"
#import "SenseViewController_iPad.h"
#import "Word.h"
#import "WordViewController_iPad.h"


@implementation WordViewController_iPad

@synthesize word;
@synthesize inflectionsLabel;
@synthesize tableView=_tableView;
@synthesize toolbar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        word = [theWord retain];
        word.delegate = self;
        inflectionsShowing = false;
        inflectionsViewController = [[InflectionsViewController_iPad alloc] initWithNibName:@"InflectionsViewController_iPad" bundle:nil word:word];
        
        self.title = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];
    }
    return self;
}

- (void)dealloc
{
    [inflectionsViewController release];
    
    word.delegate = nil;
    [word release];
    [inflectionsLabel release];
    [_tableView release];
    [super dealloc];
}

- (void)load
{
    [_tableView setHidden:NO];
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

    [self.view addSubview:inflectionsViewController.view];
    [inflectionsViewController.view setHidden:YES];
}

- (void)viewDidUnload
{
    [self setInflectionsLabel:nil];
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (word.complete && !word.error) {
        [self loadComplete:word withError:nil];
    }
    else if (word.complete) {
        // try again
        word.complete = word.error = false;
        [self load];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = word.complete ? word.senses.count : 1;
    return count;
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    DubsarAppDelegate_iPad* appDelegate = (DubsarAppDelegate_iPad*)UIApplication.sharedApplication.delegate;
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
    
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", index+1, sense.gloss];
    
    cell.detailTextLabel.text = sense.synonymsAsString;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Sense* sense = [word.senses objectAtIndex:indexPath.section];
    SenseViewController_iPad* senseViewController = [[[SenseViewController_iPad alloc]initWithNibName:@"SenseViewController_iPad" bundle:nil sense:sense]autorelease];
    [senseViewController load];
    [self.navigationController pushViewController:senseViewController animated:YES];
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    if (model != word) return;
    
    if (error) {
        [_tableView setHidden:YES];
        [inflectionsLabel setText:error];
        return;
    }
    
    NSLog(@"word load complete with %u senses", word.senses.count);
    
    [self setTableViewHeight];

    [self adjustInflections];
    [self adjustInflectionsView];
    
    if (word.inflections.count > 0) {
        [inflectionsViewController load];
    }
    else {
        [toolbar setHidden:YES];
    }

    [_tableView reloadData];
}

- (void)adjustInflections
{
    if (word.freqCnt == 0 && !word.error) {
        inflectionsLabel.hidden = YES;
        CGRect frame = _tableView.frame;
        frame.origin.y = 44.0;
        _tableView.frame = frame;
    }
    
    NSString* text = [NSString string];
    if (word.freqCnt > 0) {
        text = [text stringByAppendingFormat:@"freq. cnt.: %d", word.freqCnt];
    }
    
    inflectionsLabel.text = text;
}

- (void)loadRootController
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)setTableViewHeight
{    
    UIInterfaceOrientation currentOrientation = UIApplication.sharedApplication.statusBarOrientation;
    
    float maxHeight = UIInterfaceOrientationIsPortrait(currentOrientation) ? 960.0 : 704.0 ;
    if (word.freqCnt > 0 || word.error) maxHeight -= 44.0;
    
    float height = 66.0 * [self numberOfSectionsInTableView:_tableView];
        
    CGRect frame = _tableView.frame;
    
    frame.size.height = height < maxHeight ? height : maxHeight;
    
    _tableView.frame = frame;
    
    _tableView.contentSize = CGSizeMake(_tableView.frame.size.width, height);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self setTableViewHeight];
    [self adjustInflectionsView];
}

- (void)toggleInflections:(id)sender
{
    if (inflectionsShowing) [self dismissInflections];
    else [self showInflections];
}

- (void)showInflections
{
    inflectionsShowing = true;
    [self adjustInflectionsView];
    [UIView transitionWithView:self.view duration:0.4 options:UIViewAnimationOptionTransitionCurlUp animations:^{
        inflectionsLabel.hidden = YES;
        _tableView.hidden = YES;
        inflectionsViewController.view.hidden = NO;
    } completion:nil];
}

- (void)dismissInflections
{
    inflectionsShowing = false;
    [UIView transitionWithView:self.view duration:0.4 options:UIViewAnimationOptionTransitionCurlDown animations:^{
        inflectionsLabel.hidden = NO;
        _tableView.hidden = NO;
        inflectionsViewController.view.hidden = YES;
        
    } completion:nil];
}

- (void)adjustInflectionsView
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect frame = inflectionsViewController.view.frame;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        frame.size.height = 704.0;
    }
    else {
        frame.size.height = 960.0;
    }
    inflectionsViewController.view.frame = frame;
}

@end
