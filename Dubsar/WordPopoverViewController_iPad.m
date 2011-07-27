//
//  WordPopoverViewController_iPad.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/26/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//


#import "Sense.h"
#import "Word.h"
#import "WordPopoverViewController_iPad.h"


@implementation WordPopoverViewController_iPad

@synthesize word;
@synthesize inflectionsLabel;
@synthesize inflectionsScrollView;
@synthesize tableView=_tableView;
@synthesize headerLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        word = [theWord retain];
        word.delegate = self;
        [word load];
        
        [self adjustTitle];
        
        UIBarButtonItem* homeButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Home"style:UIBarButtonItemStyleBordered target:self action:@selector(loadRootController)]autorelease];
        self.navigationItem.rightBarButtonItem = homeButtonItem;
        
    }
    return self;
}

- (void)dealloc
{
    [word release];
    [inflectionsLabel release];
    [_tableView release];
    [headerLabel release];
    [inflectionsScrollView release];
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
    [inflectionsScrollView setContentSize:CGSizeMake(1280,44)];
    [inflectionsScrollView addSubview:inflectionsLabel];
}

- (void)viewDidUnload
{
    [self setInflectionsLabel:nil];
    [self setTableView:nil];
    [self setHeaderLabel:nil];
    [self setInflectionsScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
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
    
    if (sense.synonyms.count > 0) {
        cell.detailTextLabel.text = sense.synonymsAsString;
    }
    
    return cell;
}

- (void)loadComplete:(Model *)model
{
    if (model != word) return;
    
    NSLog(@"popover controller received word response");
    
    [self adjustTitle];
    [self adjustInflections];
    [_tableView reloadData];
}

- (void)adjustTitle
{
    headerLabel.text = [NSString stringWithFormat:@"Word: %@", word.nameAndPos];   
}

- (void)adjustInflections
{
    NSString* text = [NSString string];
    if (word.freqCnt > 0) {
        text = [text stringByAppendingFormat:@"freq. cnt.: %d ", word.freqCnt];
    }
    if (word.inflections.length > 0) {
        text = [text stringByAppendingFormat:@"also %@", word.inflections];
    }
    inflectionsLabel.text = text;
}


@end
