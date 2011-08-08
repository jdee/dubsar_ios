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

#import "DailyWord.h"
#import "DubsarViewController_iPad.h"
#import "Word.h"
#import "WordPopoverViewController_iPad.h"

@implementation DubsarViewController_iPad
@synthesize dailyWord;
@synthesize wotdButton;
@synthesize wordPopoverController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Home";
    }
    return self;
}

- (void)dealloc
{
    [dailyWord release];
    [wordPopoverController release];
    [wotdButton release];
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
    [self setWotdButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (popoverWasVisible) {
        [wordPopoverController presentPopoverFromRect:wotdButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    popoverWasVisible = wordPopoverController.popoverVisible;
    [wordPopoverController dismissPopoverAnimated:YES];        
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{    
    DailyWord* theDailyWord = (DailyWord*)model;

    if (theDailyWord.error) {
        NSLog(@"request error: %@", theDailyWord.errorMessage);
        Word* word = [[[Word alloc]init]autorelease];
        word.error = word.complete = true;
        word.errorMessage = theDailyWord.errorMessage;
        theDailyWord.word = word;
    }    
    
    WordPopoverViewController_iPad* viewController = [[[WordPopoverViewController_iPad alloc]initWithNibName:@"WordPopoverViewController_iPad" bundle:nil word:theDailyWord.word]autorelease];
    [viewController load];
    self.wordPopoverController = [[[UIPopoverController alloc]initWithContentViewController:viewController]autorelease];
    viewController.popoverController = wordPopoverController;
    viewController.navigationController = self.navigationController;
    
    [wordPopoverController presentPopoverFromRect:wotdButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)showWotd:(id)sender 
{
    dailyWord = [[DailyWord alloc]init];
    dailyWord.delegate = self;
    [dailyWord load];
}

@end
