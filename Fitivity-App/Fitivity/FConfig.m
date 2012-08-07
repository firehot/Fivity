//
//  FConfig.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/10/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "FConfig.h"
#import "Reachability.h"

#define kParseAppID			@"MmUj6HxQcfLSOUs31lG7uNVx9sl5dZR6gv0FqGHq"
#define kParseClientKey		@"krpZsVM2UrU71NCxDbdAmbEMq1EXdpygkl251Wjl"
#define kFacebookAppID		@"119218824889348"	
#define kGooglePlacesAPIKey	@"AIzaSyAsh5BYpzSxUXX4a1xYqm6FZTQle52l3L4" 
#define kGoogleAnalyticsID	@""

#define kPushStatus			@"status"

#define kMaxCreatesPerDay   2

@implementation FConfig

static FConfig *instance;

#pragma mark - Singleton Instance

- (void)initInstance {
    //Load past group creation records 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingString:@"/createRecords.plist"];
    
    groupCreationRecords = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    //If this is the first load create an empty dictionary since there is no data yet
    if (groupCreationRecords == nil) {
        groupCreationRecords = [[NSMutableDictionary alloc] init];
        [groupCreationRecords writeToFile:path atomically:YES];
    }
	
	//Load group activity records
	path = [documentsDirectory stringByAppendingString:@"/groupActivityRecords.plist"];
	groupActivityRecords  = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
	
	if (groupActivityRecords == nil) {
		groupActivityRecords = [[NSMutableDictionary alloc] init];
		[groupActivityRecords writeToFile:path atomically:YES];
	}
	
	NSLog(@"group create = %@, activity count = %@", [groupCreationRecords description], [groupActivityRecords description]);
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
    NSString *path = [documentsDirectory stringByAppendingString:@"/createRecords.plist"];
    
    if ([groupCreationRecords writeToFile:path atomically:YES]) {
#ifdef DEBUG
        NSLog(@"Saved to plist");
#endif
    }
}

- (void)saveAcitivtyData {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingString:@"/groupActivityRecords.plist"];
    
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
		[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavigationBarBackplateBlank.png"] forBarMetrics:UIBarMetricsDefault];
	}
}

- (void)setDoesHaveNotifications:(BOOL)status {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:status forKey:kPushStatus];
}

#pragma mark - BOOL methods

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

#pragma mark - NSString methods 

- (NSString *)getParseAppID {
	return kParseAppID;
}

- (NSString *)getParseClientKey {
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
