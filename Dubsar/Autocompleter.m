//
//  Autocompleter.m
//  Dubsar
//
//  Created by Jimmy Dee on 7/24/11.
//  Copyright 2011 Jimmy Dee. All rights reserved.
//

#import "Autocompleter.h"
#import "Dubsar.h"
#import "JSONKit.h"


@implementation Autocompleter

@synthesize results=_results;
@synthesize term=_term;

- (id)initWithTerm:(NSString *)theTerm
{
    self = [super init];
    if (self) {
        _term = [[theTerm copy]retain];
        _results = nil;
        _url = [NSString stringWithFormat:@"%@/os.json?term=%@", DubsarBaseUrl, _term];
    }
    return self;
}

- (void)dealloc
{
    [_term release];
    [_results release];
    [super dealloc];
}

- (void)parseData
{
    NSArray* response = [decoder objectWithData:data];
    
    NSMutableArray* r = [[NSMutableArray array]retain];
    NSArray* list = [response objectAtIndex:1];
    for (int j=0; j<3 && j<list.count; ++j) {
        [r addObject:[list objectAtIndex:j]];
    }
    _results = r;
    
    NSLog(@"autocompleter for term \"%@\" (URL \"%@\") finished with %d results:", [response objectAtIndex:0], _url, _results.count);
}

@end
