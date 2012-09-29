//
//  FConfig.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/10/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "FConfig.h"
#import "GooglePlacesObject.h"

#define kParseAppID			@"MmUj6HxQcfLSOUs31lG7uNVx9sl5dZR6gv0FqGHq"
#define kParseClientKey		@"krpZsVM2UrU71NCxDbdAmbEMq1EXdpygkl251Wjl"
#define kFacebookAppID		@"119218824889348"	
#define kTwitterKey         @"DM6PEQ49Vak0zP4KWxpAbw"
#define kTwitterSecret      @"TIzaIKoq2n0Oi4QY5naE1UOXRyTmdlNfi6SlS005c"
#define kGooglePlacesAPIKey	@"AIzaSyAsh5BYpzSxUXX4a1xYqm6FZTQle52l3L4" 
#define kGoogleAnalyticsID	@""

#define kPushStatus			@"status"
#define kPostGroupStart		@"groupshare"
#define kPostPAStart		@"pashare"
#define kPostChallenge		@"challengeshare"
#define kSortedFeedKey		@"All Activities"

#define kCreateDataPath		@"/createRecords.plist"
#define kActivityDataPath	@"/groupActivityRecords.plist"
#define kPADataPath			@"/proposedActivityRecords.plist"
#define kChallengePath		@"/challengeRecords.plist"

#define kItunesAppLink		@"http://itunes.apple.com/us/app/id558072406?mt=8"

#define kMaxGroupCreates	5
#define kMaxPACreates		2

@implementation FConfig

@synthesize mostRecentCoordinate;
@synthesize searchActivities;

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

	//Load past acitivty creation records 
	path = [documentsDirectory stringByAppendingString:kPADataPath];
	activityCreationRecords  = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
	
	if (activityCreationRecords == nil) {
		activityCreationRecords = [[NSMutableDictionary alloc] init];
		[activityCreationRecords writeToFile:path atomically:YES];
	}

	path = [documentsDirectory stringByAppendingString:kChallengePath];
	challengesViewed = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
	
	if (challengesViewed == nil) {
		challengesViewed = [[NSMutableDictionary alloc] init];
		[challengesViewed writeToFile:path atomically:YES];
	}
	
	//Set all of the types of places that should be allowed to create
	placeTypes = [[NSDictionary alloc] initWithObjectsAndKeys: kBowlingAlley, @"Bowling Alley",
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

- (void)saveGroupCreateData {
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

- (void)savePACreateData {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingString:kPADataPath];
    
    if ([activityCreationRecords writeToFile:path atomically:YES]) {
#ifdef DEBUG
        NSLog(@"Saved to plist");
#endif
    }
}

- (void)saveChallengeData {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingString:kChallengePath];
    
    if ([challengesViewed writeToFile:path atomically:YES]) {
#ifdef DEBUG
        NSLog(@"Saved to plist");
#endif
    }
}

- (void)incrementPACreationForDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM-dd-YYY"];
    NSString *key = [formatter stringFromDate:date];
    
    NSNumber *count;
    
    //check if the date is already in the records
    if ([activityCreationRecords objectForKey:key] != nil) {
        count = (NSNumber *)[activityCreationRecords objectForKey:key];
        count = [NSNumber numberWithInt:[count intValue] + 1];
        [activityCreationRecords setObject:count forKey:key];
    }
    else {
        count = [NSNumber numberWithInt:1];
        [activityCreationRecords setObject:count forKey:key];
    }
    [self savePACreateData];
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
    [self saveGroupCreateData];
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

- (void)setSharePAPost:(BOOL)status {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:status forKey:kPostPAStart];
}

- (void)setShareGroupPost:(BOOL)status {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:status forKey:kPostGroupStart];
}

- (void)setShareChallenge:(BOOL)status {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:status forKey:kPostChallenge];
}

- (void)setSortedFeedKey:(NSString *)key {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:key forKey:kSortedFeedKey];
}

- (void)setSharedForChallenge:(NSString *)challengeID {
    if ([challengesViewed objectForKey:challengeID] == nil) {
        [challengesViewed setObject:@"Shared" forKey:challengeID];
    }
	[self saveChallengeData];
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

- (void)initializeSearchActivites {
	PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
	[query addAscendingOrder:@"popularity"];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (!error) {
			//searchActivities = [NSMutableArray arrayWithArray:objects];
			searchActivities = [[NSMutableArray alloc] initWithObjects:@"All Activities", nil];
			
			for (PFObject *o in objects) {
				[searchActivities addObject:[o objectForKey:@"name"]];
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

- (BOOL)userHasReachedGroupCreationLimitForDay:(NSDate *)today {
    if (groupCreationRecords) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM-dd-YYY"];
        
        NSNumber *count = [groupCreationRecords objectForKey:[formatter stringFromDate:today]];
        NSLog(@"%i", [count intValue]);
        if ([count intValue] >= kMaxGroupCreates) {
            return YES;
        }
        return NO;
    }
    return YES;
}

- (BOOL)userHasReachedPACreationLimitForDay:(NSDate *)today {
    if (activityCreationRecords) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM-dd-YYY"];
        
		NSString *key = [formatter stringFromDate:today];
        NSNumber *count = [activityCreationRecords objectForKey:key];
        NSLog(@"%i", [count intValue]);
        if ([count intValue] >= kMaxPACreates) {
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
    return ![self userHasReachedGroupCreationLimitForDay:[NSDate date]];
}

- (BOOL)canCreatePA {
	//If the user hasn't reached their limit let them create one
    return ![self userHasReachedPACreationLimitForDay:[NSDate date]];
}

- (BOOL)doesHavePushNotifications {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:kPushStatus];
}

- (BOOL)shouldShareGroupStart {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:kPostGroupStart];
}

- (BOOL)shouldSharePAStart {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:kPostPAStart];
}

- (BOOL)shouldShareChallenge {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults boolForKey:kPostChallenge];
}

- (BOOL)shouldShareChallenge:(NSString *)cid {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	NSString *n = (NSString *)[challengesViewed objectForKey:cid];
	return [defaults boolForKey:kPostChallenge] && n == nil;
}

#pragma mark - NSDictionary Methods

- (NSDictionary *)getTypes {
	return (placeTypes == nil) ? [[NSDictionary alloc] init] : placeTypes;
}

#pragma mark - NSArray Methods 

- (NSArray *)getFacebookPermissions {
	return [NSArray arrayWithObjects:@"user_about_me", @"user_birthday", @"user_location", @"email", @"publish_stream", @"offline_access", nil];
}

#pragma mark - NetworkStatus Methods 

- (NetworkStatus)currentNetworkStatus {
	Reachability *hostReach = [Reachability reachabilityForInternetConnection];
	return [hostReach currentReachabilityStatus];
}

#pragma mark - NSString methods 

- (NSString *)getChallengeIDForActivityType:(NSString *)type {
	return [challengeGroups objectForKey:type];
}

- (NSString *)getItunesAppLink {
	return kItunesAppLink;
}

- (NSString *)getParseAppID {
	return kParseAppID;
}

- (NSString *)getParseClientKey {
	[self performSelector:@selector(initializeSearchActivites) withObject:nil afterDelay:0.4];
	[self performSelector:@selector(initializeChallenges) withObject:nil afterDelay:0.4];
	return kParseClientKey;
}

- (NSString *)getTwitterKey {
    return kTwitterKey;
}

- (NSString *)getTwitterSecret {
    return kTwitterSecret;
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

- (NSString *)getSortedFeedKey {
	return [[NSUserDefaults standardUserDefaults] objectForKey:kSortedFeedKey];
}

@end
