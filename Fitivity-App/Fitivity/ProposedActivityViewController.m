//
//  ProposedActivityViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 7/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ProposedActivityViewController.h"
#import "NSError+FITParseUtilities.h"
#import "NSAttributedString+Attributes.h"
#import "UserProfileViewController.h"
#import "GroupPageViewController.h"
#import "AboutGroupViewController.h"
#import "GooglePlacesObject.h"

#import "SocialSharer.h"
#import "AppDelegate.h"
#import "FTabBarViewController.h"

#define kCellHeight						70.0f
#define kHeaderHeight					20.0f
#define kFooterHeight					45.0f

#define kFirstCellMove					20
#define kSecondCellMove					90
#define kThirdCellMove					160
#define kTextFieldAnimationDuration    0.3f
#define kMaxCharCount					350
#define kHeaderMoreLimit				75
#define kCellMoreLimit					125

@interface ProposedActivityViewController ()

@end

@implementation ProposedActivityViewController

@synthesize activityHeader;
@synthesize creatorPicture;
@synthesize creatorName;
@synthesize message;
@synthesize activityCreateTime;
@synthesize placeLabel;
@synthesize inButton;
@synthesize activityFooter;
@synthesize activityComment;
@synthesize commentsTable;
@synthesize parent;
@synthesize moreIcon;

#pragma mark - Actions

- (IBAction)shareApp:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share Activity" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"SMS", @"Email", nil];
	
	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
}

- (IBAction) textFieldDidUpdate:(id)sender {
	
	//Get the text field, then determine what the current count is.
	UITextField * textField = (UITextField *)sender;
	int charsLeft = kMaxCharCount - [textField.text length];
	
	if (charsLeft < 0) {
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"No more characters"
														 message:[NSString stringWithFormat:@"You have reached the character limit of %d.",kMaxCharCount]
														delegate:nil
											   cancelButtonTitle:@"Ok"
											   otherButtonTitles:nil];
		[alert show];
		
		//Remove the text that went over
		[textField setText:[[textField text] substringToIndex:kMaxCharCount]];
		return;
	}
 }

- (IBAction)showHeaderMessage:(id)sender {
	
	NSString *message = [parent objectForKey:@"activityMessage"];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Activity" message:message delegate:self cancelButtonTitle:@"Done" otherButtonTitles: nil];
	[alert show];
}

- (IBAction)showPostCreator:(id)sender {
	PFUser *creator = [parent objectForKey:@"creator"];
	UserProfileViewController *user = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil initWithUser:creator];
	
	[self.navigationController pushViewController:user animated:YES];
}

- (IBAction)postImIn:(id)sender {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to post a comment" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	else if (posting) {
		return;
	}
	
	if (!autoJoined && ![self userIsPartOfParentGroup]) {
		[self autoJoinUser:[PFUser currentUser]];
	}
	
	@synchronized(self) {
		PFObject *comment = [PFObject objectWithClassName:@"Comments"];
		[comment setObject:@"I'm In!" forKey:@"message"];
		[comment setObject:[PFUser currentUser] forKey:@"user"];
		//Make sure that we have a good reference to the ProposedActivity
		if (parent) {
			[comment setObject:parent forKey:@"parent"];
		}
		else {
			[comment setObject:[NSNull null] forKey:@"parent"];
		}
		
		MBProgressHUD *HUD1 = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
		[self.navigationController.view addSubview:HUD1];
		
		HUD1.delegate = self;
		HUD1.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		HUD1.mode = MBProgressHUDModeText;
		HUD1.labelText = @"Posting...";
		
		[HUD1 show:YES];
		[HUD1 hide:YES afterDelay:.75];
		
		//Try to save the comment, if can't show error message
		[comment saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				[self postToFeedWithID:[comment objectId]];
				[self.activityComment setText:@""];
				[self getProposedActivityHistory];
				
				MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
				[self.navigationController.view addSubview:HUD];
				
				HUD.delegate = self;
				HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
				HUD.mode = MBProgressHUDModeCustomView;
				HUD.labelText = @"Posted";
				HUD.tag = 2;
				
				[HUD show:YES];
				[HUD hide:YES afterDelay:1.75];
				
				posting = NO;
			}
			else if (error) {
				NSString *errorMessage = @"An unknown error occurred while posting event.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Posting Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
	}

}

