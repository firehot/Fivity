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

#define kEmailIndex			0
#define kUserNameIndex		1
#define kPasswordIndex		2
#define kProfilePicIndex	3

#define kNumberOfRows		4

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize facebookLinkButton;
@synthesize accountInfoTable;
@synthesize onButton;
@synthesize offButton;

#pragma mark - IBAction's 

- (IBAction)signUserOut:(id)sender {
	//Log user out, and alert other classes that the user has logged out
	[PFUser logOut];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"userLoggedOut" object:self];
}

- (IBAction)linkUserWithFacebook:(id)sender {
	//If they aren't linked with facebook, go to facebook and authenticate the app. Otherwise unlink the account
	if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
		[PFFacebookUtils linkUser:[PFUser currentUser] permissions:nil block:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"facebookLogin" object:self];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Fitivity account is now linked with Facebook!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[facebookLinkButton setImage:[UIImage imageNamed:@"FBUnlinkButton.png"] forState:UIControlStateNormal];
				[facebookLinkButton setImage:[UIImage imageNamed:@"FBUnlinkButtonPressed.png"] forState:UIControlStateHighlighted];
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
				[facebookLinkButton setImage:[UIImage imageNamed:@"FBlinkButton.png"] forState:UIControlStateNormal];
				[facebookLinkButton setImage:[UIImage imageNamed:@"FBlinkedButtonPressed.png"] forState:UIControlStateHighlighted];
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

- (void)registerPushNotificationsForCurrentUser {
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

- (IBAction)turnOnPushNotifications:(id)sender {
	
	//Run in background on another thread to avoid GUI lag
	[self performSelectorInBackground:@selector(registerPushNotificationsForCurrentUser) withObject:nil];
	
	[[FConfig instance] setDoesHaveNotifications:YES];
	
	[self.offButton setEnabled:YES];
	[self.onButton setEnabled:NO];
}

- (IBAction)turnOffPushNotifications:(id)sender {
	
	//Run in background on another thread to avoid GUI lag
	[self performSelectorInBackground:@selector(unregisterPushNotificationsForCurrentUser) withObject:nil];
	
	[[FConfig instance] setDoesHaveNotifications:NO];
	
	[self.offButton setEnabled:NO];
	[self.onButton setEnabled:YES];
}

#pragma mark - Helper methods 

- (void)setUpNotificationGUI {
	BOOL status = [[FConfig instance] doesHavePushNotifications];
	
	if (status) {
		[self.offButton setEnabled:YES];
		[self.onButton setEnabled:NO];
	}
	else {
		[self.offButton setEnabled:NO];
		[self.onButton setEnabled:YES];
	}
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
		case kProfilePicIndex: {
            [cell.pictureView setHidden:NO];
            [cell.categoryLabel setHidden:YES];
            PFFile *image = [[PFUser currentUser] objectForKey:@"image"];
            NSData *picData = [image getData];
            
            if (!picData) {
                [cell.pictureView setImage:[UIImage imageNamed:@"FeedCellProfilePlaceholderPicture.png"]];
            }
            else {
                [cell.pictureView setImage:[UIImage imageWithData:picData]];
            }
            
            [cell.informationLabel setText:@"Tap to change picture"];
			break;
        }
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
	return 46;
}



/**
 *	Since this header is so basic no need for a .xib file
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section == 0) {
		UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kHeaderHeight)];
		[header setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
		
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
		case kProfilePicIndex: {
			UIImagePickerController *picker = [[UIImagePickerController alloc] init];
			picker.allowsEditing = YES;
			picker.delegate = self;
			picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
			picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
			[self presentModalViewController:picker animated:YES];
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
	
	//Get the profile picture cell
	SettingsCell *tempCell = (SettingsCell *)[self.accountInfoTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kProfilePicIndex inSection:0]];
	[tempCell.pictureView setImage:choosenPic];
	
	PFUser *user = [PFUser currentUser];
	[user setObject:sendPic forKey:@"image"];
	[user save];
	
	//Notify the user profile view that the picture changed
	[[NSNotificationCenter defaultCenter] postNotificationName:@"changedInformation" object:self];
	
	[picker dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.accountInfoTable.separatorColor = [UIColor colorWithRed:178.0/255.0f green:216.0/255.0f blue:254.0/255.0f alpha:1];
    [self.accountInfoTable setScrollEnabled:NO];
    
	if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
		[facebookLinkButton setImage:[UIImage imageNamed:@"FBUnlinkButton.png"] forState:UIControlStateNormal];
		[facebookLinkButton setImage:[UIImage imageNamed:@"FBUnlinkButtonPressed.png"] forState:UIControlStateHighlighted];
	}
	else {
		[facebookLinkButton setImage:[UIImage imageNamed:@"FBlinkButton.png"] forState:UIControlStateNormal];
		[facebookLinkButton setImage:[UIImage imageNamed:@"FBlinkedButtonPressed.png"] forState:UIControlStateHighlighted];
	}
	
	[self setUpNotificationGUI];
}

- (void)viewDidUnload {
	[self setFacebookLinkButton:nil];
	[self setAccountInfoTable:nil];
	[self setOnButton:nil];
	[self setOffButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
