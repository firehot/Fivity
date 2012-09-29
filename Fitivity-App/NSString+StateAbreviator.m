//
//  NSString+StateAbreviator.m
//  Fitivity
//
//  Created by Nathan Doe on 9/29/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import "NSString+StateAbreviator.h"

@implementation NSString (StateAbreviator)

- (NSString *)abreviateStateString {
	NSDictionary *states = [[NSDictionary alloc] initWithObjectsAndKeys:@"AL", @"Alabama",
																		@"AK", @"Alaska",
																		@"AZ", @"Arizona",
																		@"AR", @"Arkansas",
																		@"CA", @"California",
																		@"CO", @"Colorado",
																		@"CT", @"Connecticut",
																		@"DE", @"Delaware",
																		@"FL", @"Florida",
																		@"GA", @"Georgia",
																		@"HI", @"Hawaii",
																		@"ID", @"Idaho",
																		@"IL", @"Illinois",
																		@"IN", @"Indiana",
																		@"IA", @"Iowa",
																		@"KS", @"Kansas",
																		@"KY", @"Kentucky",
																		@"LA", @"Lousiana",
																		@"ME", @"Maine",
																		@"MD", @"Maryland",
																		@"MA", @"Massachusetts",
																		@"MI", @"Michigan",
																		@"MN", @"Minnesota",
																		@"MS", @"Mississippi",
																		@"MO", @"Missouri",
																		@"MT", @"Montana",
																		@"NE", @"Nebraska",
																		@"NV", @"Nevada",
																		@"NH", @"New Hampshire",
																		@"NJ", @"New Jersey",
																		@"NM", @"New Mexico",
																		@"NY", @"New York",
																		@"NC", @"North Carolina",
																		@"ND", @"North Dakota",
																		@"OH", @"Ohio",
																		@"OK", @"Oklahoma",
																		@"OR", @"Oregon",
																		@"PA", @"Pennsylvania",
																		@"RI", @"Rhode Island",
																		@"SC", @"South Carolina",
																		@"SD", @"South Dakota",
																		@"TN", @"Tennessee",
																		@"TX", @"Texas",
																		@"UT", @"Utah",
																		@"VT", @"Vermont",
																		@"VA", @"Virginia",
																		@"WA", @"Washington",
																		@"WV", @"West Virginia",
																		@"WI", @"Wisconsin",
																		@"WY", @"Wyoming",
																		nil];
	NSString *ab;

	// If the whole address is passed in return the whole thing back
	if ([[self componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]] count] > 1) {
		ab = self;
	} else {
		ab = [states objectForKey:self];
		if (ab == nil) {
			ab = self;
		}
	}
	return ab;
}

@end
