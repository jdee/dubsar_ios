//
//  AboutViewController_iPad.h
//  Dubsar
//
//  Created by Jimmy Dee on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController_iPad : UIViewController {
    
    UILabel *versionLabel;
}
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
- (IBAction)showLicense:(id)sender;

@end
