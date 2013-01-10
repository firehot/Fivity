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
#import "AboutGroupViewController.h"
#import "ProposedActivityViewController.h"
#import "ChallengesViewController.h"
#import "UserProfileViewController.h"
#import "SocialSharer.h"

#define kDistanceMileFilter		0.15
#define kCellHeight				96.0f
#define kHeaderHeight			20.0f

#define kMaxDisplayHours        23
#define kSecondsInMin           60
#define kSecondsInHour          3600
#define kSecondsInDay           86400

#define kPACellMoreIcon			75

@interface GroupPageViewController ()

@end

@implementation GroupPageViewController

@synthesize activityLabel;
@synthesize proposedTable;
@synthesize place, activity;

#pragma mark - IBAction's

- (IBAction)showGroupMap:(id)sender {
	autoJoin = NO;
	//Show the location of the group on a bigger map
	LocationMapViewController *mapView = [[LocationMapViewController alloc] initWithNibName:@"LocationMapViewController" bundle:nil place:self.place];
	[self.navigationController pushViewController:mapView animated:YES];
}

- (IBAction)joinGroup:(id)sender {
	joinFlag = YES;
	[self attemptJoinGroup];
}

- (IBAction)proposeGroupActivity:(id)sender {
	autoJoin = NO;
	if (alreadyJoined) {
		
		if (![[FConfig instance] canCreatePA]) {
			//Show the create proposed activity view controller
			CreateProposeActivityViewController *prop = [[CreateProposeActivityViewController alloc] initWithNibName:@"CreateProposeActivityViewController" bundle:nil];
			[prop setDelegate:self];
			[prop setGroup:group];
			[self.navigationController pushViewController:prop animated:YES];
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Limit Reached" message:@"You can only propose an activity twice a day." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Joined" message:@"You must be part of the group in order to propose an activity" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction)showChallenges:(id)sender {
	autoJoin = NO;
	if (!alreadyJoined) {
		joinedFromChallenge = YES;
		[self attemptJoinGroup];
	}
	ChallengesViewController *challenge = [[ChallengesViewController alloc] initWithNibName:@"ChallengesViewController" bundle:nil groupType:self.activity groupLocation:[place name]];
	[self.navigationController pushViewController:challenge animated:YES];
}

- (IBAction)viewAboutGroup:(id)sender {
	autoJoin = NO;
	
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeText;
	HUD.labelText = @"Loading...";
	
	[HUD show:YES];
	[HUD hide:YES afterDelay:1.33];
	
	AboutGroupViewController *about = [[AboutGroupViewController alloc] initWithNibName:@"AboutGroupViewController"
																				bundle:nil
																				group:group
																				joined:alreadyJoined
																				activity:self.activity
																				place:self.place];
	[self.navigationController pushViewController:about animated:YES];
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

- (void)updateJoiningGUI {
	//When the user is part of the group display the unjoin button otherwise display the join button
	if (alreadyJoined) {
		UIImage *memberImage = [UIImage imageNamed:@"leave.png"];
		UIImage *memberImageDown = [UIImage imageNamed:@"leave_down.png"];
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setImage:memberImage forState:UIControlStateNormal];
		[button setImage:memberImageDown forState:UIControlStateHighlighted];
		[button addTarget:self action:@selector(joinGroup:) forControlEvents:UIControlEventTouchUpInside];
		button.frame = CGRectMake(0.0, 0.0, 62.0, 28.0);
		
		UIBarButtonItem *joinButton = [[UIBarButtonItem alloc] initWithCustomView:button];
		self.navigationItem.rightBarButtonItem = joinButton;
	}
	else {
		UIImage *memberImage = [UIImage imageNamed:@"b_join.png"];
		UIImage *memberImageDown = [UIImage imageNamed:@"b_join_down.png"];
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setImage:memberImage forState:UIControlStateNormal];
		[button setImage:memberImageDown forState:UIControlStateHighlighted];
		[button addTarget:self action:@selector(joinGroup:) forControlEvents:UIControlEventTouchUpInside];
		button.frame = CGRectMake(0.0, 0.0, 58.0, 40.0);
		
		UIBarButtonItem *joinButton = [[UIBarButtonItem alloc] initWithCustomView:button];
		self.navigationItem.rightBarButtonItem = joinButton;
	}
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

- (void)attemptUpdateGroupInfo:(BOOL)userJoining {
	@synchronized(self) {
		//Update group member count logic
		PFQuery *query = [PFQuery queryWithClassName:@"ActivityEvent"];
		[query whereKey:@"group" equalTo:group];
		[query whereKey:@"postType" equalTo:[NSNumber numberWithInt:0]];
		
		PFObject *updateGroup = [query getFirstObject];
		
		if (updateGroup) {
			NSNumber *num = [updateGroup objectForKey:@"number"];
			if (userJoining && (!autoJoin || !alreadyJoined)) {
				//User is joining the group
				int temp = [num integerValue] + 1;
				[updateGroup setObject:[NSNumber numberWithInt:temp] forKey:@"number"];
			}
			else if (!userJoining && [num integerValue] > 0) {
				//User is unjoining from the group
				int temp = [num integerValue] - 1;
				[updateGroup setObject:[NSNumber numberWithInt:temp] forKey:@"number"];
			}
			else {
				//User has just created and autojoined the group
				return;
			}
			[updateGroup saveInBackground];
		}
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
		[groupMember deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			if (error) {
				NSString *errorMessage = @"Something went wrong, and you weren't unjoined from this group.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unjoin Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
			if (succeeded) {
				//update vars & gui then notify other classes of the user unjoining
				alreadyJoined = NO;
				[self attemptUpdateGroupInfo:NO];
				[self updateJoiningGUI];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
				
				//Unsubscribe to notifications
				if ([[FConfig instance] doesHavePushNotifications]) {
					NSString *channel = [NSString stringWithFormat:@"Fitivity%@", [group objectId]];
					[PFPush unsubscribeFromChannelInBackground:channel];
				}
			}
		}];
	}
}

- (void)attemptJoinGroup {
    
	//User isnt connected
    if (![[FConfig instance] connected]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to join a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
    }
	
	//User trying to unjoin from group
	if (alreadyJoined && !autoJoin) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Leave Group?" message:@"Are you sure you would like to unjoin this group?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
		[alert show];
		return;
	}
	
	//User just created this group, make sure they really want to unjoin it
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
		
		if (group) {
			[group fetchIfNeeded];
			[post setObject:[group objectId] forKey:@"group"];
		}
		
		[post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
			
			NSString *errorMessage = @"An unknown error uccoured while joining group.";
			if (error) {
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Join Group Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			if (succeeded) {
				//update vars and gui
				alreadyJoined = YES;
				[self attemptUpdateGroupInfo:YES];
				[self updateJoiningGUI];
				[self shareNewGroup];
				
				//Subscribe to notifications
				if ([[FConfig instance] doesHavePushNotifications]) {
					NSString *channel = [NSString stringWithFormat:@"Fitivity%@", [group objectId]];
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
				
				if (joinedFromChallenge) {
					HUD.tag = 44;
				}
				
				[HUD show:YES];
				[HUD hide:YES afterDelay:3.00];
			}
		}];
	}
}

- (void)attemptGetProposedActivities {
	@synchronized(self) {
		//Get all PA for this group
		PFQuery *query = [PFQuery queryWithClassName:@"ProposedActivity"];
		[query whereKey:@"group" equalTo:group];
		[query orderByDescending: @"createdAt"];
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

- (BOOL)proposedActivityHasComments:(PFObject *)pa {
	
	[pa fetchIfNeeded];
	BOOL ret = NO;
	
	@synchronized(self) {
		
		//Check if the proposed activity has any comments
		PFQuery *q = [PFQuery queryWithClassName:@"Comments"];
		[q whereKey:@"parent" equalTo:pa];
		
		//We only care if there is more than one comment
		PFObject *object = [q getFirstObject];
		if (object) {
			ret = YES;
		}
	}
	
	return ret;
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

- (void)shareNewGroup {
	if ([[FConfig instance] shouldShareGroupStart]) {
		if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
			
			NSString *message = [NSString stringWithFormat:@"I just joined the %@ group at %@ using fitivity!", activity, [place name]];
			
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
			[[SocialSharer sharer] shareMessageWithTwitter:[NSString stringWithFormat:@"I just joined the %@ group at %@ using fitivity!", activity, [place name]] image:nil link:[NSURL URLWithString:[[FConfig instance] getItunesAppLink]]];
		}
	}

}

- (void)shareNewActivity {
	if ([[FConfig instance] shouldSharePAStart]) {
		if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
			
			NSString *message = [NSString stringWithFormat:@"I just proposed an activity at %@ using fitivity!", [place name]];
			
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
			[[SocialSharer sharer] shareMessageWithTwitter:[NSString stringWithFormat:@"I just proposed an activity at %@ using fitivity!", [place name]] image:nil link:[NSURL URLWithString:[[FConfig instance] getItunesAppLink]]];
		}
	}
}

- (void)handleNewProposedActivity {
	[self performSelectorInBackground:@selector(attemptGetProposedActivities) withObject:nil];
	[self shareNewActivity];
}

#pragma mark - CreateProposedActivityViewController Delegate 

//This is a hacky way around currupting the navigation stack. should probably fix eventually.
- (void)showNewPA:(PFObject *)newActivity {
	if (newActivity) {
		ProposedActivityViewController *proposedActivity = [[ProposedActivityViewController alloc] initWithNibName:@"ProposedActivityViewController" bundle:nil proposedActivity:newActivity];
		[self.navigationController pushViewController:proposedActivity animated:YES];
	}
}

- (void)didCreateProposedActivity:(PFObject *)npa {
	if (group) {
		[[FConfig instance] updateGroup:[group objectId] withActivityCount:[group objectForKey:@"activityCount"]];
	}
	[self performSelector:@selector(showNewPA:) withObject:npa afterDelay:0.45];
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	
	if (hud.tag == 44) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Auto-Joined" message:@"Since you were not part of this group, we automatically joined you to it." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		joinedFromChallenge = NO;
	}
	
	[hud removeFromSuperview];
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:@"Yes"]) {
		autoJoin = NO;
		[self attemptUnjoinGroup];
	}
}

