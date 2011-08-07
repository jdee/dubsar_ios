//
//  DubsarApplicationTests_iPad.m
//  DubsarApplicationTests_iPad
//
//  Created by Jimmy Dee on 8/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DubsarApplicationTests_iPad.h"

@implementation DubsarApplicationTests_iPad

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    id app_delegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(app_delegate, @"cannot find the app delegate");
    // STFail(@"Unit tests are not implemented yet in DubsarApplicationTests_iPad");
}

@end
