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
#import "NSAttributedString+Attributes.h"
#import "GroupMembersViewController.h"
#import "CreateProposeActivityViewController.h"
#import "ProposedActivityViewController.h"
#import "ProposedActivityCell.h"

#define kDistanceMileFilter		0.15
#define kCellHeight				96.0f

#define kMaxDisplayHours        23
#define kSecondsInMin           60
#define kSecondsInHour          3600
#define kSecondsInDay           86400

@interface GroupPageViewController ()

@end

@implementation GroupPageViewController

@synthesize activityLabel;
@synthesize proposedTable;
@synthesize place, activity;

#pragma mark - IBAction's

- (IBAction)showGroupMap:(id)sender {
	//Show the location of the group on a bigger map
	LocationMapViewController *mapView = [[LocationMapViewController alloc] initWithNibName:@"LocationMapViewController" bundle:nil place:self.place];
	[self.navigationController pushViewController:mapView animated:YES];
}

- (IBAction)joinGroup:(id)sender {
	joinFlag = YES;
	[self attemptJoinGroup];
}

- (IBAction)proposeGroupActivity:(id)sender {
	
	if (alreadyJoined) {
		//Show the create proposed activity view controller
		CreateProposeActivityViewController *prop = [[CreateProposeActivityViewController alloc] initWithNibName:@"ProposeGroupActivityViewController" bundle:nil];
		[prop setGroup:group];
		[self.navigationController pushViewController:prop animated:YES];
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Joined" message:@"You must be part of the group in order to propose an activity" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction)showChallenges:(id)sender {
	//Implement showing challenges
}

#pragma mark - Helper Methods

- (void)getGroupReference {
    CLLocationCoordinate2D point = [self.place coordinate];
	PFGeoPoint *loc = [PFGeoPoint geoPointWithLatitude:point.latitude longitude:point.longitude];
	
	PFQuery *query = [PFQuery queryWithClassName:@"Groups"];
	[query whereKey:@"location" nearGeoPoint:loc withinMiles:kDistanceMileFilter];
	[query whereKey:@"place" equalTo:[self.place name]];
	[query whereKey:@"activity" equalTo:self.activity];
	
	//set as reference to this group
	group = [query getFirstObject];
}

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
		groupMember = result; //Can use this later if they are unjoining
	}
}

- (void)attemptUnjoinGroup {
	if (![[FConfig instance] connected]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to unjoin a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
    }
	
	//Delete the member from the group
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

- (void)attemptGetProposedActivities {
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"ProposedActivity"];
		[query whereKey:@"group" equalTo:group];
		[query addAscendingOrder: @"createdAt"];
		[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
			if (error) {
				NSString *errorMessage = @"An unknown error occured while loading activities.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			
			results = [[NSMutableArray alloc] initWithArray:objects];
			[self.proposedTable reloadData];
		}];
	}
}

- (void)viewMemebers {
	GroupMembersViewController *members = [[GroupMembersViewController alloc] initWithNibName:@"GroupMembersViewController" bundle:nil place:self.place activity:self.activity];
	[self.navigationController pushViewController:members animated:YES];
}

//Get the string for the time interval difference
- (NSString *)getTimeIntervalDifference: (double)diff {
	NSString *time = @"";
    NSNumber *num = [NSNumber numberWithDouble:diff];
    if (([num intValue]/kSecondsInHour) > kMaxDisplayHours) {
        //show days
        int days = ([num intValue]/kSecondsInDay < 1) ? 1 : [num intValue]/kSecondsInDay;
        time = (days == 1) ? [NSString stringWithFormat:@"%i Day Ago", days] : [NSString stringWithFormat:@"%i Days Ago", days];
    }
    else if ([num intValue]/kSecondsInHour >= 1){
        //show hours
        int hours = ([num intValue]/kSecondsInHour < 1) ? 1 : [num intValue]/kSecondsInHour;
        time = (hours == 1) ? [NSString stringWithFormat:@"%i Hour Ago", hours] : [NSString stringWithFormat:@"%i Hours Ago", hours];
    }
    else {
        int mins = [num intValue]/kSecondsInMin;
        time = (mins == 1) ? [NSString stringWithFormat:@"%i Minute Ago", mins] : [NSString stringWithFormat:@"%i Minutes Ago", mins];
    }
    return time;
}

//Calculate what the differece is between when the activity was posted and now
- (NSString *)getTimeSincePost:(PFObject *)propActivity {
	
    NSDate *input = [propActivity createdAt];
    NSDate *temp = [NSDate date];
	
    NSTimeInterval diff = [temp timeIntervalSinceDate:input];
    return [self getTimeIntervalDifference:diff];
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
    ProposedActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ProposedActivityCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	//Seperate the objects within a P.A.
	PFObject *currentPA = [results objectAtIndex:indexPath.row];
	[currentPA fetchIfNeeded];
	
	PFObject *user = [currentPA objectForKey:@"creator"];
	
	[user fetchIfNeeded];
	
	//Get the image
	PFFile *pic = [user objectForKey:@"image"];
	NSData *picData = [pic getData];
	if (picData) {
		[cell.userPicture setImage:[UIImage imageWithData:picData]];
	}
	else {
		[cell.userPicture setImage:[UIImage imageNamed:@"FeedCellProfilePlaceholderPicture.png"]];
	}
	
	//Style picture
	[cell.userPicture.layer setCornerRadius:10.0f];
	[cell.userPicture.layer setMasksToBounds:YES];
	[cell.userPicture.layer setBorderColor:[[UIColor whiteColor] CGColor]];
	[cell.userPicture.layer setBorderWidth:4];
	
	//Set cell text
	NSMutableAttributedString *attStr = [NSMutableAttributedString attributedStringWithString:[currentPA objectForKey:@"activityMessage"]];
	[attStr setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
	[attStr setTextColor:[UIColor whiteColor]];
	cell.activityMessage.attributedText = attStr;
	cell.userName.text = [user objectForKey:@"username"];
	cell.timeAgoLabel.text = [self getTimeSincePost:currentPA];
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [results count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}

#pragma mark - UITableViewDataSource 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	ProposedActivityViewController *pa = [[ProposedActivityViewController alloc] initWithNibName:@"ProposedActivityViewController" bundle:nil proposedActivity:[results objectAtIndex:indexPath.row]];
	[self.navigationController pushViewController:pa animated:YES];
	
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
        [self getGroupReference];
		[self attemptGetProposedActivities];
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
	//Fixes unjoin bug 
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
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attemptGetProposedActivities) name:@"addedPA" object:nil];
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
