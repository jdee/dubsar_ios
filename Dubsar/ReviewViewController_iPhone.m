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

#import "DubsarViewController_iPhone.h"
#import "Inflection.h"
#import "ReviewViewController_iPhone.h"
#import "Review.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

@interface ReviewViewController_iPhone ()

@end

@implementation ReviewViewController_iPhone
@synthesize loading;
@synthesize selectField;
@synthesize selectView;
@synthesize tableView;
@synthesize review;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil page:(int)page
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.review = [Review reviewWithPage:page];
        self.review.delegate = self;
        self.title = [NSString stringWithFormat:@"Review p. %d", page];
        self.loading = false;
        
        [self createToolbarItems];
    }
    return self;
}

- (void)dealloc
{
    [review release];
    [super dealloc];
}

- (void)load
{
    if (self.loading || (review.complete && !review.error)) return;
 
    [review load];

    self.loading = true;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.selectView.hidden = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    NSLog(@"Review response received");
    self.loading = false;
    
    if (model != review) return;
    
    NSLog(@"Response is for our request");
    
    if (error) {
        // handle error
        NSLog(@"Error : %@", error);
        
        return;
    }
    
    NSLog(@"Reloading table view");
    
    self.title = [NSString stringWithFormat:@"Review p. %d/%d", review.page, review.totalPages];

    [self createToolbarItems];
    [tableView reloadData];
}

- (void)createToolbarItems
{
    NSMutableArray* buttonItems = [NSMutableArray array];
    
    UIBarButtonItem* item = [[[UIBarButtonItem alloc] initWithTitle:@"Home" style: UIBarButtonItemStyleBordered target:self action:@selector(loadMain)]autorelease];
    [buttonItems addObject:item];
    
    if (review && review.complete && review.page > 1) {
        item = [[[UIBarButtonItem alloc]initWithTitle:@"Prev" style:UIBarButtonItemStyleBordered target:self action:@selector(loadPrev)]autorelease];
        [buttonItems addObject:item];
    }
    if (review && review.complete && review.page < review.totalPages) {
        item = [[[UIBarButtonItem alloc]initWithTitle:@"Next" style:UIBarButtonItemStyleBordered target:self action:@selector(loadNext)]autorelease];
        [buttonItems addObject:item];
    }
    
    item = [[[UIBarButtonItem alloc] initWithTitle:@"Select" style: UIBarButtonItemStyleBordered target:self action:@selector(displaySelectView)]autorelease];
    [buttonItems addObject:item];
    
    self.toolbarItems = buttonItems;
}

- (void) loadPrev
{
    int prevPage = review.page - 1;
    ReviewViewController_iPhone* viewController = [[[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:prevPage] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) loadNext
{
    int nextPage = review.page + 1;
    ReviewViewController_iPhone* viewController = [[[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:nextPage] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) loadMain
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

# pragma mark - Table View Management

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    Inflection* inflection = [review.inflections objectAtIndex:indexPath.row];
    WordViewController_iPhone* viewController = [[[WordViewController_iPhone alloc] initWithNibName:@"WordViewController_iPhone" bundle:nil word:inflection.word]autorelease];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return loading ? 1 : review.inflections.count;
}

- (UITableViewCell*)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellType = @"inflection";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellType]autorelease];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    if (!review || !review.complete) {
        NSLog(@"review is not complete");
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"indicator"];
        if (cell == nil) {
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"indicator"]autorelease];
        }
        UIActivityIndicatorView* indicator = [[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]autorelease];
        [cell.contentView addSubview:indicator];
        CGRect frame = CGRectMake(10.0, 10.0, 24.0, 24.0);
        indicator.frame = frame;
        [indicator startAnimating];
        return cell;
    }
    
    int row = indexPath.row;
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];

    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.detailTextLabel.font = appDelegate.dubsarSmallFont;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    Inflection* inflection = [review.inflections objectAtIndex:row];
    cell.textLabel.text = inflection.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%@.)", inflection.word.name, inflection.word.pos];
    
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section
{
    return nil;
}

- (IBAction)selectPage:(id)sender
{
    [self dismissSelectView:sender];
    int pageNo = [selectField.text intValue];
    ReviewViewController_iPhone* viewController = [[[self.class alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:pageNo] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)displaySelectView
{
    selectView.hidden = NO;
}

- (IBAction)dismissSelectView:(id)sender
{
    [selectField resignFirstResponder];
    selectView.hidden = YES;
}

@end
