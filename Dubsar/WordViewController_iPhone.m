//
//  WordViewController.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/22/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "WordViewController_iPhone.h"

#import "SearchBarManager_iPhone.h"
#import "Sense.h"
#import "Word.h"

@implementation WordViewController_iPhone
@synthesize searchBarManager;
@synthesize searchBar;
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

        self.title = word.nameAndPos;
   }
    return self;
}

- (void)dealloc
{
    [word release];
    [searchBarManager release];
    [inflectionsLabel release];
    [searchBar release];
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
    searchBarManager = [SearchBarManager_iPhone managerWithSearchBar:searchBar navigationController:self.navigationController];
}

- (void)viewDidUnload
{
    [self setInflectionsLabel:nil];
    [self setSearchBar:nil];
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarSearchButtonClicked:theSearchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)theSearchBar 
{
    [searchBarManager searchBarCancelButtonClicked:theSearchBar];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar*)theSearchBar
{
    [searchBarManager searchBarTextDidBeginEditing:theSearchBar];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)theSearchBar
{
    [searchBarManager searchBarTextDidEndEditing:theSearchBar];
}

- (void)searchBar:(UISearchBar*)theSearchBar textDidChange:(NSString *)theSearchText
{
    [searchBarManager searchBar:theSearchBar textDidChange:theSearchText];
}

- (BOOL)searchBar:(UISearchBar*)theSearchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [searchBarManager searchBar:theSearchBar shouldChangeTextInRange:range
                       replacementText:text];
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section
{
    return theTableView == tableView && word.complete && word.senses ? word.senses.count : 0;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView != theTableView) return nil;
    
    static NSString* cellType = @"word";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType] autorelease];
    }
    
    int index = indexPath.row;
    Sense* sense = [word.senses objectAtIndex:index];
    
    NSString* synonymList = [NSString string];
    for(int j=0; j<sense.synonyms.count; ++j) {
        Word* synonym = [sense.synonyms objectAtIndex:j];
        synonymList = [synonymList stringByAppendingString:synonym.name];
        if (j<sense.synonyms.count-1) {
            synonymList = [synonymList stringByAppendingString:@", "];
        }
    }

    cell.textLabel.text = [NSString stringWithFormat:@"%d. %@", index+1, sense.gloss];
    cell.detailTextLabel.text = synonymList;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
   
    return cell;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ((interfaceOrientation == UIInterfaceOrientationPortrait) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) ||
        (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    
    return NO;
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
    inflectionsLabel.text = [NSString stringWithFormat:@"other forms: %@", inflections];
}

@end