#pragma mark - ProposedActivityCell Delegate 

- (void)userWantsProfileAtRow:(NSInteger)row {
	PFObject *comment = [results objectAtIndex:row];
	PFUser *user = [comment objectForKey:@"creator"];
	
	UserProfileViewController *profile = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil initWithUser:user];
	[self.navigationController pushViewController:profile animated:YES];
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
		[cell.userPicture setImage:[UIImage imageNamed:@"b_avatar_settings.png"]];
	}
	
	//Style picture
	[cell.userPicture.layer setCornerRadius:10.0f];
	[cell.userPicture.layer setMasksToBounds:YES];
	[cell.userPicture.layer setBorderColor:[[[FConfig instance] getFitivityBlue] CGColor]];
	[cell.userPicture.layer setBorderWidth:4];
	
	//Set cell text
	NSMutableAttributedString *attStr = [NSMutableAttributedString attributedStringWithString:[currentPA objectForKey:@"activityMessage"]];
	[attStr setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
	[attStr setTextColor:[UIColor blackColor]];
	cell.activityMessage.text = [currentPA objectForKey:@"activityMessage"];
	
	if (cell.activityMessage.text.length < kPACellMoreIcon) {
		cell.moreIcon.hidden = YES;
	}
	
	cell.userName.text = [user objectForKey:@"username"];
	cell.timeAgoLabel.text = [self getTimeSincePost:currentPA];
	
	if ([self proposedActivityHasComments:currentPA]) {
		[cell.notificationImage setImage:[UIImage imageNamed:@"NewActivityNotification.png"]];
	}
	
	[cell setTag:indexPath.row];
	[cell setDelegate:self];
	
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
    [label setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_heading_header.png"]]];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
    [label setText:@"Activities"];
	
    [header addSubview:label];
    return header;
}

#pragma mark - UITableViewDataSource 

- (void)loadPAViewWithParent:(PFObject *)parent {
	ProposedActivityViewController *pa = [[ProposedActivityViewController alloc] initWithNibName:@"ProposedActivityViewController" bundle:nil proposedActivity:parent];
	[self.navigationController pushViewController:pa animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeText;
	HUD.labelText = @"Loading...";
	[HUD show:YES];
    
    PFObject *o = [results objectAtIndex:indexPath.row];
    [o fetchIfNeeded];
    
    [self loadPAViewWithParent:o];
    [HUD hide:YES afterDelay:0.8];
    
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
		[self performSelectorInBackground:@selector(attemptGetProposedActivities) withObject:nil];
        [self.navigationItem setTitle:activity];
    }
    return self;
}


- (void)viewDidAppear:(BOOL)animated {
    
    if (autoJoin && !shouldCancel) {
        //Join the user to the group
		joinFlag = NO;
        [self performSelectorInBackground:@selector(attemptJoinGroup) withObject:nil];
    }
	
	[self performSelectorInBackground:@selector(updateJoiningGUI) withObject:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	//Fixes unjoin bug 
	if (autoJoin) {
		shouldCancel = YES;
		[self.navigationController popViewControllerAnimated:NO];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];

	//If there is a challenge we need to make the table view smaller
	if (hasChallenge) {
		CGRect frame = self.proposedTable.frame;
		frame.origin.y += 37.0;
		frame.size.height -= 37.0;
		self.proposedTable.frame = frame;
	}
	
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
	self.proposedTable.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
    self.activityLabel.text = [place name];

	if (autoJoin) {
		int64_t delayInSeconds = 2.2;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Complete Group Information" message:@"To get maximum participation at this group - fill in the description, add photos, rate, or review in the group information section" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		});
	}
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNewProposedActivity) name:@"addedPA" object:nil];
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
