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

#import "AboutViewController_iPhone.h"
#import "AugurViewController_iPhone.h"
#import "DailyWord.h"
#import "DubsarViewController_iPhone.h"
#import "FAQViewController_iPhone.h"
#import "ReviewViewController_iPhone.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

@implementation DubsarViewController_iPhone
@synthesize wotdButton;
@synthesize dailyWord;
@synthesize augurViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Home";
        UIImage* image = [UIImage imageNamed:@"dubsar-full.png"];
        UIImageView* titleView = [[[UIImageView alloc]initWithImage:image]autorelease];
        titleView.autoresizingMask = UIViewAutoresizingNone;
        
        if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
            // iOS 6.0+
            [titleView setTranslatesAutoresizingMaskIntoConstraints:YES];
        }
        
        CGRect bounds = titleView.bounds;
        bounds.size = CGSizeMake(82.5, 30.0);
        titleView.bounds = bounds;

        self.navigationItem.titleView = titleView;
        self.augurViewController = [[AugurViewController_iPhone alloc]
                                     initWithNibName:@"AugurViewController_iPhone" bundle:nil];
        // augurViewController has retain semantics, so will retain this after init.
        [self.augurViewController release];
    }
    return self;
}

- (void)dealloc
{
    [dailyWord release];
    [wotdButton release];
    [super dealloc];
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
    [super viewWillAppear:animated];
    [self initOrientation];
    [self load];
}

- (void)load
{
    if (self.loading) return;

    [wotdButton setTitle:@"loading..." forState:UIControlStateNormal];
    [wotdButton setTitle:@"loading..." forState:UIControlStateHighlighted];
    [wotdButton setTitle:@"loading..." forState:UIControlStateSelected];
    
    self.dailyWord = [[[DailyWord alloc]init]autorelease];
    dailyWord.delegate = self;
    [dailyWord loadFromServer];
    
    self.searchBar.text = @"";
    self.loading = true;
}

- (void)displayFAQ
{
    [self presentModalViewController:[[[FAQViewController_iPhone alloc]
            initWithNibName:@"FAQViewController_iPhone" bundle:nil]autorelease] animated: YES];    
}

- (void)displayAbout
{
    AboutViewController_iPhone* aboutViewController = [[[AboutViewController_iPhone alloc]
                                                        initWithNibName:@"AboutViewController_iPhone" bundle:nil]autorelease];
    aboutViewController.mainViewController = self;
    [self presentModalViewController:aboutViewController animated: YES];
}

- (void)displayAugury
{
    [self presentModalViewController:self.augurViewController animated: YES];
}

- (void)displayReview
{
    ReviewViewController_iPhone* viewController = [[[ReviewViewController_iPhone alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:1] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)loadWotd:(id)sender
{
    if (!dailyWord.complete || dailyWord.error) return;
    
    WordViewController_iPhone* viewController = [[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:dailyWord.word]autorelease];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)createToolbarItems
{
    UIBarButtonItem* faqButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"FAQ" style:UIBarButtonItemStyleBordered target:self action:@selector(displayFAQ)]autorelease];
    UIBarButtonItem* aboutButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"About" style:UIBarButtonItemStyleBordered target:self action:@selector(displayAbout)]autorelease];
    UIBarButtonItem* augurButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Augur" style:UIBarButtonItemStyleBordered target:self action:@selector(displayAugury)]autorelease];
    UIBarButtonItem* reviewButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Review" style:UIBarButtonItemStyleBordered target:self action:@selector(displayReview)]autorelease];
    
    NSMutableArray* buttonItems = [NSMutableArray array];
    [buttonItems addObject:faqButtonItem];
    [buttonItems addObject:aboutButtonItem];
    [buttonItems addObject:augurButtonItem];
    [buttonItems addObject:reviewButtonItem];
    
    self.toolbarItems = buttonItems.retain;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    self.loading = false;
    if (![model isMemberOfClass:DailyWord.class]) {
        return;
    }
    
    Word* word = dailyWord.word;
    
    NSString* title;
    if (dailyWord.error) {
        title = dailyWord.errorMessage;
    }
    else {
        title = [NSString stringWithFormat:@"%@", word.nameAndPos];
        if (word.freqCnt > 0) {
            title = [title stringByAppendingFormat:@" freq. cnt.: %d", word.freqCnt];
        }
        /*
         if (word.inflections > 0) {
         title = [title stringByAppendingFormat:@"; also %@", word.inflections];
         }
         */
    }
    
    [wotdButton setTitle:title forState:UIControlStateNormal];
    [wotdButton setTitle:title forState:UIControlStateHighlighted];
    [wotdButton setTitle:title forState:UIControlStateSelected];
}

@end
