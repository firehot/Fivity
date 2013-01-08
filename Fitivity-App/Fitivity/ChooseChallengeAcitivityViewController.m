//
//  ChooseChallengeAcitivityViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 12/21/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import "ChooseChallengeAcitivityViewController.h"
#import "ChallengesViewController.h"
#import "NSError+FITParseUtilities.h"
#import "ChooseActivityCell.h"
#import "GroupPageViewController.h"
#import "SocialSharer.h"

#define kRowHeight		45
#define kDistanceMileFilter		0.15

@interface ChooseChallengeAcitivityViewController ()

@end

@implementation ChooseChallengeAcitivityViewController

@synthesize activities, activityTable, chooseLocationView, selectedActivity, selectedPlace, groupRef;

#pragma mark - Helper Methods

- (void)resetState {
	[self setSelectedPlace:nil];
	[self setSelectedActivity:nil];
}

- (void)handlePop {
	[self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)shareNewGroup {
	if ([[FConfig instance] shouldShareGroupStart]) {
		if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
			
			NSString *message = [NSString stringWithFormat:@"I just joined the %@ group at %@ using fitivity!", selectedActivity, [selectedPlace name]];
			
			NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										   [[FConfig instance] getFacebookAppID], @"app_id",
										   [[FConfig instance] getItunesAppLink], @"link",
										   @"http://www.fitivitymovement.com/FitivityAppIcon.png", @"picture",
										   @"Fitivity", @"name",
										   @"You can download it in in the Apple App Store or in Google Play", @"description",
										   message,  @"message",
										   nil];
			[[SocialSharer sharer] shareWithFacebook:params facebook:[PFFacebookUtils facebook]];
		}
		if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
			[[SocialSharer sharer] shareMessageWithTwitter:[NSString stringWithFormat:@"I just joined the %@ group at %@ using fitivity!", selectedActivity, [selectedPlace name]] image:nil link:[NSURL URLWithString:[[FConfig instance] getItunesAppLink]]];
		}
	}
	
}

#pragma mark - Query 

- (void)getChallengeActivities {
	if ([[FConfig instance] connected]) {
		PFQuery *query = [PFQuery queryWithClassName:@"Activity"];
		[query setCachePolicy:kPFCachePolicyNetworkElseCache]; //If the user isn't connected, it will look on the device disk for a cached version
		[query addAscendingOrder:@"name"];
		[query whereKey:@"category" equalTo:@"Workout Challenges"];
		[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
			if (!error) {
				activities = [NSMutableArray arrayWithArray:objects];
			}
			[self.activityTable reloadData];
		}];
	}
}

//Checks to see if the group already exists, if so join the user to the group
- (BOOL)groupAlreadyExists {
	BOOL ret = NO;
	
	CLLocationCoordinate2D point = [selectedPlace coordinate];
	PFGeoPoint *loc = [PFGeoPoint geoPointWithLatitude:point.latitude longitude:point.longitude];
	
	PFQuery *query = [PFQuery queryWithClassName:@"Groups"];
	[query whereKey:@"location" nearGeoPoint:loc withinMiles:kDistanceMileFilter];
	[query whereKey:@"place" equalTo:[selectedPlace name]];
	[query whereKey:@"activity" equalTo:selectedActivity];
	
	//If we get a result we know that the group has already been created
	PFObject *result = [query getFirstObject];
	if (result) {
		groupRef = result;
		ret = YES;
	}
	
	return ret;
}

- (void)attemptUpdateGroupInfo:(BOOL)userJoining objectID:(NSString *)objectID {
	@synchronized(self) {
		//Update group member count logic
		PFQuery *query = [PFQuery queryWithClassName:@"ActivityEvent"];
		[query whereKey:@"group" equalTo:[PFObject objectWithoutDataWithClassName:@"Groups" objectId:objectID]];
		[query whereKey:@"postType" equalTo:[NSNumber numberWithInt:0]];
		
		PFObject *updateGroup = [query getFirstObject];
		
		if (updateGroup) {
			NSNumber *num = [updateGroup objectForKey:@"number"];
			if (userJoining) {
				//User is joining the group
				int temp = [num integerValue] + 1;
				[updateGroup setObject:[NSNumber numberWithInt:temp] forKey:@"number"];
			}
			[updateGroup save];
		}
	}
}

