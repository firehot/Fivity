//
//  UserProfileViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/14/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "UserProfileViewController.h"
#import "SettingsViewController.h"
#import "NSError+FITParseUtilities.h"
#import "GroupPageViewController.h"
#import "GooglePlacesObject.h"
#import "ProfileCell.h"
#import "NDArtworkPopout.h"
#import "NSString+StateAbreviator.h"

#define kNoAboutMe	@"To Add information here, unlink with Facebook (in settings) and then choose the edit button that will then be located in your profile."

@interface UserProfileViewController ()

@end

@implementation UserProfileViewController

@synthesize mainUser;
@synthesize userProfile;
@synthesize groupsTable;
@synthesize userNameLabel, userAgeLabel, userHometownLabel, userOcupationLabel, userWorkLabel, userBioView;
@synthesize userPicture;
@synthesize facebookProfilePicture;
@synthesize groupsView, aboutMeView;
@synthesize segControl, toolbar;
@synthesize editButton;

#pragma mark - Helper Methods 

- (void) showSettings {
	SettingsViewController *settings = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
	[self.navigationItem setTitle:@"Back"];
	[self.navigationController pushViewController:settings animated:YES];
}

- (void)handlePop {
	[self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)attemptGetUserGroups {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to view groups" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	if (!userProfile) {
		userProfile = [PFUser currentUser];
	}
	
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query addDescendingOrder:@"updatedAt"];
	[query whereKey:@"user" equalTo:userProfile];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		NSString *errorMessage = @"An unknown error occured while loading this users groups.";
		if (error) {
			errorMessage = [error userFriendlyParseErrorDescription:YES];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		} 
		else if ([objects count] > 0) {
			groupResults = [[NSMutableArray alloc] initWithArray:objects];
			[groupsTable reloadData];
		}
	}];
}

- (void)setCorrectData {
		
	if (mainUser && [PFFacebookUtils isLinkedWithUser:userProfile]) {
		[self requestFacebookData];
	}
	else {
		PFFile *pic = [userProfile objectForKey:@"image"];
		if (pic && pic != [NSNull null]) {
			NSData *picData = [pic getData];
			[self.userPicture setImage:[UIImage imageWithData:picData]];
		}
		[self.userNameLabel setText:[userProfile username]];
		[self.userOcupationLabel setText:[[userProfile objectForKey:@"occupation"] stringByAppendingString:@" at"]];
		
		if ([[userProfile objectForKey:@"age"] intValue] == 0) {
			[self.userAgeLabel setText:@""];
		} else {
			[self.userAgeLabel setText:[NSString stringWithFormat:@"Age %i", [[userProfile objectForKey:@"age"] intValue]]];
		}
		
		
		[self.userHometownLabel setText:[userProfile objectForKey:@"hometown"]];
		[self.userWorkLabel setText:[userProfile objectForKey:@"workPlace"]];
		[self.userBioView setText:[userProfile objectForKey:@"bio"]];

	}
	
	//Round the pictures edges and add border
	[self.userPicture.layer setCornerRadius:10.0f];
	[self.userPicture.layer setMasksToBounds:YES];
	[self.userPicture.layer setBorderColor:[[[FConfig instance] getFitivityBlue] CGColor]];
	[self.userPicture.layer setBorderWidth:5.5];
}

- (void)updateGroupCountFromMember:(PFObject *)groupMember {
	@synchronized(self) {
		
		[groupMember fetchIfNeeded];
		
		//Get a reference to the group that is getting deleted
		PFQuery *q = [PFQuery queryWithClassName:@"Groups"];
		[q whereKey:@"activity" equalTo:[groupMember objectForKey:@"activity"]];
		[q whereKey:@"place" equalTo:[groupMember objectForKey:@"place"]];
		
		PFObject *group = [q getFirstObject];
		[group fetchIfNeeded];
		
		//Update group member count
		PFQuery *query = [PFQuery queryWithClassName:@"ActivityEvent"];
		[query whereKey:@"group" equalTo:group];
		[query whereKey:@"postType" equalTo:[NSNumber numberWithInt:0]];
		
		PFObject *updateGroup = [query getFirstObject];
		[updateGroup fetchIfNeeded];
		
		if (updateGroup) {
			NSNumber *num = [updateGroup objectForKey:@"number"];
			if ([num integerValue] > 0) {
				//User is unjoining from the group
				int temp = [num integerValue] - 1;
				
				if (temp == 0) {
					[updateGroup deleteInBackground];
				} else {
					[updateGroup setObject:[NSNumber numberWithInt:temp] forKey:@"number"];
					[updateGroup saveInBackground];
				}
			}
		}
	}
}

