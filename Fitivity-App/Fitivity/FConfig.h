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
#import <Parse/Parse.h>

@interface FConfig : NSObject {
    NSMutableDictionary *groupCreationRecords, *groupActivityRecords, *challengeGroups;
	NSDictionary *placeTypes;
}

// Get the singleton instance
+ (FConfig *)instance;

// Determine if the device has an internet connection
- (BOOL)connected;
- (BOOL)shouldLogIn;
- (BOOL)canCreateGroup;
- (BOOL)doesHavePushNotifications;
- (BOOL)shouldShowNewActivityForGroup:(NSString *)objectID newActivityCount:(NSNumber *)n;
- (BOOL)groupHasChallenges:(NSString *)groupType;

- (NSString *)getParseAppID;
- (NSString *)getParseClientKey;
- (NSString *)getFacebookAppID;
- (NSString *)getGoogleAnalyticsID;
- (NSString *)getGooglePlacesAPIKey;
- (NSString *)getChallengeIDForActivityType:(NSString *)type;

- (UIColor *)getFitivityBlue;

- (void)showLogoNavBar:(BOOL)status;
- (void)setDoesHaveNotifications:(BOOL)status;
- (void)incrementGroupCreationForDate:(NSDate *)date;
- (void)updateGroup:(NSString *)objectID withActivityCount:(NSNumber *)i;

- (NSDictionary *)getTypes;

@end