- (IBAction)showGroup:(id)sender {
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeText;
	HUD.labelText = @"Loading...";
	HUD.tag = 4;
	
	[HUD show:YES];
	[HUD hide:YES afterDelay:1.25];
	
	PFObject *group = [parent objectForKey:@"group"];
	[group fetchIfNeeded];
	
	BOOL challenge = [[FConfig instance] groupHasChallenges:[group objectForKey:@"activity"]];
	PFGeoPoint *point = [group objectForKey:@"location"];
	GooglePlacesObject *place = [[GooglePlacesObject alloc] initWithName:[group objectForKey:@"place"]
																latitude:point.latitude
															   longitude:point.longitude
															   placeIcon:nil
																  rating:nil
																vicinity:nil
																	type:nil
															   reference:nil
																	 url:nil
													   addressComponents:nil
														formattedAddress:nil
													formattedPhoneNumber:nil
																 website:nil
													  internationalPhone:nil
															 searchTerms:nil
														  distanceInFeet:nil
														 distanceInMiles:nil];
	
	GroupPageViewController *g = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController"
																		   bundle:nil place:place
																		 activity:[group objectForKey:@"activity"]
																		challenge:challenge
																		 autoJoin:NO];
	[self.navigationController pushViewController:g animated:YES];
}

/*
 *	No longer used for this view... Leaving in case someone changes their mind.
 */
- (IBAction)showAboutGroup:(id)sender {
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeText;
	HUD.labelText = @"Loading...";
	HUD.tag = 3;
	
	[HUD show:YES];
	[HUD hide:YES afterDelay:1.25];
	
	PFObject *group = [parent objectForKey:@"group"];
	[group fetchIfNeeded];
	
	PFGeoPoint *point = [group objectForKey:@"location"];
	GooglePlacesObject *place = [[GooglePlacesObject alloc] initWithName:[group objectForKey:@"place"]
																latitude:point.latitude
															   longitude:point.longitude
															   placeIcon:nil
																  rating:nil
																vicinity:nil
																	type:nil
															   reference:nil
																	 url:nil
													   addressComponents:nil
														formattedAddress:nil
													formattedPhoneNumber:nil
																 website:nil
													  internationalPhone:nil
															 searchTerms:nil
														  distanceInFeet:nil
														 distanceInMiles:nil];
	
	AboutGroupViewController *about = [[AboutGroupViewController alloc] initWithNibName:@"AboutGroupViewController"
																		bundle:nil
																		group:group
																		joined:[self findUserAlreadyJoinedGroupWithActivity:[group objectForKey:@"activity"] place:place]
																		activity:[group objectForKey:@"activity"]
																		place:place];
	[self.navigationController pushViewController:about animated:YES];
}

- (BOOL)findUserAlreadyJoinedGroupWithActivity:(NSString *)a place:(GooglePlacesObject *)p {
	BOOL ret = NO;
	
	//Find if they are already part of the group
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query whereKey:@"user" equalTo:[PFUser currentUser]];
	[query whereKey:@"activity" equalTo:a];
	[query whereKey:@"place" equalTo:[p name]];
	
	PFObject *result = [query getFirstObject];
	if (result) {
		ret = YES;
	}
	
	return ret;
}

- (void)autoJoinUser:(PFUser *)user {
	
	autoJoined = YES;
	
	PFObject *group = [parent objectForKey:@"group"];
	[group fetchIfNeeded];
	
	PFObject *member = [PFObject objectWithClassName:@"GroupMembers"];
	[member setObject:[group objectId] forKey: @"group"];
	[member setObject:[group objectForKey:@"activity"] forKey:@"activity"];
	[member setObject:[group objectForKey:@"place"] forKey:@"place"];
	[member setObject:[group objectForKey:@"location"] forKey:@"location"];
	[member setObject:user forKey:@"user"];
	
	if (![member save]) {
		[member saveEventually];
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"changedGroup" object:self];
	}
}

