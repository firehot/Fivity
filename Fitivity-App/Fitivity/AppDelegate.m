//
//  AppDelegate.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/10/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "AppDelegate.h"
#import "NSError+FITParseUtilities.h"
#import "FTabBarViewController.h"
#import "OpeningLogoViewController.h"
#import "ActivityHomeViewController.h"
#import "UserProfileViewController.h"
#import "DiscoverFeedViewController.h"
#import "ChooseChallengeAcitivityViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize openingView = _openingView;
@synthesize tabBarController = _tabBarController;
@synthesize selectedVC = _selectedVC;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setAutoresizesSubviews:YES];
    
	//Set up parse credentials 
	[Parse setApplicationId:[[FConfig instance] getParseAppID] clientKey:[[FConfig instance] getParseClientKey]];
	[PFFacebookUtils initializeWithApplicationId:[[FConfig instance] getFacebookAppID]];
	[PFTwitterUtils initializeWithConsumerKey:[[FConfig instance] getTwitterKey] consumerSecret: [[FConfig instance] getTwitterSecret]];
    
	//Initialize the main view controllers
	self.openingView = [[OpeningLogoViewController alloc] initWithNibName:@"OpeningLogoViewController" bundle:nil];
	DiscoverFeedViewController *discoverView = [[DiscoverFeedViewController alloc] initWithStyle:UITableViewStylePlain];
	
//	if (![self userExistsSanityCheck]) {
//		[PFUser logOut];
//		[discoverView clear];
//		[discoverView setCancelLoad:YES];
//	}
	
	ActivityHomeViewController *activity = [[ActivityHomeViewController alloc] initWithNibName:@"ActivityHomeViewController" bundle:nil];
	ChooseChallengeAcitivityViewController *challengeActivity = [[ChooseChallengeAcitivityViewController alloc] initWithNibName:@"ChooseChallengeAcitivityViewController" bundle:nil];
	UserProfileViewController *profile = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil initWithUser:[PFUser currentUser]];
	[profile setMainUser:YES];
	
	// Set up the custom tab bar titles
	[discoverView setTitle:@""];
	[[discoverView tabBarItem] setTitle:@"Discover"];
	[[discoverView tabBarItem] setImage:[UIImage imageNamed:@"discover.png"]];
	
	[activity setTitle:@""];
	[[activity tabBarItem] setTitle:@"Start Activity"];
	[[activity tabBarItem] setImage:[UIImage imageNamed:@"start_activity.png"]];
	
	[challengeActivity setTitle:@""];
	[[challengeActivity tabBarItem] setTitle:@"Challenges"];
	[[challengeActivity tabBarItem] setImage:[UIImage imageNamed:@"challenge"]];
	
	[profile setTitle:@""];
	[[profile tabBarItem] setTitle:@"Me"];
	[[profile tabBarItem] setImage:[UIImage imageNamed:@"profile.png"]];
	
	// Set up the navigation controllers
	UINavigationController *navController1 = [[UINavigationController alloc] initWithRootViewController:discoverView];
	UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:activity];
	UINavigationController *navController4 = [[UINavigationController alloc] initWithRootViewController:challengeActivity];
	UINavigationController *navController3 = [[UINavigationController alloc] initWithRootViewController:profile];
	
	self.tabBarController = [[UITabBarController alloc] init];
	[self.tabBarController setDelegate:self];
	self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController1, navController2, navController4, navController3, nil];
	self.window.rootViewController = self.tabBarController;
	
	[self.openingView setDelegate:self];
	[SocialSharer sharerWithDelegate:discoverView];
	
	self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
	
	//Reset badge count upon reopen of the app
	[application setApplicationIconBadgeNumber:0];
	
	//Present the opening view
	[activity presentModalViewController:self.openingView animated:NO];
	
	//Register for push notifications
	[application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound];
	
	//Resolve complie time errors
	[PF_FBProfilePictureView class];
	
	//increment launch counter
	int num = [[FConfig instance] getLaunchCount];
	[[FConfig instance] setLaunchCount:++num];
	
    //Update the installation info
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation setObject:@"Fitivity" forKey:@"appName"];
    [installation setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"appVersion"];
    [installation saveEventually];
    
	[self handleLaunchNotification:[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]];
	
    return YES;
}