- (BOOL)findUserAlreadyJoined {
	BOOL ret = NO;
	
	//Find if they are already part of the group
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query whereKey:@"user" equalTo:[PFUser currentUser]];
	[query whereKey:@"activity" equalTo:selectedActivity];
	[query whereKey:@"place" equalTo:[selectedPlace name]];
	
	PFObject *result = [query getFirstObject];
	if (result) {
		ret = YES;
	}
	
	return ret;
}

- (void)attemptJoinGroupWithObjectId:(NSString *)objectID updateInfo:(BOOL)update {
    
	@synchronized(self) {
		CLLocationCoordinate2D point = [selectedPlace coordinate];
		PFGeoPoint *loc = [PFGeoPoint geoPointWithLatitude:point.latitude longitude:point.longitude];
		
		PFUser *user = [PFUser currentUser];
		PFObject *post = [PFObject objectWithClassName:@"GroupMembers"];
		[post setObject:user forKey:@"user"];
		[post setObject:selectedActivity forKey:@"activity"];
		[post setObject:[selectedPlace name] forKey:@"place"];
		[post setObject:loc forKey:@"location"];
		
		if (objectID) {
			[post setObject:objectID forKey:@"group"];
		}
		
		[post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			
			NSString *errorMessage = @"An unknown error uccoured while joining group.";
			if (error) {
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Join Group Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			if (succeeded) {
				
				if (update) {
					[self attemptUpdateGroupInfo:YES objectID:objectID];
				}
				
				[self shareNewGroup];
				
				//Subscribe to notifications
				if ([[FConfig instance] doesHavePushNotifications]) {
					NSString *channel = [NSString stringWithFormat:@"Fitivity%@", objectID];
					[PFPush subscribeToChannelInBackground:channel];
				}
				
				//Notify other classes & user that they joined the group
				[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
				
				MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
				[self.navigationController.view addSubview:HUD];
				
				HUD.delegate = self;
				HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
				HUD.mode = MBProgressHUDModeCustomView;
				HUD.labelText = @"Stored in Profile";
				
				[HUD show:YES];
				[HUD hide:YES afterDelay:3.00];
			}
		}];
	}
}


- (void)showGroupViewWithAutoJoin:(BOOL)autojoin groupId:(NSString *)groupID alreadyExists:(BOOL)exists {
	
	/*
	 *	Create the group with the selected information, pop the old view from the stack (unanimated) and present the new one so there is no odd transition.
	 *	Once the views have finished presenting, reset the state of the picker view.
	 */
	[self.navigationController popToRootViewControllerAnimated:NO];
	
	if (autojoin) {
		[self attemptJoinGroupWithObjectId:groupID updateInfo:exists];
	}
	
	BOOL challenge = [[FConfig instance] groupHasChallenges:selectedActivity];
	GroupPageViewController *groupView = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:selectedPlace activity:selectedActivity challenge:challenge autoJoin:NO];
	ChallengesViewController *challengeView = [[ChallengesViewController alloc] initWithNibName:@"ChallengesViewController" bundle:nil groupType:selectedActivity groupLocation:[selectedPlace name]];
	
	[self.navigationController pushViewController:groupView animated:NO];
	[self.navigationController pushViewController:challengeView animated:YES];
	
	[self resetState];
}

- (void)attemptPostGroupToFeedWithID:(NSString *)id {
	@synchronized(self) {
		//Get the user, group just created, and a new activityevent
		PFUser *user = [PFUser currentUser];
		PFObject *event = [PFObject objectWithClassName:@"ActivityEvent"];
		PFObject *group = [PFObject objectWithoutDataWithClassName:@"Groups" objectId:id];
		
		//configure the activityevent
		[event setObject:user forKey:@"creator"];
		[event setObject:group forKey:@"group"];
		[event setObject:[NSNumber numberWithInt:1] forKey:@"number"]; //Only one user currently
		[event setObject:[NSNumber numberWithInt:0] forKey:@"postType"];
		
		//If it doesn't save the first time, don't worry about it and try again in the future.
		if (![event save]) {
			[event saveEventually];
		}
	}
}

