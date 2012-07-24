//
//  GroupPageViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/17/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "GroupPageViewController.h"
#import "LocationMapViewController.h"
#import "NSError+FITParseUtilities.h"
#import "GroupMembersViewController.h"
#import "ProposeGroupActivityViewController.h"

@interface GroupPageViewController ()

@end

@implementation GroupPageViewController

@synthesize activityLabel;
@synthesize proposedTable;
@synthesize place, activity;

#pragma mark - IBAction's

- (IBAction)showGroupMap:(id)sender {
	LocationMapViewController *mapView = [[LocationMapViewController alloc] initWithNibName:@"LocationMapViewController" bundle:nil place:self.place];
	[self.navigationController pushViewController:mapView animated:YES];
}

- (IBAction)joinGroup:(id)sender {
	joinFlag = YES;
	[self attemptJoinGroup];
}

- (IBAction)proposeGroupActivity:(id)sender {
	ProposeGroupActivityViewController *prop = [[ProposeGroupActivityViewController alloc] initWithNibName:@"ProposeGroupActivityViewController" bundle:nil];
	[self.navigationController pushViewController:prop animated:YES];
}

- (IBAction)showChallenges:(id)sender {
	//Implement showing challenges
}

#pragma mark - Helper Methods

- (void)findUserAlreadyJoined {
	alreadyJoined = autoJoin;
	
	//Find if they are already part of the group
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query whereKey:@"user" equalTo:[PFUser currentUser]];
	[query whereKey:@"activity" equalTo:activity];
	[query whereKey:@"place" equalTo:[place name]];
	
	PFObject *result = [query getFirstObject];
	if (result) {
		alreadyJoined = YES;
		group = result; //Can use this later if they are unjoining
	}
}

- (void)attemptUnjoinGroup {
	if (![[FConfig instance] connected]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to unjoin a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
    }
	
	@synchronized(self) {
		[group deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			if (error) {
				NSString *errorMessage = @"Something went wrong, and you weren't unjoined from this group.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unjoin Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
			if (succeeded) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
			}
		}];
	}
}

- (void)attemptJoinGroup {
    
    if (![[FConfig instance] connected]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to join a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
    }
	
	if (alreadyJoined && !autoJoin) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Already Member" message:@"You are already part of this group. Would you like to unjoin?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		[alert show];
		return;
	}
	
    if (joinFlag && autoJoin) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Just Created" message:@"You just created this group, do you really want to unjoin?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		[alert show];
		return; 
	}
	
	@synchronized(self) {
		CLLocationCoordinate2D point = [place coordinate];
		PFGeoPoint *loc = [PFGeoPoint geoPointWithLatitude:point.latitude longitude:point.longitude];
		
		PFUser *user = [PFUser currentUser];
		PFObject *post = [PFObject objectWithClassName:@"GroupMembers"];
		[post setObject:user forKey:@"user"];
		[post setObject:activity forKey:@"activity"];
		[post setObject:[place name] forKey:@"place"];
		[post setObject:loc forKey:@"location"];
		[post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			
			NSString *errorMessage = @"An unknown error uccoured while joining group.";
			if (error) {
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Join Group Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			if (succeeded) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"You are now part of this group." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
	}
}

- (void)attemptGetComments {
	//get comments and activities
}

- (void)viewMemebers {
	GroupMembersViewController *members = [[GroupMembersViewController alloc] initWithNibName:@"GroupMembersViewController" bundle:nil place:self.place activity:self.activity];
	[self.navigationController pushViewController:members animated:YES];
}

#pragma mark - UIAlertView Delegate 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:@"Yes"]) {
		autoJoin = NO;
		[self attemptUnjoinGroup];
	}
}

#pragma mark - UITableViewDelegate 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    }
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;//CHANGE TO DYNAMIC VALUE OF # OF GROUPS USER IN
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 80;
}

#pragma mark - UITableViewDataSource 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)p activity:(NSString *)a challenge:(BOOL)c autoJoin:(BOOL)yn{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.place = p;
        self.activity = a;
		hasChallenge = c;
        autoJoin = yn;
		shouldCancel = NO;
		
		[self findUserAlreadyJoined];
        [self.navigationItem setTitle:[self.place name]];
    }
    return self;
}


- (void)viewDidAppear:(BOOL)animated {
    
    if (autoJoin && !shouldCancel) {
        //Join the user to the group
		joinFlag = NO;
        [self attemptJoinGroup];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	if (autoJoin) {
		shouldCancel = YES;
		[self.navigationController popViewControllerAnimated:NO];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];

	//If there is a challenge we need to make the table view smaller
	if (hasChallenge) {
		CGRect frame = self.proposedTable.frame;
		frame.origin.y += 35.0;
		frame.size.height -= 35.0;
		self.proposedTable.frame = frame;
	}
	
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    self.activityLabel.text = activity;
	
	UIBarButtonItem *members = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"GroupMembersButton.png"] style:UIBarButtonItemStylePlain target:self action:@selector(viewMemebers)];
	self.navigationItem.rightBarButtonItem = members;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attemptGetComments) name:@"addedComment" object:nil];
}

- (void)viewDidUnload {
    [self setActivityLabel:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