- (BOOL)deleteUserFromGroupAtIndex:(NSInteger)index {
	PFObject *deleteObject = [groupResults objectAtIndex:index];
	
	//This ensures that the object doesn't get deleted while we still need the reference 
	[self performSelectorOnMainThread:@selector(updateGroupCountFromMember:) withObject:deleteObject waitUntilDone:YES];
	
	BOOL ret = [deleteObject delete];
	
	//Only delete the group from the GUI if the delete was successful 
	if (ret) {
		[groupResults removeObjectAtIndex:index];
	}
	return ret;
}

- (void)getImageRepresentationOfFBProfilePicture {
	
	//Get image representation of the PF_FBProfilePictureView
	CGFloat scale = 1.0;
	if([[UIScreen mainScreen]respondsToSelector:@selector(scale)]) {
		CGFloat tmp = [[UIScreen mainScreen]scale];
		if (tmp > 1.5) {
			scale = 2.0;
		}
	}
	
	UIGraphicsBeginImageContextWithOptions(facebookProfilePicture.bounds.size, YES, scale);
	[facebookProfilePicture.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *profilePicImg = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
		
	[self.userPicture setImage:profilePicImg];
	
	//Upload to parse for future use
	PFFile *imageFile = [PFFile fileWithData:UIImagePNGRepresentation(profilePicImg)];
	[imageFile saveInBackground];
	
	PFUser *user = [PFUser currentUser];
	[user setObject:imageFile forKey:@"image"];
	
	if (![userAgeLabel.text isEqualToString:@"Age "]) {
		int age = [[userAgeLabel.text stringByReplacingOccurrencesOfString:@"Age " withString:@""] intValue];
		[user setObject:[NSNumber numberWithInt:age] forKey:@"age"];
	}
	if (userOcupationLabel.text != nil) {
		[user setObject:[userOcupationLabel.text stringByReplacingOccurrencesOfString:@" at" withString:@""] forKey:@"occupation"];
	}
	if (userWorkLabel.text != nil) {
		[user setObject:userWorkLabel.text forKey:@"workPlace"];
	}
	if (userBioView.text != nil && ![userBioView.text isEqualToString:kNoAboutMe]) {
		[user setObject:userBioView.text forKey:@"bio"];
	}
	if (userHometownLabel.text != nil) {
		[user setObject:userHometownLabel.text forKey:@"hometown"];
	}

	[user saveInBackground];

}

- (NSString *)getAgeString:(NSString *)birthDay {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"MM/DD/YYYY"];
	NSDate *dob = [df dateFromString:birthDay];
	
	if (dob == nil || birthDay == nil) {
		// Hasn't authorized yet
		if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
			[PFFacebookUtils linkUser:[PFUser currentUser] permissions:[[FConfig instance] getFacebookPermissions] block:^(BOOL succeeded, NSError *error) {
				if (succeeded) {
					[self requestFacebookData];
				}
			}];
		}
		return @"";
	}
	
	int age;
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
	unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
	NSDateComponents *dateComponentsNow = [calendar components:unitFlags fromDate:[NSDate date]];
	NSDateComponents *dateComponentsBirth = [calendar components:unitFlags fromDate:dob];
	
	if (([dateComponentsNow month] < [dateComponentsBirth month]) ||
		(([dateComponentsNow month] == [dateComponentsBirth month]) && ([dateComponentsNow day] < [dateComponentsBirth day]))) {
		age = [dateComponentsNow year] - [dateComponentsBirth year] - 1;
	} else {
		age = [dateComponentsNow year] - [dateComponentsBirth year];
	}
	
	return [NSString stringWithFormat:@"Age %i", age];
}

