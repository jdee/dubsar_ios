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

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    Sense* sense = [word.senses objectAtIndex:index];
    [self.navigationController pushViewController:[[SenseViewController_iPhone alloc]initWithNibName:@"SenseViewController_iPhone" bundle:nil sense:sense] animated:YES];
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    if (theTableView != tableView) return 0;
    return word.complete && word.senses ? word.senses.count : 1;
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
    
    int index = indexPath.row;
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
