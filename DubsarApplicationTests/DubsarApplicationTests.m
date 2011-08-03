//
//  DubsarApplicationTests.m
//  DubsarApplicationTests
//
//  Created by Jimmy Dee on 8/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DubsarApplicationTests.h"

@implementation DubsarApplicationTests

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

- (void)testAppDelegate
{
    id app_delegate = [[UIApplication sharedApplication] delegate];
    STAssertNotNil(app_delegate, @"cannot find the app delegate");
}

@end