- (void)handleLaunchNotification:(NSDictionary *)launchData {
	if (launchData) {
		tempPushInfo = launchData;
		NSString *message = [(NSDictionary *)[launchData objectForKey:@"aps"] objectForKey:@"alert"];
		NSString *paid = [launchData objectForKey:@"pa_id"];
		
		//This isn't a proposed activity push
		if (paid == nil && ![paid isEqualToString:@""]) {
			[PFPush handlePush:launchData];
			return;
		}
		
		if ([PFUser currentUser]) {
			
			//Check to see if the user is the one who sent it, if so dont show the message
			NSRange range = [message rangeOfString:[NSString stringWithFormat:@"%@",[[PFUser currentUser] username]]];
			if (range.location == NSNotFound) {
								
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Acitivty" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Join", nil];
				int64_t delayInSeconds = 2.0;
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
					[alert show];
				});
			}
		}
	}
}

- (BOOL)userExistsSanityCheck {
	if (![PFUser currentUser]) {
		return NO;
	}
	
	PFQuery *query = [PFQuery queryWithClassName:@"_User"];
	[query whereKey:@"objectId" equalTo:[[PFUser currentUser] objectId]];

	if ([query getFirstObject] != nil) {
		return YES;
	}
	return NO;
}

#pragma mark - UITabBarControllerDeleate 

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	if (!self.selectedVC || ![self.selectedVC isEqual:viewController]) {
		[self setSelectedVC:viewController];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"changedTab" object:nil];
	} 
}

#pragma mark - Opening View Delegate

-(void)viewHasFinishedAnnimating:(OpeningLogoViewController *)view {
	[view dismissModalViewControllerAnimated:YES];
}

#pragma mark - Facebook login handling 

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [PFFacebookUtils handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	return [PFFacebookUtils handleOpenURL:url]; 
}

#pragma mark - Notification handling

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Tell Parse about the device token.
    [PFPush storeDeviceToken:newDeviceToken];
    // Subscribe to the global broadcast channel.
    [PFPush subscribeToChannelInBackground:@""];
	
	//Save the push status for the settings gui
	[[FConfig instance] setDoesHaveNotifications:YES];
}

//If the user has the app open when the push goes out
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	
	tempPushInfo = userInfo;
	NSString *message = [(NSDictionary *)[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
	NSString *paid = [userInfo objectForKey:@"pa_id"];
	
	//This isn't a proposed activity push
	if (paid == nil && ![paid isEqualToString:@""]) {
		[PFPush handlePush:userInfo];
		return;
	}
	
	if ([PFUser currentUser]) {
		
		//Check to see if the user is the one who sent it, if so dont show the message
		NSRange range = [message rangeOfString:[NSString stringWithFormat:@"%@",[[PFUser currentUser] username]]];
		if (range.location == NSNotFound) {
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New Acitivty" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Join", nil];
			[alert show];
		}
	}
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if ([error code] == 3010) {
        NSLog(@"Push notifications don't work in the simulator!");
    } else {
        NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:@"Join"]) {
		[self attemptPostComment:@"I'm in!" withParentID:[tempPushInfo objectForKey:@"pa_id"]];
	}
}

#pragma mark - Queries for Push Notification Handling

- (void)attemptPostComment:(NSString *)comment withParentID:(NSString *)objectID {
	
	if (![[FConfig instance] connected]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to join a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
    }
	
	@synchronized([AppDelegate class]) {
		//Get the refference to the group
		PFObject *pa = [PFObject objectWithoutDataWithClassName:@"ProposedActivity" objectId:objectID];
		[pa fetchIfNeeded];
		
		if (pa) {
			PFObject *joinGroup = [PFObject objectWithClassName:@"Comments"];
			[joinGroup setObject:[PFUser currentUser] forKey:@"user"];
			[joinGroup setObject:pa forKey:@"parent"];
			[joinGroup setObject:comment forKey:@"message"];
			
			[joinGroup saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
				
				if (succeeded) {
#ifndef DEBUG
					NSLog(@"Succeeded Posting Comment");
#endif
//					[self.tabBarView showLeftTab];
//					NSArray *vc = [[self.tabBarView leftNavigationController] viewControllers];
//					DiscoverFeedViewController *d = (DiscoverFeedViewController *)[vc objectAtIndex:0];
//					[d handlePushNotification:pa];
				}
				else if (error) {
					NSString *errorMessage = @"An unknown error occurred while joining the group.";
					errorMessage = [error userFriendlyParseErrorDescription:YES];
					
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Joining Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
				}
			}];
		}
	}
}

#pragma mark - Application

- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	// Reset badge count
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
	[application setApplicationIconBadgeNumber:0];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	[PF_FBSession.activeSession close];
}

@end
