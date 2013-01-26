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
#import "AuguryViewController_iPhone.h"
#import "DailyWord.h"
#import "Dubsar.h"
#import "DubsarViewController_iPhone.h"
#import "FAQViewController_iPhone.h"
#import "JSONKit.h"
#import "KeychainWrapper.h"
#import "ReviewViewController_iPhone.h"
#import "SyncViewController_iPhone.h"
#import "Word.h"
#import "WordViewController_iPhone.h"

#define DubsarAuguryIntroSeenKey @"com.dubsar-dictionary.Dubsar.auguryIntroSeen"

@implementation DubsarViewController_iPhone
@synthesize wotdButton;
@synthesize dailyWord;
@synthesize auguryViewController;
@synthesize emailTextField, loginView, passwordTextField;
@synthesize auguryIntroView, auguryIntroWebView;

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
        self.auguryViewController = [[AuguryViewController_iPhone alloc]
                                     initWithNibName:@"AuguryViewController_iPhone" bundle:nil];
        // augurViewController has retain semantics, so will retain this after init.
        [self.auguryViewController release];
        
        dailyWord = [[DailyWord alloc]init];
        dailyWord.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [auguryIntroWebView release];
    [auguryIntroView release];
    [auguryViewController release];
    [emailTextField release];
    [passwordTextField release];
    [loginView release];
    [dailyWord release];
    [wotdButton release];
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.loginView.hidden = YES;
#ifdef DUBSAR_EDITORIAL_BUILD
    [self checkForCredentials];
#endif // DUBSAR_EDITORIAL_BUILD
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
    
    [dailyWord load];
    
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
    [self hideAuguryIntro];
    [self presentModalViewController:self.auguryViewController animated: YES];
}

- (void)displayReview
{
    // Page 0: Load the saved page if present. Otherwise, page 1.
    ReviewViewController_iPhone* viewController = [[[ReviewViewController_iPhone alloc] initWithNibName:@"ReviewViewController_iPhone" bundle:nil page:0] autorelease];
    [viewController load];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)displaySync
{
    SyncViewController_iPhone* viewController = [[[SyncViewController_iPhone alloc] initWithNibName:@"SyncViewController_iPhone" bundle:nil] autorelease];
    [self presentModalViewController:viewController animated:YES];
}

- (void)checkForCredentials
{
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];    
    if (appDelegate.authToken == nil) {
        // see if we have the password.
        NSLog(@"Looking in keychain for password for bundle ID %@", [[NSBundle mainBundle] bundleIdentifier]);
        
        KeychainWrapper* passwordWrapper = [[KeychainWrapper alloc] initWithIdentifier:[[NSBundle mainBundle] bundleIdentifier] requestClass:kSecClassGenericPassword];
        
        NSString* password = [passwordWrapper myObjectForKey:(NSString*)kSecValueData];
        
        if (![password isEqualToString:@"none"]) {
            NSLog(@"found password in keychain");
            // have email and password. fetch the auth token.
            appDelegate.authToken = [self authenticateEmail:@"jgvdthree@gmail.com" password:password];
            
            return;
        }
        
        NSLog(@"didn't find password in keychain");

        // prompt the user
        loginView.hidden = NO;
        [passwordTextField becomeFirstResponder];
    }
}