- (void)attemptToCreateGroup {
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to create a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[self.navigationController popToRootViewControllerAnimated:YES];
		[self resetState];
		return;
	}
	
	@synchronized(self) {
		
		if (![[FConfig instance] canCreateGroup]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Limit Exceeded" message:@"You have already created the max number (5) of groups today." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[self.navigationController popToRootViewControllerAnimated:YES];
			[self resetState];
			return;
		}
		
		//Check if the group has already been created
		if (![self groupAlreadyExists]) {
			//Create the group in the database
			PFObject *group = [PFObject objectWithClassName:@"Groups"];
			CLLocationCoordinate2D point = [selectedPlace coordinate];
			PFGeoPoint *loc = [PFGeoPoint geoPointWithLatitude:point.latitude longitude:point.longitude];
			[group setObject:selectedActivity forKey:@"activity"];
			[group setObject:loc forKey:@"location"];
			[group setObject:[NSNumber numberWithInt:0] forKey:@"activityCount"];
			[group setObject:[selectedPlace name] forKey:@"place"];
			[group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
				NSString *errorMessage = @"An unknown error occured while creating this group.";
				
				if (succeeded) {
					//increment the daily creation count, and push group view
					[[FConfig instance] incrementGroupCreationForDate:[NSDate date]];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
					
					[self showGroupViewWithAutoJoin:YES groupId:[group objectId] alreadyExists:NO];
					[self attemptPostGroupToFeedWithID:[group objectId]];
					[[FConfig instance] updateGroup:[group objectId] withActivityCount:[NSNumber numberWithInt:0]];
				}
				else {
					if (error) {
						errorMessage = [error userFriendlyParseErrorDescription:YES]; //Get a more descriptive error if possible
					}
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create Group Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
					
					[self.navigationController popToRootViewControllerAnimated:YES];
				}
			}];
		}
		else {
			//If they are already part of the group, just show the group. If they aren't part of the group show it and autojoin
			if ([self findUserAlreadyJoined]) {
				[self showGroupViewWithAutoJoin:NO groupId:[groupRef objectId] alreadyExists:YES];
			}
			else {
				[self showGroupViewWithAutoJoin:YES groupId:[groupRef objectId] alreadyExists:YES];
			}
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
		}
	}
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
}

#pragma mark - ChooseLocationViewController Delegate

- (void)userPickedLocation:(GooglePlacesObject *)place {
	// Create & move to challenge screen
	[self setSelectedPlace:place];
	[self attemptToCreateGroup];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	// Dequeue or create a cell of the appropriate type.
	ChooseActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ChooseActivityCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	PFObject *o = [activities objectAtIndex:indexPath.row];
	cell.titleLabel.text = (NSString *)[o objectForKey:@"name"];
	[cell.titleLabel setTextAlignment:UITextAlignmentCenter];
	
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kRowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [activities count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	selectedActivity = [[(ChooseActivityCell *)[tableView cellForRowAtIndexPath:indexPath] titleLabel] text];
	
	chooseLocationView = [[ChooseLocationViewController alloc] initWithNibName:@"ChooseLocationViewController" bundle:nil];
	[chooseLocationView setDelegate:self];
	[self.navigationItem setTitle:@"Back"];
	[self.navigationController pushViewController:chooseLocationView animated:YES];
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if (!activities) {
			activities = [[NSMutableArray alloc] init];
			[self getChallengeActivities];
		}
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
	[self.navigationItem setTitle:@""];
	
	if (![[FConfig instance] connected]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to create a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetState) name:@"changedTab" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePop) name:@"changedTab" object:nil];
	
	[self.activityTable setBackgroundColor:[UIColor clearColor]];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_chall.png"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self setActivityTable:nil];
	[super viewDidUnload];
}

@end