- (void)postToFeedWithID:(NSString *)id {
	@synchronized(self) {
		
		PFQuery *query = [PFQuery queryWithClassName:@"ActivityEvent"];
		[query whereKey:@"proposedActivity" equalTo:parent];
		
		PFObject *feed = [query getFirstObject];
		[feed fetchIfNeeded];
		
		if (feed) {
			[feed setObject:[NSNumber numberWithInt:2] forKey:@"postType"];
			[feed setObject:[PFUser currentUser] forKey:@"creator"];
			
			if (![feed save]) {
				[feed saveEventually];
			}
		}
	}
}


- (void)postComment {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to post a comment" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	if ([[self.activityComment text] isEqualToString:@""]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Valid" message:@"You must put something in the comment message." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	if (posting) {
		return;
	}
	
	if (![self userIsPartOfParentGroup]) {
		[self autoJoinUser:[PFUser currentUser]];
	}
	
	[activityComment resignFirstResponder];
	
	@synchronized(self) {
		PFObject *comment = [PFObject objectWithClassName:@"Comments"];
		[comment setObject:[self.activityComment text] forKey:@"message"];
		[comment setObject:[PFUser currentUser] forKey:@"user"];
		//Make sure that we have a good reference to the ProposedActivity
		if (parent) {
			[comment setObject:parent forKey:@"parent"];
		}
		else {
			[comment setObject:[NSNull null] forKey:@"parent"];
		}
		
		//Try to save the comment, if can't show error message
		[comment saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				[self postToFeedWithID:[comment objectId]];
				[self.activityComment setText:@""];
				[self getProposedActivityHistory];
			
				MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
				[self.navigationController.view addSubview:HUD];
				
				HUD.delegate = self;
				HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
				HUD.mode = MBProgressHUDModeCustomView;
				HUD.labelText = @"Posted";
				
				[HUD show:YES];
				[HUD hide:YES afterDelay:1.75];
				
				posting = NO;
			}
			else if (error) {
				NSString *errorMessage = @"An unknown error occurred while posting event.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Posting Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
	}
}

- (void)getProposedActivityReference {
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"ProposedActivity"];
		[query whereKey:@"activityMessage" equalTo:[parent objectForKey:@"activityMessage"]];
		[query whereKey:@"creator" equalTo:[parent objectForKey:@"creator"]];
		[query whereKey:@"group" equalTo:[parent objectForKey:@"group"]];
		
		parent = [query getFirstObject];
	}

}

- (void)getProposedActivityHistory {
	
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"Comments"];
		[query whereKey:@"parent" equalTo:parent];
		[query addDescendingOrder:@"createdAt"];
		
		[query findObjectsInBackgroundWithBlock: ^(NSArray *objects, NSError *error) {
			if (error) {
				NSString *errorMessage = @"An unknown error occurred while loading event.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			
			results = [[NSMutableArray alloc] initWithArray:objects];
			[commentsTable reloadData];
		}];
	}
	
}

