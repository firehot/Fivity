//
//  GooglePlaceAdder.m
//  Fitivity
//
//  Created by Nathan Doe on 8/10/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import "GooglePlaceAdder.h"
#import "SBJson.h"

@implementation GooglePlaceAdder

@synthesize delegate;

- (void)sendPlace:(NSDictionary *)info {
	
	if (!activeConnection) {
		NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/add/json?sensor=true&key=%@", [[FConfig instance] getGooglePlacesAPIKey]];
		
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
		
		NSString *jsonBody = [info JSONRepresentation];
		NSData *requestData = [NSData dataWithBytes:[jsonBody UTF8String] length:[jsonBody length]];
		
		[request setHTTPMethod:@"POST"];
		[request setHTTPBody:requestData];
		
		//Make sure nothing is going on before sending data
		connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
		
		if (connection) {
			responseData = [NSMutableData data];
			activeConnection = YES;
		}
	}
}

#pragma mark - NSURLConnection Delegate 

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response  {
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data  {
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error  {
	activeConnection = NO;
	
	if ([delegate respondsToSelector:@selector(didFinishWithError:)]) {
		[delegate didFinishWithError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn  {
	activeConnection = NO;
	NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSDictionary *response = [parser objectWithString:responseString];
	
	if ([delegate respondsToSelector:@selector(didFinishSendingNewPlace:)]) {
		[delegate didFinishSendingNewPlace:response];
	}
}

@end
