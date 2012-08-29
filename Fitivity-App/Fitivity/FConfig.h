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
#import <CoreLocation/CoreLocation.h>

@interface FConfig : NSObject {
    NSMutableDictionary *groupCreationRecords, *groupActivityRecords, *challengeGroups, *activityCreationRecords;
	NSDictionary *placeTypes;
}

@property (nonatomic, assign) CLLocationCoordinate2D mostRecentCoordinate;

// Get the singleton instance
+ (FConfig *)instance;

// Determine if the device has an internet connection
- (BOOL)connected;
- (BOOL)shouldLogIn;
- (BOOL)canCreateGroup;
- (BOOL)canCreatePA;
- (BOOL)doesHavePushNotifications;
- (BOOL)shouldShowNewActivityForGroup:(NSString *)objectID newActivityCount:(NSNumber *)n;
- (BOOL)groupHasChallenges:(NSString *)groupType;

- (NSString *)getParseAppID;
- (NSString *)getParseClientKey;
- (NSString *)getFacebookAppID;
- (NSString *)getGoogleAnalyticsID;
- (NSString *)getGooglePlacesAPIKey;
- (NSString *)getChallengeIDForActivityType:(NSString *)type;
- (NSString *)getItunesAppLink;

- (UIColor *)getFitivityBlue;

- (void)showLogoNavBar:(BOOL)status;
- (void)setDoesHaveNotifications:(BOOL)status;
- (void)incrementGroupCreationForDate:(NSDate *)date;
- (void)incrementPACreationForDate:(NSDate *)date;
- (void)updateGroup:(NSString *)objectID withActivityCount:(NSNumber *)i;

- (NSDictionary *)getTypes;

@end
