// 
//  FConfig.h
//  Fitivity
// 
//	Configuration class to hold all cross class configuration variables
//
//  Created by Nathaniel Doe on 7/10/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FConfig : NSObject {
    NSMutableDictionary *groupCreationRecords, *groupActivityRecords;
}

// Get the singleton instance
+ (FConfig *)instance;

// Determine if the device has an internet connection
- (BOOL)connected;
- (BOOL)shouldLogIn;
- (BOOL)canCreateGroup;
- (BOOL)doesHavePushNotifications;
- (BOOL)shouldShowNewActivityForGroup:(NSString *)objectID newActivityCount:(NSNumber *)n;

- (NSString *)getParseAppID;
- (NSString *)getParseClientKey;
- (NSString *)getFacebookAppID;
- (NSString *)getGoogleAnalyticsID;
- (NSString *)getGooglePlacesAPIKey;

- (UIColor *)getFitivityBlue;

- (void)showLogoNavBar:(BOOL)status;
- (void)setDoesHaveNotifications:(BOOL)status;
- (void)incrementGroupCreationForDate:(NSDate *)date;
- (void)updateGroup:(NSString *)objectID withActivityCount:(NSNumber *)i;

@end