- (IBAction)loadWotd:(id)sender
{
    if (!dailyWord.complete || dailyWord.error) return;
    
    WordViewController_iPhone* viewController = [[[WordViewController_iPhone alloc]initWithNibName:@"WordViewController_iPhone" bundle:nil word:dailyWord.word title:@"Word of the Day"]autorelease];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)login:(id)sender
{
    loginView.hidden = YES;
    [emailTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
    DubsarAppDelegate* appDelegate = (DubsarAppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegate.authToken = [self authenticateEmail:emailTextField.text password:passwordTextField.text];

    KeychainWrapper* passwordWrapper = [[KeychainWrapper alloc] initWithIdentifier:@"com.dubsar-dictionary.Dubsar" requestClass:kSecClassGenericPassword];
    [passwordWrapper mySetObject:passwordTextField.text forKey:(NSString*)kSecValueData];
}

- (NSString*)authenticateEmail:(NSString *)email password:(NSString *)password
{
    NSString* url = [NSString stringWithFormat:@"%@/tokens", DubsarSecureUrl];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    [request setHTTPMethod:@"POST"];
    
    NSString* payload = [NSString stringWithFormat:@"{\"email\":\"%@\",\"password\":\"%@\"}", email, password];
    [request setHTTPBody:[payload dataUsingEncoding:NSUTF8StringEncoding]];
    NSHTTPURLResponse* response;
    NSError* error;
    
    NSLog(@"POST %@", url);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSData* body = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSLog(@"HTTP status code %d", response.statusCode);
    
    // why 0?
    if (response.statusCode == 0 || response.statusCode >= 400) {
        NSLog(@"login failed");
        // Prompt user for password and start over
        
        loginView.hidden = NO;
        passwordTextField.text = @"";
        [passwordTextField becomeFirstResponder];
   }
    
    JSONDecoder* decoder = [JSONDecoder decoder];
    NSDictionary* jsonResponse = [decoder objectWithData:body];
    return [jsonResponse valueForKey:@"token"];
}

- (void)createToolbarItems
{
    UIBarButtonItem* faqButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"FAQ" style:UIBarButtonItemStyleBordered target:self action:@selector(displayFAQ)]autorelease];
    UIBarButtonItem* aboutButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"About" style:UIBarButtonItemStyleBordered target:self action:@selector(displayAbout)]autorelease];
    UIBarButtonItem* auguryButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Augur" style:UIBarButtonItemStyleBordered target:self action:@selector(displayAugury)]autorelease];
#ifdef DUBSAR_EDITORIAL_BUILD
    UIBarButtonItem* reviewButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Review" style:UIBarButtonItemStyleBordered target:self action:@selector(displayReview)]autorelease];
    UIBarButtonItem* syncButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Sync" style:UIBarButtonItemStyleBordered target:self action:@selector(displaySync)]autorelease];
    UIBarButtonItem* resetButtonItem = [[[UIBarButtonItem alloc]initWithTitle:@"Reset" style:UIBarButtonItemStyleBordered target:self action:@selector(resetWotd)]autorelease];
#endif // DUBSAR_EDITORIAL_BUILD
   
    NSMutableArray* buttonItems = [NSMutableArray array];
    [buttonItems addObject:faqButtonItem];
    [buttonItems addObject:aboutButtonItem];
    [buttonItems addObject:auguryButtonItem];
#ifdef DUBSAR_EDITORIAL_BUILD
    [buttonItems addObject:reviewButtonItem];
    [buttonItems addObject:resetButtonItem];
    [buttonItems addObject:syncButtonItem];
#endif // DUBSAR_EDITORIAL_BUILD
    
    self.toolbarItems = buttonItems.retain;
}

- (void)loadComplete:(Model *)model withError:(NSString *)error
{
    self.loading = false;
    if (![model isKindOfClass:DailyWord.class]) {
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

- (void)resetWotd
{
    [DailyWord resetWotd];
    [self handleWotd];
}

- (void)handleWotd
{
    [wotdButton setTitle:@"loading..." forState:UIControlStateNormal];
    [wotdButton setTitle:@"loading..." forState:UIControlStateHighlighted];
    [wotdButton setTitle:@"loading..." forState:UIControlStateSelected];
    [dailyWord load];
}

- (NSString*)htmlForAuguryIntro
{
    return
        @"<!DOCTYPE html>"
        "<html>"
            "<body style='color:#1c94c4; background-color:#fff; font: bold 12pt Trebuchet MS; text-align: center;'>"
                "Augury was one of the main occupations of the ancient <em>dubsar</em>, "
                "cataloging omens in order to predict the future. The Dubsar app now also speaks "
                "mysteriously when asked, using WordNet&reg;&apos;s generic verb frames and "
                "randomly-selected words to construct arbitrary sentences. Tap the Augur button "
                "to try it. See the FAQ for further information."
            "</body>"
        "</html>";
}

- (void)initOrientation
{
    [super initOrientation];
    
    // useful testing hook
    // [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DubsarAuguryIntroSeenKey];
    
    // BOOL value defaults to NO if not present
    if (!self.navigationController.toolbarHidden &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:DubsarAuguryIntroSeenKey]) {
        [auguryIntroWebView loadHTMLString:[self htmlForAuguryIntro] baseURL:nil];
        auguryIntroView.hidden = NO;
    }
}

- (void)hideAuguryIntro
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DubsarAuguryIntroSeenKey];
    auguryIntroView.hidden = YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        auguryIntroView.hidden = YES;
    }    
}

@end
