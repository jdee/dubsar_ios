//
//  WordViewController.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "WordViewController_iPhone.h"
#import "Sense.h"
#import "SenseViewController_iPhone.h"
#import "Word.h"

@implementation WordViewController_iPhone
@synthesize inflectionsLabel;
@synthesize tableView;
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
    [word release];
    [inflectionsLabel release];
    [tableView release];
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
    [tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) return 0;
    return word && word.complete ? word.senses.count : 1;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)theTableView
{
    if (theTableView != tableView) return nil;
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
    if (theTableView != tableView) return -1;
    switch (index) {
        case 0:
            return 0;
    }
    return 5*index - 1;
}

#define USE_SECTION_HEADER_IN_WORD_TABLE_VIEW

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (theTableView != tableView) return nil;
    
#ifdef USE_SECTION_HEADER_IN_WORD_TABLE_VIEW
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
#else
    return @"";
#endif
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    [self.navigationController pushViewController:[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:sense] animated:YES];
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) return 0;
    return 1;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != theTableView) return nil;
    
    static NSString* cellType = @"word";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType] autorelease];
    }
    
    if (!word.complete) {
        cell.textLabel.text = @"loading...";
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    
    int index = indexPath.section;
    Sense* sense = [word.senses objectAtIndex:index];
    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", index+1, sense.gloss];
    cell.detailTextLabel.text = sense.synonymsAsString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   
    return cell;
}

- (void)loadComplete:(Model *)model
{
    if (model != word) return;
    
    [self adjustInflections];
    
    [tableView reloadData];
}

- (void)adjustInflections
{
    NSString* inflections = word.inflections;
    if (inflections.length == 0) inflections = @"(none)";
    NSString* text = [NSString stringWithFormat:@"other forms: %@", inflections];
    if (word.freqCnt > 0) {
        text = [text stringByAppendingFormat:@" freq. cnt.: %d", word.freqCnt];
    }
    inflectionsLabel.text = text;
}

@end
