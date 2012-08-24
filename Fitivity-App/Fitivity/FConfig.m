//
//  FConfig.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/10/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "FConfig.h"
#import "Reachability.h"
#import "GooglePlacesObject.h"

#define kParseAppID			@"MmUj6HxQcfLSOUs31lG7uNVx9sl5dZR6gv0FqGHq"
#define kParseClientKey		@"krpZsVM2UrU71NCxDbdAmbEMq1EXdpygkl251Wjl"
#define kFacebookAppID		@"119218824889348"	
#define kGooglePlacesAPIKey	@"AIzaSyAsh5BYpzSxUXX4a1xYqm6FZTQle52l3L4" 
#define kGoogleAnalyticsID	@""

#define kPushStatus			@"status"

#define kCreateDataPath		@"/createRecords.plist"
#define kActivityDataPath	@"/groupActivityRecords.plist"

#define kMaxCreatesPerDay   2

@implementation FConfig

@synthesize mostRecentCoordinate;

static FConfig *instance;

#pragma mark - Singleton Instance

- (void)initInstance {
    //Load past group creation records 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingString:kCreateDataPath];
    
    groupCreationRecords = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    //If this is the first load create an empty dictionary since there is no data yet
    if (groupCreationRecords == nil) {
        groupCreationRecords = [[NSMutableDictionary alloc] init];
        [groupCreationRecords writeToFile:path atomically:YES];
    }
	
	//Load group activity records
	path = [documentsDirectory stringByAppendingString:kActivityDataPath];
	groupActivityRecords  = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
	
	if (groupActivityRecords == nil) {
		groupActivityRecords = [[NSMutableDictionary alloc] init];
		[groupActivityRecords writeToFile:path atomically:YES];
	}

	//Set all of the types of places that should be allowed to create
	placeTypes = [[NSDictionary alloc] initWithObjectsAndKeys: kBowlingAlley, @"Bownling Alley",
															kCampground, @"Campground",
															kGym, @"Gym",
															kPark, @"Park",
															kSchool, @"School",
															kStadium, @"Stadium",
															kUniversity, @"University", nil];
	
}

+ (FConfig *)instance {
	@synchronized([FConfig class]) {
		if (instance == nil) {
			instance = [[FConfig alloc] init];
            [instance initInstance];
		}
	}
	return instance;
}

#pragma mark - void methods 

- (void)saveCreateData {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingString:kCreateDataPath];
    
    if ([groupCreationRecords writeToFile:path atomically:YES]) {
#ifdef DEBUG
        NSLog(@"Saved to plist");
#endif
    }
}

- (void)saveAcitivtyData {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingString:kActivityDataPath];
    
    if ([groupActivityRecords writeToFile:path atomically:YES]) {
#ifdef DEBUG
        NSLog(@"Saved to plist");
#endif
    }
}

- (void)incrementGroupCreationForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd-YYY"];
    NSString *key = [formatter stringFromDate:date];
    
    NSNumber *count;
    
    //check if the date is already in the records
    if ([groupCreationRecords objectForKey:key] != nil) {
        count = (NSNumber *)[groupCreationRecords objectForKey:key];
        count = [NSNumber numberWithInt:[count intValue] + 1];
        [groupCreationRecords setObject:count forKey:key];
    }
    else {
        count = [NSNumber numberWithInt:1];
        [groupCreationRecords setObject:count forKey:key];
    }
    [self saveCreateData];
}

- (void)updateGroup:(NSString *)objectID withActivityCount:(NSNumber *)i {
	[groupActivityRecords setObject:i forKey:objectID];
	[self saveAcitivtyData];
}

- (void)showLogoNavBar:(BOOL)status {
		
	if (status) {
		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavigationBarBackplate.png"] forBarMetrics:UIBarMetricsDefault];
	}
	else {
		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
	}
}

- (void)setDoesHaveNotifications:(BOOL)status {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:status forKey:kPushStatus];
}

- (void)initializeChallenges {
	//Get all of the most recent challenges
	challengeGroups = [[NSMutableDictionary alloc] init];
	PFQuery *query = [PFQuery queryWithClassName:@"Challenge"];
	[query whereKeyExists:@"activityType"];
	[query setCachePolicy:kPFCachePolicyNetworkElseCache];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
#ifdef DEBUG
			NSLog(@"%@", [error description]);
#endif
		}
		else if (objects) {
			for (PFObject *o in objects) {
				[o fetchIfNeeded];
				[challengeGroups setObject:[o objectId] forKey:[o objectForKey:@"activityType"]];
			}
		}
	}];

}

#pragma mark - UIColor methods

- (UIColor *)getFitivityBlue {
	return [UIColor colorWithRed:142.0/255.0f green:198.0/255.0f blue:250.0/255.0f alpha:1];
}

#pragma mark - BOOL methods

- (BOOL)groupHasChallenges:(NSString *)groupType {
	BOOL ret = NO;
	
	//If the object exists we have a challenge
	if ([challengeGroups objectForKey:groupType]) {
		ret = YES;
	}
	
	return ret;
}

- (BOOL)shouldShowNewActivityForGroup:(NSString *)objectID newActivityCount:(NSNumber *)n {
	BOOL ret = NO;
	
	NSNumber *num = (NSNumber *)[groupActivityRecords objectForKey:objectID];
	
	if (!num || [num compare:n] == NSOrderedAscending) {
		ret = YES;
	}
	
	return ret;
}

- (BOOL)userHasReachedCreationLimitForDay:(NSDate *)today {
    if (groupCreationRecords) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM-DD-YYY"];
        
        NSNumber *count = [groupCreationRecords objectForKey:[formatter stringFromDate:today]];
        NSLog(@"%i", [count intValue]);
        if ([count intValue] >= kMaxCreatesPerDay) {
            return YES;
        }
        return NO;
    }
    return YES;
}

- (BOOL)connected {
	//return NO; // force for offline testing
	Reachability *hostReach = [Reachability reachabilityForInternetConnection];	
	NetworkStatus netStatus = [hostReach currentReachabilityStatus];	
    return !(netStatus == NotReachable);
}

- (BOOL)shouldLogIn {
	return YES;
}

- (BOOL)canCreateGroup {
    //If the user hasn't reached their limit let them create one
    return ![self userHasReachedCreationLimitForDay:[NSDate date]];
}

- (BOOL)doesHavePushNotifications {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:kPushStatus];
}

#pragma mark - NSDictionary Methods

- (NSDictionary *)getTypes {
	return (placeTypes == nil) ? [[NSDictionary alloc] init] : placeTypes;
}

#pragma mark - NSString methods 

- (NSString *)getChallengeIDForActivityType:(NSString *)type {
	return [challengeGroups objectForKey:type];
}

- (NSString *)getParseAppID {
	return kParseAppID;
}

- (NSString *)getParseClientKey {
	[self performSelector:@selector(initializeChallenges) withObject:nil afterDelay:0.4];
	return kParseClientKey;
}

- (NSString *)getFacebookAppID {
	return kFacebookAppID;
}

- (NSString *)getGoogleAnalyticsID {
	return kGoogleAnalyticsID;
}

- (NSString *)getGooglePlacesAPIKey {
	return kGooglePlacesAPIKey;
}

@end
