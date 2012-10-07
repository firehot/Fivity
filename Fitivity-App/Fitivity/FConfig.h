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

#import "Reachability.h"

@interface FConfig : NSObject {
    NSMutableDictionary *groupCreationRecords, *groupActivityRecords, *challengeGroups, *activityCreationRecords, *challengesViewed;
	NSDictionary *placeTypes;
}

@property (nonatomic, assign) CLLocationCoordinate2D mostRecentCoordinate;
@property (nonatomic, retain) NSMutableArray *searchActivities;

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
- (BOOL)shouldSharePAStart;
- (BOOL)shouldShareGroupStart;
- (BOOL)shouldShareChallenge;
- (BOOL)shouldShareChallenge:(NSString *)cid;

- (NSString *)getParseAppID;
- (NSString *)getParseClientKey;
- (NSString *)getFacebookAppID;
- (NSString *)getTwitterKey;
- (NSString *)getTwitterSecret;
- (NSString *)getGoogleAnalyticsID;
- (NSString *)getGooglePlacesAPIKey;
- (NSString *)getChallengeIDForActivityType:(NSString *)type;
- (NSString *)getItunesAppLink;
- (NSString *)getSortedFeedKey;

- (UIColor *)getFitivityBlue;
- (UIColor *)getFitivityGreen;

- (void)showLogoNavBar:(BOOL)status;
- (void)setDoesHaveNotifications:(BOOL)status;
- (void)incrementGroupCreationForDate:(NSDate *)date;
- (void)incrementPACreationForDate:(NSDate *)date;
- (void)setSharedForChallenge:(NSString *)challengeID;
- (void)updateGroup:(NSString *)objectID withActivityCount:(NSNumber *)i;
- (void)setSharePAPost:(BOOL)status;
- (void)setShareGroupPost:(BOOL)status;
- (void)setShareChallenge:(BOOL)status;
- (void)setSortedFeedKey:(NSString *)key;
- (void)setLaunchCount:(int)count;

- (NSDictionary *)getTypes;

- (NSArray *)getFacebookPermissions;

- (NetworkStatus)currentNetworkStatus;

- (int)getLaunchCount;

@end
