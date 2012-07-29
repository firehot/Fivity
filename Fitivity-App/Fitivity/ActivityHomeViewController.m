//
//  ActivityHomeViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/14/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ActivityHomeViewController.h"
#import "NSError+FITParseUtilities.h"
#import "GroupPageViewController.h"

#define kDistanceMileFilter		0.15

@interface ActivityHomeViewController ()

@end

@implementation ActivityHomeViewController

@synthesize chooseActivityButton;
@synthesize chooseLocationButton;

#pragma mark - IBAction's 

- (IBAction)chooseActivity:(id)sender {
	ChooseActivityViewController *activity = [[ChooseActivityViewController alloc] initWithNibName:@"ChooseActivityViewController" bundle:nil];
	[activity setDelegate: self];
	[self.navigationController pushViewController:activity animated:YES];
}

- (IBAction)chooseLocation:(id)sender {
	ChooseLocationViewController *location = [[ChooseLocationViewController alloc] initWithNibName:@"ChooseLocationViewController" bundle:nil];
	[location setDelegate: self];
	[self.navigationController pushViewController:location animated:YES];
}

- (void)showGroupViewWithAutoJoin:(BOOL)autojoin {
	
	/*
	 *	Create the group with the selected information, pop the old view from the stack (unanimated) and present the new one so there is no odd transition.
	 *	Once the views have finished presenting, reset the state of the picker view. 
	 */
	GroupPageViewController *groupView = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:selectedPlace activity:selectedActivity challenge:NO autoJoin:autojoin];
	[self.navigationController popViewControllerAnimated:NO];
	[self.navigationController pushViewController:groupView animated:YES];
	
	[self resetState];
}

#pragma mark - Helper Methods

- (void)resetState {
    //Reset GUI and vars 
    [chooseActivityButton setEnabled:YES];
    [chooseLocationButton setEnabled:YES];
    selectedPlace = nil;
    selectedActivity = nil;
    hasPickedActivity = NO;
    hasPickedLocation = NO;
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
		[event setObject:@"NEW" forKey:@"status"];	//Just created groups are new
		[event setObject:@"NORMAL" forKey:@"type"];	//Groups have type of NORMAL
		
		//If it doesn't save the first time, don't worry about it and try again in the future.
		if (![event save]) {
			[event saveEventually];
		}
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
		ret = YES;
	}
	
	return ret;
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

- (void)attemptCreateGroup {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to create a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	@synchronized(self) {
		//If both have been selected present the group
		if (hasPickedActivity && hasPickedLocation) {
			
			// MAKE SURE THIS IS UNCOMMENTED OUT FOR FINAL TESTING!!!
			if (![[FConfig instance] canCreateGroup]) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Limit Exceeded" message:@"You have already created the max number (2) of groups today." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
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
				[group setObject:[selectedPlace name] forKey:@"place"];
				[group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
					NSString *errorMessage = @"An unknown error occured while creating this group.";
					
					if (succeeded) {
						//increment the daily creation count, and push group view
						[[FConfig instance] incrementGroupCreationForDate:[NSDate date]];
						[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
						
						[self showGroupViewWithAutoJoin:YES];
						[self attemptPostGroupToFeedWithID:[group objectId]];
					}
					else {
						if (error) {
							errorMessage = [error userFriendlyParseErrorDescription:YES]; //Get a more descriptive error if possible
						}
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create Group Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
						[alert show];
					}
				}];
			}
			else {
				//If they are already part of the group, just show the group. If they aren't part of the group show it and autojoin
				if ([self findUserAlreadyJoined]) {
					[self showGroupViewWithAutoJoin:NO];
				}
				else {
					[self showGroupViewWithAutoJoin:YES];
				}
				
				[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
			}
		}	
	}
}

#pragma mark - ChooseActivityViewController Delegate

- (void)userPickedActivity:(NSString *)activityName {
	hasPickedActivity = YES;
	[chooseActivityButton setEnabled:NO];
    selectedActivity = activityName;
    [self attemptCreateGroup];
}

- (BOOL)shouldPopViewController:(ChooseActivityViewController *)view {
	return !(hasPickedActivity && hasPickedLocation);
}

#pragma mark - ChoosLocationViewController Delegate

- (void)userPickedLocation:(GooglePlacesObject *)place {
	hasPickedLocation = YES;
	[chooseLocationButton setEnabled:NO];
    selectedPlace = place;
    [self attemptCreateGroup];
}

- (BOOL)shouldPopViewControllerFromNavController:(ChooseLocationViewController *)view {
	return !(hasPickedActivity && hasPickedLocation);
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	hasPickedActivity = NO; //Nothing picked when loaded
	hasPickedLocation = NO;
}

- (void)viewDidUnload {
	[self setChooseActivityButton:nil];
	[self setChooseLocationButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
