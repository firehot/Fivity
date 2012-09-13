//
//  SettingsViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/18/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "SettingsViewController.h"
#import "UserProfileViewController.h"
#import "NSError+FITParseUtilities.h"
#import "SettingsCell.h"
#import "AppDelegate.h"

#define kEmailIndex			0
#define kUserNameIndex		1
#define kPasswordIndex		2

#define kNumberOfRows		3

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize facebookLinkButton;
@synthesize accountInfoTable;
@synthesize pushNotificationsButton;
@synthesize pictureButton;
@synthesize shareGroupButton;
@synthesize shareActivityButton;
@synthesize twitterLinkButton;

bool pushNotifications;
bool shareGroup;
bool shareActivity;

#pragma mark - IBAction's 

- (IBAction)selectImage:(id)sender{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = YES;
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
    [picker.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
    [self presentModalViewController:picker animated:YES];
}

- (void)signUserOut{
    //Log user out, and alert other classes that the user has logged out
	[PFUser logOut];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"userLoggedOut" object:self];
	}

- (IBAction)linkUserWithTwitter:(id)sender {
	if (![PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
		[PFTwitterUtils linkUser:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Fitivity account is now linked with Twitter!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
                [twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_unlink.png"] forState:UIControlStateNormal];
				[twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_unlink_down.png"] forState:UIControlStateHighlighted];
				
				// Automatically set sharing to on
				[[FConfig instance] setShareGroupPost:YES];
				[[FConfig instance] setSharePAPost:YES];
				[[FConfig instance] setShareChallenge:YES];
				[self setUpSharing];
			}
			
			if (error) {
				NSString *errorMessage = @"An unknown error occurred while linking with Twitter";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Link Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
	}
	else {
		[PFTwitterUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Fitivity account is no longer associated with Twitter." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
                [twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_link.png"] forState:UIControlStateNormal];
				[twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_link_down.png"] forState:UIControlStateHighlighted];
			}
			
			if (error) {
				NSString *errorMessage = @"An unknown error occurred while unlinking with Twitter";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unlink Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
	}
}

- (IBAction)linkUserWithFacebook:(id)sender {
	//If they aren't linked with facebook, go to facebook and authenticate the app. Otherwise unlink the account
	if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
		[PFFacebookUtils linkUser:[PFUser currentUser] permissions:nil block:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"facebookLogin" object:self];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Fitivity account is now linked with Facebook!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_unlink.png"] forState:UIControlStateNormal];
				[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_unlink_down.png"] forState:UIControlStateHighlighted];
				
				// Automatically set sharing to on
				[[FConfig instance] setShareGroupPost:YES];
				[[FConfig instance] setSharePAPost:YES];
				[[FConfig instance] setShareChallenge:YES];
				[self setUpSharing];
			}
			
			if (error) {
				NSString *errorMessage = @"An unknown error occurred while linking with Facebook";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Link Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
	}
	else {
		[PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Fitivity account is no longer associated with Facebook." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_link.png"] forState:UIControlStateNormal];
				[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_link_down.png"] forState:UIControlStateHighlighted];
			}
			
			if (error) {
				NSString *errorMessage = @"An unknown error occurred while unlinking with Facebook";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unlink Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
	}
}

- (void)unregisterPushNotificationsForCurrentUser {
	@synchronized(self) {
		
		//Get all of the groups the user is part of
		PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
		[query whereKey:@"user" equalTo:[PFUser currentUser]];
		NSArray *results = [query findObjects];
		
		//Populate just the group objectID's since that is what the push channel is named after
		NSMutableArray *groupIDS = [[NSMutableArray alloc] init];
		for (PFObject *o in results) {
			[groupIDS addObject:[o objectForKey:@"group"]];
		}
		
		//For each objectID unsubscribe from the notifications
		for (NSString *s in groupIDS) {
			[PFPush unsubscribeFromChannelInBackground:[NSString stringWithFormat:@"Fitivity%@", s] block:^(BOOL succeeded, NSError *error) {
				if (succeeded) {
#ifdef DEBUG
					NSLog(@"%@ succeeded unsubscribing", s);
#endif
				}
			}];
		}
	}
}

- (IBAction)shareGroup:(id)sender {
	
	BOOL linked = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] || [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
	
	if (!linked) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Linked" message:@"You must link your account with either Twitter or Facebook before turning these settings on." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	[[FConfig instance] setShareGroupPost:![[FConfig instance] shouldShareGroupStart]];
	[self setUpSharing];
}

- (IBAction)shareActivity:(id)sender {
	BOOL linked = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] || [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
	
	if (!linked) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Linked" message:@"You must link your account with either Twitter or Facebook before turning these settings on." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	[[FConfig instance] setSharePAPost:![[FConfig instance] shouldSharePAStart]];
	[self setUpSharing];
}

- (IBAction)shareChallenge:(id)sender {
	BOOL linked = [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]] || [PFTwitterUtils isLinkedWithUser:[PFUser currentUser]];
	
	if (!linked) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Linked" message:@"You must link your account with either Twitter or Facebook before turning these settings on." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	[[FConfig instance] setShareChallenge:![[FConfig instance] shouldShareChallenge]];
	[self setUpSharing];
}

- (void)registerPushNotificationsForCurrentUser {
	
	UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
	if (types == UIRemoteNotificationTypeNone) {
        
		NSString *message = @"You declined access for this app to send push notifications. Unfortunately Apple doesn't allow apps to re-enable push notifications unless the app has been deleted from your device for one day.";
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Enabled" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
        
		[pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_off.png"] forState:UIControlStateNormal];
		[pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_off_down.png"] forState:UIControlStateHighlighted];
		pushNotifications = NO;
        
		return;
	}
	
	@synchronized(self) {
		//Get all of the groups the user is part of
		PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
		[query whereKey:@"user" equalTo:[PFUser currentUser]];
		NSArray *results = [query findObjects];
		
		//Populate just the group objectID's since that is what the push channel is named after
		NSMutableArray *groupIDS = [[NSMutableArray alloc] init];
		for (PFObject *o in results) {
			[groupIDS addObject:[o objectForKey:@"group"]];
		}
		
		//For each objectID subscribe from the notifications
		for (NSString *s in groupIDS) {
			[PFPush subscribeToChannelInBackground:[NSString stringWithFormat:@"Fitivity%@", s] block:^(BOOL succeeded, NSError *error) {
				if (succeeded) {
#ifdef DEBUG
					NSLog(@"%@ succeeded subscribing", s);
#endif
				}
			}];
		}
	}
}

- (IBAction)togglePushNotifications:(id)sender {
	
	//Run in background on another thread to avoid GUI lag
	if(!pushNotifications){
    [self performSelectorInBackground:@selector(registerPushNotificationsForCurrentUser) withObject:nil];
	
	[[FConfig instance] setDoesHaveNotifications:YES];
	
    [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_on.png"] forState:UIControlStateNormal];
    [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_contorl_on_down.png"] forState:UIControlStateHighlighted];
        
    pushNotifications = YES;
        
        NSLog(@"Push notifications have been turned on");
    }
    else {
        [self performSelectorInBackground:@selector(unregisterPushNotificationsForCurrentUser) withObject:nil];
        
        [[FConfig instance] setDoesHaveNotifications:NO];
        
        [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_off.png"] forState:UIControlStateNormal];
        [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_off_down.png"] forState:UIControlStateHighlighted];
        NSLog(@"Push notifications have been turned off");
    pushNotifications = NO;
    }
}

#pragma mark - Helper methods 

- (void)setUpNotificationGUI {
	BOOL status = [[FConfig instance] doesHavePushNotifications];
    
	if (status) {
        [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_on.png"] forState:UIControlStateNormal];
        [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_on_down.png"] forState:UIControlStateHighlighted];
        pushNotifications = YES;
	}
	else {
        [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_off.png"] forState:UIControlStateNormal];
        [pushNotificationsButton setImage:[UIImage imageNamed:@"pn_control_off_down.png"] forState:UIControlStateHighlighted];
        pushNotifications = NO;
	}
}

- (void)setUpSharing {
	
	BOOL groupStatus = [[FConfig instance] shouldShareGroupStart];
	BOOL paStatus = [[FConfig instance] shouldSharePAStart];
	BOOL challengeStatus = [[FConfig instance] shouldShareChallenge];
	
	if (groupStatus) {
		[shareGroupButton setImage:[UIImage imageNamed:@"media_control_on.png"] forState:UIControlStateNormal];
		[shareGroupButton setImage:[UIImage imageNamed:@"media_control_on_down.png"] forState:UIControlStateHighlighted];
	}
	else {
		[shareGroupButton setImage:[UIImage imageNamed:@"media_control_off.png"] forState:UIControlStateNormal];
		[shareGroupButton setImage:[UIImage imageNamed:@"media_control_off_down.png"] forState:UIControlStateHighlighted];
	}
	
	if (paStatus) {
		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_on.png"] forState:UIControlStateNormal];
		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_on_down.png"] forState:UIControlStateHighlighted];
	}
	else {
		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_off.png"] forState:UIControlStateNormal];
		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_off_down.png"] forState:UIControlStateHighlighted];
	}

	// ONCE YOU ADD THE CHALLENGE BUTOON CHANGE THIS AND IT WILL WORK
//	if (challengeStatus) {
//		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_on.png"] forState:UIControlStateNormal];
//		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_on_down.png"] forState:UIControlStateHighlighted];
//	}
//	else {
//		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_off.png"] forState:UIControlStateNormal];
//		[shareActivityButton setImage:[UIImage imageNamed:@"media_control_off_down.png"] forState:UIControlStateHighlighted];
//	}
}

#pragma mark - UITableViewDelegate 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
	SettingsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SettingsCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	PFUser *user = [PFUser currentUser];
	
	switch (indexPath.row) {
		case kEmailIndex:
			[cell.categoryLabel setText:@"E-mail:"];
			[cell.informationLabel setText:[user objectForKey:@"email"]];
            [cell.pictureView setHidden:YES];
			break;
		case kPasswordIndex:
			[cell.categoryLabel setText:@"Password:"];
			[cell.informationLabel setText:@"********"]; //Don't show a users password in plain text
            [cell.pictureView setHidden:YES];
			break;
		case kUserNameIndex:
			[cell.categoryLabel setText:@"Username:"];
			[cell.informationLabel setText:[user objectForKey:@"username"]];
            [cell.pictureView setHidden:YES];
			break;
            
		default:
			break;
	}
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return kNumberOfRows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 39;
}



/**
 *	Since this header is so basic no need for a .xib file
 */

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section == 0) {
		UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kHeaderHeight)];
		[header setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_heading_header.png"]]];
		
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
		[title setText:@"Account Settings"];
		[title setTextAlignment:UITextAlignmentCenter];
		[title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
		[title setBackgroundColor:[UIColor clearColor]];
		[title setTextColor:[UIColor whiteColor]];
		[header addSubview:title];
		
		return header;
	}
	return nil;
}


#pragma mark - UITableViewDataSource 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//Determine what should be done for each row when selected
	switch (indexPath.row) {
		case kEmailIndex: {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Change Email" message:@"What would you like to change your email address to?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
			[alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
			[alert setTag:2];
			[alert show];
			break;
		}
		case kUserNameIndex: {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Change Username" message:@"What would you like to change your username to?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
			[alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
			[alert setTag:1];
			[alert show];
			break;
		}
		case kPasswordIndex: {
			BOOL ret = [PFUser requestPasswordResetForEmail:[[PFUser currentUser] email]];
			
			if (ret) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Reset" message:@"An email has been sent to your email address with instructions on how to reset your password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Reset Error" message:@"You are unable to reset your password at this time. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
			break;
		}
		default:
			break;
	}
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIAlertView Delegate 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	//Changing Username
	if ([title isEqualToString:@"Done"] && alertView.tag == 1) {
		PFUser *user = [PFUser currentUser];
		[user setUsername:[[alertView textFieldAtIndex:0] text]];
		[user save];
		[self.accountInfoTable reloadData];
	}
	//Changing Email
	else if ([title isEqualToString:@"Done"] && alertView.tag == 2) {
		PFUser *user = [PFUser currentUser];
		[user setEmail:[[alertView textFieldAtIndex:0] text]];
		[user save];
		[self.accountInfoTable reloadData];
	}
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	//Get the picture, update the GUI and send to server
	UIImage *choosenPic = [info objectForKey:@"UIImagePickerControllerEditedImage"];
	PFFile *sendPic = [PFFile fileWithData:UIImagePNGRepresentation(choosenPic)];
	[sendPic save];
	
	PFUser *user = [PFUser currentUser];
	[user setObject:sendPic forKey:@"image"];
	[user save];
	
	//Notify the user profile view that the picture changed
	[[NSNotificationCenter defaultCenter] postNotificationName:@"changedInformation" object:self];
	
    [pictureButton setImage:choosenPic forState:UIControlStateNormal];
    
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UIImage *signOut = [UIImage imageNamed:@"b_sign_out.png"];
    UIImage *signOutDown = [UIImage imageNamed:@"b_sign_out_down.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:signOut forState:UIControlStateNormal];
    [button setImage:signOutDown forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(signUserOut) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0.0, 0.0, 58.0, 40.0);
    
    UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = share;
    
    self.accountInfoTable.separatorColor = [UIColor colorWithRed:178.0/255.0f green:216.0/255.0f blue:254.0/255.0f alpha:1];
    [self.accountInfoTable setScrollEnabled:NO];
    self.accountInfoTable.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
    
    PFFile *image = [[PFUser currentUser] objectForKey:@"image"];
    NSData *picData = [image getData];
    
    if (!picData) {
        [pictureButton setImage:[UIImage imageNamed:@"b_avatar_settings.png"] forState:UIControlStateNormal];
    }
    else {
        [pictureButton setImage:[UIImage imageWithData:picData] forState:UIControlStateNormal];
    }
    [pictureButton.layer setMasksToBounds:YES];
    [pictureButton.layer setCornerRadius:6.0];

    [PFFacebookUtils initializeWithApplicationId:[[FConfig instance] getFacebookAppID]];
	if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
		[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_unlink.png"] forState:UIControlStateNormal];
		[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_unlink_down.png"] forState:UIControlStateHighlighted];
	}
	else {
		[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_link.png"] forState:UIControlStateNormal];
		[facebookLinkButton setImage:[UIImage imageNamed:@"b_facebook_link_down.png"] forState:UIControlStateHighlighted];
	}
	
	if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
		[twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_unlink.png"] forState:UIControlStateNormal];
		[twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_unlink_down.png"] forState:UIControlStateHighlighted];
	} else {
		[twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_link.png"] forState:UIControlStateNormal];
		[twitterLinkButton setImage:[UIImage imageNamed:@"b_twitter_link_down.png"] forState:UIControlStateHighlighted];
	}
	
	[self setUpSharing];
	[self setUpNotificationGUI];
}

- (void)viewDidUnload {
	[self setFacebookLinkButton:nil];
	[self setAccountInfoTable:nil];
	[self setPushNotificationsButton:nil];
    [self setPictureButton:nil];
    [self setShareActivityButton:nil];
    [self setShareGroupButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