- (void)requestFacebookData {
	
	if (PF_FBSession.activeSession.isOpen) {
		//Get basic info
		[[PF_FBRequest requestForMe] startWithCompletionHandler:^(PF_FBRequestConnection *connection, NSDictionary<PF_FBGraphUser> *user, NSError *error) {
			if (!error) {				
				NSArray *location = [user.location.name componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
				NSString *state;
				if ([location count] > 1) {
					//Assumes the location is CITY, STATE format 
					state = [location objectAtIndex:1];
					state = [[state stringByReplacingOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:NSMakeRange(0, 2)] abreviateStateString];
					
					self.userHometownLabel.text = [[location objectAtIndex:0] stringByAppendingString:[NSString stringWithFormat:@", %@", state]];
				} else {
					self.userHometownLabel.text = user.location.name;
				}
				
				self.userNameLabel.text = user.name;
				self.userAgeLabel.text = [self getAgeString:user.birthday];
				self.facebookProfilePicture.profileID = user.id;
				
				NSTimeInterval delay = 4.0;
				if ([[FConfig instance] connected]) {
					if ([[FConfig instance] currentNetworkStatus] == ReachableViaWiFi) {
						delay = 2.0;
					} 
					[self performSelector:@selector(getImageRepresentationOfFBProfilePicture) withObject:nil afterDelay:delay];
				}				
			} else {
				//If there is an error load what is in parse
				PFFile *pic = [userProfile objectForKey:@"image"];
				if (pic && pic != [NSNull null]) {
					NSData *picData = [pic getData];
					[self.userPicture setImage:[UIImage imageWithData:picData]];
				}
				[self.userNameLabel setText:[userProfile username]];
				
				if ([[userProfile objectForKey:@"age"] intValue] == 0) {
					[self.userAgeLabel setText:@""];
				} else {
					[self.userAgeLabel setText:[NSString stringWithFormat:@"Age %i", [[userProfile objectForKey:@"age"] intValue]]];
				}
				
				[self.userHometownLabel setText:[userProfile objectForKey:@"hometown"]];
			}
		}];
		
		// Get extended info
		[[PF_FBRequest requestForGraphPath:@"me/?fields=bio,education,work"] startWithCompletionHandler:^(PF_FBRequestConnection *connection, NSDictionary<PF_FBGraphObject> *result, NSError *error){
			
			if (!error) {
				if (result == nil) {
					return;
				}
				
				userBioView.text = [result objectForKey:@"bio"];
				
				if ([userBioView.text isEqualToString:@""]) {
					userBioView.text = kNoAboutMe;
				}
				
				//Array of Dictionaries
				NSArray *education = [result objectForKey:@"education"];
				//Array of Dictionaries
				NSArray *work = [result objectForKey:@"work"];
				
				if (work == nil || [work count] == 0) {
					if (education != nil && [education count] > 0) {
						//Schools are listed starting with oldest
						NSDictionary *ed = (NSDictionary *)[education objectAtIndex:[education count]-1];
						NSDictionary *school = [ed objectForKey:@"school"];
						
						userOcupationLabel.text = @"Student";
						userWorkLabel.text = [school objectForKey:@"name"];
					}
				} else {
					NSDictionary *w = (NSDictionary *)[work objectAtIndex:0];
					NSDictionary *employer = [w objectForKey:@"employer"];
					NSDictionary *job = [w objectForKey:@"position"];
					
					NSString *j = [job objectForKey:@"name"];
					NSString *work = [employer objectForKey:@"name"];
					if (j == nil || [j isEqualToString:@" "]) {
						[self.userOcupationLabel setText:[userProfile objectForKey:@"occupation"]];
						[self.userWorkLabel setText:[[userProfile objectForKey:@"workPlace"] stringByAppendingString:@" at"]];
					} else {
						userOcupationLabel.text = [j stringByAppendingString:@" at"];
						userWorkLabel.text = work;
					}
				}
			} else {
				[self.userOcupationLabel setText:[userProfile objectForKey:@"occupation"]];
				[self.userBioView setText:[userProfile objectForKey:@"bio"]];
				[self.userWorkLabel setText:[[userProfile objectForKey:@"workPlace"] stringByAppendingString:@" at"]];
			}
		}];
	}
}

- (void)reloadAfterLogin {
	userProfile = [PFUser currentUser];
	[self loadCachedData];
	[self attemptGetUserGroups];
}

- (void)loadCachedData {
	// Load Cache to display immediately
	PFFile *pic = [userProfile objectForKey:@"image"];
	if (pic && pic != [NSNull null]) {
		NSData *picData = [pic getData];
		[self.userPicture setImage:[UIImage imageWithData:picData]];
	}
	
	userNameLabel.text = [userProfile username];
	userOcupationLabel.text = [[userProfile objectForKey:@"occupation"] stringByAppendingString:@" at"];
	userAgeLabel.text = [NSString stringWithFormat:@"Age %i", [[userProfile objectForKey:@"age"] intValue]];
	userHometownLabel.text = [userProfile objectForKey:@"hometown"];
	userBioView.text = [userProfile objectForKey:@"bio"];
	userWorkLabel.text = [userProfile objectForKey:@"workPlace"];
}

#pragma mark - EditProfileViewController Delegate

-(void)userDidUpdateProfile {
	[self loadCachedData];
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
}

#pragma mark - UITableViewDelegate 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
	ProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ProfileCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	//To prevent many api calls to parse, cells will only be checked for new activity upon loading 
	PFObject *currentGroup = [groupResults objectAtIndex:indexPath.row];
	BOOL show = [(NSNumber *)[updatedGroups objectForKey:[currentGroup objectId]] boolValue];
	
	if (mainUser && (![updatedGroups objectForKey:[currentGroup objectId]] || show)) {
		PFObject *group = [PFObject objectWithoutDataWithClassName:@"Groups" objectId:[currentGroup objectForKey:@"group"]];
		[group fetchIfNeeded];
		
		// Check if there is any new activity only if you are looking at your profile
		if (show || [[FConfig instance] shouldShowNewActivityForGroup:[group objectId] newActivityCount:[group objectForKey:@"activityCount"]]) {
			[cell.activityIndicator setImage:[UIImage imageNamed:@"NewActivityNotification.png"]];
			[updatedGroups setObject:[NSNumber numberWithBool:YES] forKey:[currentGroup objectId]];
		}
		else {
			[updatedGroups setObject:[NSNumber numberWithBool:NO] forKey:[currentGroup objectId]];
		}
	}
		
	cell.locationLabel.text = [currentGroup objectForKey:@"place"];
	cell.activityLabel.text = [currentGroup objectForKey:@"activity"];
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [groupResults count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 80;
}

/**
 *	Since this header is so basic no need for a .xib file
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section == 0) {
		UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kHeaderHeight)];
		[header setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_activity_header.png"]]];
		
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
		[title setText:@"My Groups"];
		[title setTextAlignment:UITextAlignmentCenter];
		[title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
		[title setBackgroundColor:[UIColor clearColor]];
		[title setTextColor:[UIColor whiteColor]];
		[header addSubview:title];
		return header;
	}
	return nil;
}

#pragma mark - UITableViewDataSource 

- (void)loadGroupView:(PFObject *)group {
	PFGeoPoint *point = [group objectForKey:@"location"];
	
	BOOL challenge = [[FConfig instance] groupHasChallenges:[group objectForKey:@"activity"]];
	
	GooglePlacesObject *place = [[GooglePlacesObject alloc] initWithName:[group objectForKey:@"place"] latitude:point.latitude longitude:point.longitude placeIcon:nil rating:nil vicinity:nil type:nil reference:nil url:nil addressComponents:nil formattedAddress:nil formattedPhoneNumber:nil website:nil internationalPhone:nil searchTerms:nil distanceInFeet:nil distanceInMiles:nil];
	GroupPageViewController *groupPage = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:place activity:[group objectForKey:@"activity"] challenge:challenge autoJoin:NO];
	
	
	PFObject *g = [PFObject objectWithoutDataWithClassName:@"Groups" objectId:[group objectForKey:@"group"]];
	[g fetchIfNeeded];
	
	//Update the local count
	[[FConfig instance] updateGroup:[g objectId] withActivityCount:[g objectForKey:@"activityCount"]];
	
	[self.navigationItem setTitle:@"Back"];
	[self.navigationController pushViewController:groupPage animated:YES];
	[updatedGroups setObject:[NSNumber numberWithBool:NO] forKey:[group objectId]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeText;
	HUD.labelText = @"Loading...";
	
	//Get the group and present it
	PFObject *currentGroup = [groupResults objectAtIndex:indexPath.row];
	[currentGroup fetchIfNeeded];
	
	[HUD showWhileExecuting:@selector(loadGroupView:) onTarget:self withObject:currentGroup animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
	//Check to make sure that the table can be edited by the current user
	if (!mainUser) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Permissions" message:@"You don't have permissions to delete this group." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
        return;
	}
	else if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You need to be connected to edit your groups." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
        return;
	}
	
	//Delete the current group from the GUI and remove the entry in the database
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		if ([self deleteUserFromGroupAtIndex:indexPath.row]) {
			[tableView beginUpdates];
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[tableView endUpdates];
		}
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Error" message:@"There was an error while deleting this group." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}  
}

#pragma mark - IBAction's 

- (IBAction)editInformation:(id)sender {
	EditProfileViewController *edit = [[EditProfileViewController alloc] initWithNibName:@"EditProfileViewController" bundle:nil];
	[edit setDelegate:self];
	[self presentModalViewController:edit animated:YES];
}

- (IBAction)enlargePicture:(id)sender {
	NDArtworkPopout *pop = [[NDArtworkPopout alloc] initWithImage:userPicture.image];
	[pop show];
}

- (IBAction)updateViews:(id)sender {
	UISegmentedControl *seg = (UISegmentedControl *)sender;
	if ([seg selectedSegmentIndex] == 0) {
		[groupsView setHidden:NO];
		[aboutMeView setHidden:YES];
	} else {
		[groupsView setHidden:YES];
		[aboutMeView setHidden:NO];
	} 
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil initWithUser:(PFUser *)user {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.userProfile = user;
		
		//Make sure that the user exists first (for first launch)
		if ([PFUser currentUser]) {
			[self performSelectorInBackground:@selector(attemptGetUserGroups) withObject:nil];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAfterLogin) name:@"loggedIn" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attemptGetUserGroups) name:@"changedGroup" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestFacebookData) name:@"facebookLogin" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidLoad) name:@"changedInformation" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePop) name:@"changedTab" object:nil];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[groupsTable reloadData];
    
	if (mainUser) {
		// Can't edit information that is pulled from FB
		if (![PFFacebookUtils isLinkedWithUser:userProfile]) {
			[editButton setHidden:NO];
		} else {
			if ([[[PFUser currentUser] objectForKey:@"bio"] isEqualToString:@""]) {
				userBioView.text = @"";
			}
			[editButton setHidden:YES];
		}
	} else {
		[editButton setHidden:YES];
	}
	
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
	[self.navigationItem setTitle:@""];
}

- (void)viewDidLoad {
    [super viewDidLoad];
			
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
	[self.segControl setTintColor:[[FConfig instance] getFitivityBlue]];
	[self.toolbar setTintColor:[[FConfig instance] getFitivityBlue]];
	
	[self.displayView addSubview:groupsView];
	[self.displayView addSubview:aboutMeView];
	[aboutMeView setHidden:YES];
	
	[aboutMeView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	
	if (!userProfile) {
		userProfile = [PFUser currentUser];
	}

	[self loadCachedData];
	[self setCorrectData];
	
	//If the results didn't load at init, try to reload them.
	if (!groupResults) {
		[self performSelectorInBackground:@selector(attemptGetUserGroups) withObject:nil];
	}
	
	//Only display settings button if on the main users profile
	if (mainUser) {
        
        UIImage *settingsImage = [UIImage imageNamed:@"b_settings.png"];
        UIImage *settingsImageDown = [UIImage imageNamed:@"b_settings_down.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:settingsImage forState:UIControlStateNormal];
        [button setImage:settingsImageDown forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(0.0, 0.0, 58.0, 40.0);
		
        UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithCustomView:button];
		self.navigationItem.rightBarButtonItem = settings;

		updatedGroups = [[NSMutableDictionary alloc] init];
	}
	
    self.groupsTable.separatorColor = [UIColor colorWithRed:178.0/255.0f green:216.0/255.0f blue:254.0/255.0f alpha:1];
	self.groupsTable.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
}

- (void)viewDidUnload {
	[self setUserPicture:nil];
	[self setUserNameLabel:nil];
	[self setGroupsTable:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self setFacebookProfilePicture:nil];
	[self setDisplayView:nil];
	[self setUserAgeLabel:nil];
	[self setUserHometownLabel:nil];
	[self setUserOcupationLabel:nil];
	[self setToolbar:nil];
	[self setSegControl:nil];
	[self setUserBioView:nil];
    [self setUserWorkLabel:nil];
	[self setEditButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
