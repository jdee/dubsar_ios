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

#import "InflectionsViewController_iPhone.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

@interface InflectionsViewController_iPhone ()

@end

@implementation InflectionsViewController_iPhone
@synthesize tableView;
@synthesize word;
@synthesize parent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil word:(Word *)theWord parent:(WordViewController_iPhone *)theParent
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.word = theWord;
        self.parent = theParent; // assign, not retain
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setViewFrame) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setViewFrame];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setViewFrame];
}

- (void)setViewFrame
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    int max = UIInterfaceOrientationIsLandscape(orientation) ? 4 : 7;
    int count = word.inflections.count > max ? max : word.inflections.count;
    
    CGRect frame = self.view.frame;
    frame.size.height = count * 44.0 + 74.0;
    self.view.frame = frame;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"Other forms of %@", word.nameAndPos];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return word.inflections.count;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    
    NSString* inflection = [word.inflections objectAtIndex:row];
    static NSString* cellType = @"inflection";
    
    UITableViewCell* cell = [theTableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellType]autorelease];
    }
    
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    
    cell.textLabel.textColor = appDelegate.dubsarTintColor;
    cell.textLabel.font = appDelegate.dubsarNormalFont;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.text = inflection;
    
    return cell;
}

- (IBAction)dismiss:(id)sender
{
    [parent dismissInflections];
}

@end
