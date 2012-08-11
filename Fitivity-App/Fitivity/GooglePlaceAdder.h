//
//  GooglePlaceAdder.h
//  Fitivity
//
//  Created by Nathan Doe on 8/10/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GooglePlaceAdderDelegate;

@interface GooglePlaceAdder : NSObject {
	NSMutableData *responseData;
	NSURLConnection *connection;
	
	BOOL activeConnection;
}

- (void)sendPlace:(NSDictionary *)info;

@property (nonatomic, assign) id <GooglePlaceAdderDelegate> delegate;

@end

@protocol GooglePlaceAdderDelegate <NSObject>

- (void) didFinishSendingNewPlace:(NSDictionary *)ref;
- (void) didFinishWithError:(NSError *)error;

@end