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

#define kGroupCreateMax     2

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

#pragma mark - Helper Methods

- (void)attemptCreateGroup {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to create a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
    //TODO: Query to make sure they havent created more than 2 groups today
	//PFQuery *createCountQuery = [[PFQuery alloc] initWithClassName:@"Groups"];
	
    //If both have been selected present the group
	if (hasPickedActivity && hasPickedLocation) {
		
		//Create the group in the database
		PFObject *group = [PFObject objectWithClassName:@"Groups"];
		CLLocationCoordinate2D point = [selectedPlace coordinate];
		PFGeoPoint *loc = [PFGeoPoint geoPointWithLatitude:point.latitude longitude:point.longitude];
		[group setObject:selectedActivity forKey:@"activity"];
		[group setObject:loc forKey:@"location"];
		[group setObject:[selectedPlace name] forKey:@"place"];
		[group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			__block NSString *errorMessage = @"An unknown error occured while creating this group.";
			
			if (succeeded) {
				PFQuery *query = [PFQuery queryWithClassName:@"Groups"];
				[query whereKey:@"activity" equalTo:selectedActivity];
				[query whereKey:@"place" equalTo:[selectedPlace name]];
				[query whereKey:@"location" equalTo:loc];
				NSArray *usersPosts = [query findObjects];
				
				PFObject *retrievedGroup = nil;
				if ([usersPosts count] > 0) {
					retrievedGroup = [usersPosts objectAtIndex:0];
				}
				
				if (retrievedGroup) {
					PFUser *user = [PFUser currentUser];
					PFObject *post = [PFObject objectWithClassName:@"GroupMembers"];
					[post setObject:user forKey:@"user"];
					[post setObject:[retrievedGroup objectId] forKey:@"group"];
					[post setObject:selectedActivity forKey:@"activity"];
					[post setObject:[selectedPlace name] forKey:@"place"];
					[post setObject:loc forKey:@"lcation"];
					[post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
						
						if (succeeded) {
							NSLog(@"Created Group");
						}
						else {
							errorMessage = @"Could not associate you with this group.";
						}
					}];
				}
				else {
					errorMessage = @"Could not get group ID. You were not added to this group.";
				}
			}
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create Group Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
		
		//Show the group that was just saved
		GroupPageViewController *groupView = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:selectedPlace activity:selectedActivity];
		[self.navigationController popViewControllerAnimated:NO];
		[self.navigationController pushViewController:groupView animated:YES];
		
		//Reset GUI and vars 
		[chooseActivityButton setEnabled:YES];
		[chooseLocationButton setEnabled:YES];
		selectedPlace = nil;
		selectedActivity = nil;
		hasPickedActivity = NO;
		hasPickedLocation = NO;
	}
}

#pragma mark - ChooseActivityViewController Delegate

- (void)userPickedActivity:(NSString *)activityName {
	hasPickedActivity = YES;
	[chooseActivityButton setEnabled:NO];
    selectedActivity = activityName;
    [self attemptCreateGroup];
}

#pragma mark - ChoosLocationViewController Delegate

- (void)userPickedLocation:(GooglePlacesObject *)place {
	hasPickedLocation = YES;
	[chooseLocationButton setEnabled:NO];
    selectedPlace = place;
    [self attemptCreateGroup];
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