- (BOOL)userIsPartOfParentGroup {
	BOOL ret = NO;
	
	//Get the P.A's parent group
	PFObject *parentGroup = [parent objectForKey:@"group"];
	[parentGroup fetchIfNeeded];
	
	//Search for the user in the group's members
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query whereKey:@"user" equalTo:[PFUser currentUser]];
	[query whereKey:@"activity" equalTo:[parentGroup objectForKey:@"activity"]];
	[query whereKey:@"place" equalTo:[parentGroup objectForKey:@"place"]];
	
	//If we get a result we know the user is part of the group
	PFObject *result = [query getFirstObject];
	if (result) {
		ret = YES;
	}
	
	return ret;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
	
    [parent fetchIfNeeded];
	PFUser *creator = [parent objectForKey:@"creator"];
	PFObject *group = [parent objectForKey:@"group"];
	[creator fetchIfNeeded];

	NSString *message = [NSString stringWithFormat:@"%@ proposes %@ at %@. Here are the details: %@.",	[creator username],
						 [group objectForKey:@"activity"],
						 [group objectForKey:@"place"],
						 [parent objectForKey:@"activityMessage"]];
	
    if ([title isEqualToString:@"Facebook"]) {
		
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [[FConfig instance] getFacebookAppID], @"app_id",
									   [[FConfig instance] getItunesAppLink], @"link",
									   @"http://nathanieldoe.com/AppFiles/FitivityArtwork", @"picture",
									   @"Fitivity", @"name",
									   message, @"caption",
									   @"To join, download the free Fitivity app in the Apple App Store or in Google Play, and participate in physical activities with us.", @"description",
									   @"Go download this app!",  @"message",
									   nil];
		
        [[SocialSharer sharer] shareWithFacebookUsers:params facebook:[PFFacebookUtils facebook]];
    } else if ([title isEqualToString:@"Twitter"]) {
		NSString *tweet = [NSString stringWithFormat:@"I'm playing %@ using fitivity. Download it for free in the Apple app store or Google Play store. Keyword search - fitivity", [group objectForKey:@"activity"]];
        [[SocialSharer sharer] shareMessageWithTwitter:tweet image:nil link:nil];
    } else if ([title isEqualToString:@"SMS"]) {
        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"%@. Download it in the App Store %@", message, [[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"Email"]) {
		NSString *bodyHTML = [NSString stringWithFormat:@"%@ To join, download the free Fitivity app in the Apple App Store or in Google Play, and participate in physical activities with us.<br><br>Download it now in the Apple App Store: <a href=\"%@\">%@</a>", message, [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"];
		NSData *picture = [NSData dataWithContentsOfFile:path];
		NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys: picture, @"data", @"image/png", @"mimeType", @"FitivityIcon", @"fileName", nil];
		
        [[SocialSharer sharer] shareEmailMessage:bodyHTML title:@"Fitivity App" attachment:data isHTML:YES];
    }
}

#pragma mark - Helper Methods 

- (NSString *)getFormattedStringForDate:(NSDate *)date {
	NSDateFormatter *formatter = [[NSDateFormatter  alloc] init];
	[formatter setDateFormat:@"hh:mm a MM/dd"];
	return [formatter stringFromDate:date];
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
	
	if (hud.tag == 2 && autoJoined) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Auto-Joined" message:@"Since you were not part of this group, we automatically joined you to it." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
	
	// Only let users post I'm in once at a time... 
	if (hud.tag == 2) {
		[inButton setEnabled:false];
	}
}

#pragma mark - CommentCell Delegate 

- (void)userWantsProfileAtRow:(NSInteger)row {
	PFObject *comment = [results objectAtIndex:row];
	PFUser *user = [comment objectForKey:@"user"];
	
	UserProfileViewController *profile = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil initWithUser:user];
	[self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
    CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CommentCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	//Seperate the objects within a P.A.
	PFObject *currentPA = [results objectAtIndex:indexPath.row];
	[currentPA fetchIfNeeded];
	
	PFObject *user = [currentPA objectForKey:@"user"];
	
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
	[cell.userPicture.layer setBorderWidth:2];
    
	cell.commentMessage.text = [currentPA objectForKey:@"message"];
		
	if (cell.commentMessage.text.length < kCellMoreLimit) {
		cell.moreIcon.hidden = YES;
	}
	
	cell.commentMessage.adjustsFontSizeToFitWidth = YES;
	cell.userName.text = [user objectForKey:@"username"];
	cell.time.text = [self getFormattedStringForDate:[currentPA createdAt]];
	
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

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//	return kHeaderHeight;
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//	return kFooterHeight;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//	return activityHeader;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//	return activityFooter;
//}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	PFObject *currentPA = [results objectAtIndex:indexPath.row];
	[currentPA fetchIfNeeded];
	
	NSString *message = [currentPA objectForKey:@"message"];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comment" message:message delegate:self cancelButtonTitle:@"Done" otherButtonTitles: nil];
	[alert show];
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextField Delegate

//Move the text fields up so that the keyboard does not cover them
- (void) animateTextField:(UITextField*)textField Up:(BOOL)up {
    
	int movement = (up ? -kThirdCellMove : kThirdCellMove);
//	
//	if ([results count] == 0) {
//		movement = (up ? -kFirstCellMove : kFirstCellMove);
//	} else if ([results count] == 1) {
//		movement = (up ? -kSecondCellMove : kSecondCellMove);
//	} else {
//		movement = (up ? -kThirdCellMove : kThirdCellMove);
//	}
	
	[UIView beginAnimations: @"anim" context: nil];
	[UIView setAnimationBeginsFromCurrentState: YES];
	[UIView setAnimationDuration: kTextFieldAnimationDuration];
	self.view.frame = CGRectOffset(self.view.frame, 0, movement);
	[UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self animateTextField:textField Up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self animateTextField:textField Up:NO];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	if ([textField isEqual:self.activityComment]) {
		[self postComment];
	}
	
	return NO;
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil proposedActivity:(PFObject *)pa {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.parent = pa;
		
		if (![[FConfig instance] connected]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected!" message:@"you must be connected to view this content" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
		else {
			if (!parent) {
				[self performSelectorInBackground:@selector(getProposedActivityReference) withObject:nil];
			}			
		}
		
		UIImage *shareApp = [UIImage imageNamed:@"b_group.png"];
		UIImage *shareAppDown = [UIImage imageNamed:@"b_group_down.png"];
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setImage:shareApp forState:UIControlStateNormal];
		[button setImage:shareAppDown forState:UIControlStateHighlighted];
		[button addTarget:self action:@selector(showGroup:) forControlEvents:UIControlEventTouchUpInside];
		button.frame = CGRectMake(0.0, 0.0, 65.0, 40.0);
		
		UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:button];
		self.navigationItem.rightBarButtonItem = share;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self getProposedActivityHistory];
	
    PFObject *creator = [parent objectForKey:@"creator"];
	[creator fetchIfNeeded];
	
	//Get the image
	PFFile *pic = [creator objectForKey:@"image"];
	NSData *picData = [pic getData];
	if (picData) {
		[creatorPicture setImage:[UIImage imageWithData:picData]];
	}
	else {
		[creatorPicture setImage:[UIImage imageNamed:@"b_avatar_settings.png"]];
	}
	
	//Style picture
	[creatorPicture.layer setCornerRadius:10.0f];
	[creatorPicture.layer setMasksToBounds:YES];
	[creatorPicture.layer setBorderColor:[[[FConfig instance] getFitivityBlue] CGColor]];
	[creatorPicture.layer setBorderWidth:2];
	
	creatorName.text = [creator objectForKey:@"username"];
	message.text = [parent objectForKey:@"activityMessage"];
	
    [moreIcon setHidden:YES];
//	if (activityMessage.text.length >= kHeaderMoreLimit) {
//		[moreIcon setHidden:NO];
//	} else {
//		[moreIcon setHidden:YES];
//	}
	
	activityCreateTime.text = [self getFormattedStringForDate:[parent createdAt]];

	posting = NO;
	autoJoined = NO;
	
	PFObject *group = [parent objectForKey:@"group"];
	[group fetchIfNeeded];
	
	self.navigationItem.title = [group objectForKey:@"activity"];
	self.placeLabel.text = [group objectForKey:@"place"];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
	self.commentsTable.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
    self.commentsTable.separatorColor = [UIColor colorWithRed:178.0/255.0f green:216.0/255.0f blue:254.0/255.0f alpha:1];
}

- (void)viewDidUnload {
	[self setCommentsTable:nil];
	[self setActivityHeader:nil];
	[self setCreatorPicture:nil];
	[self setCreatorName:nil];
	[self setMessage:nil];
	[self setActivityCreateTime:nil];
	[self setActivityFooter:nil];
	[self setActivityComment:nil];
	[self setPlaceLabel:nil];
	[self setInButton:nil];
    [self setMoreIcon:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
