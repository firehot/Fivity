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
@synthesize footerView;

#pragma mark - IBAction's 

- (IBAction)signUserOut:(id)sender {
	//Log user out, and alert other classes that the user has logged out
	[PFUser logOut];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"userLoggedOut" object:self];
}

- (IBAction)linkUserWithFacebook:(id)sender {
	if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
		[PFFacebookUtils linkUser:[PFUser currentUser] permissions:nil block:^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"facebookLogin" object:self];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Fitivity account is now linked with Facebook!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				[facebookLinkButton.titleLabel setText:@"Unlink Facebook"];
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
				[facebookLinkButton.titleLabel setText:@"Link with Facebook"];
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
	return 55;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 115;
}

/**
 *	Since this header is so basic no need for a .xib file
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section == 0) {
		UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kHeaderHeight)];
		[header setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
		
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
		[title setText:@"Accout Settings"];
		[title setTextAlignment:UITextAlignmentCenter];
		[title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:18]];
		[title setBackgroundColor:[UIColor clearColor]];
		[title setTextColor:[UIColor whiteColor]];
		[header addSubview:title];
		
		return header;
	}
	return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return footerView;
}

#pragma mark - UITableViewDataSource 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.row) {
		case kEmailIndex:
			break;
		case kUserNameIndex:
			break;
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
        self.footerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[facebookLinkButton.titleLabel setText:([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) ? @"Unlink Facebook" : @"Link with Facebook"];
}

- (void)viewDidUnload {
	[self setFacebookLinkButton:nil];
	[self setAccountInfoTable:nil];
    [self setFooterView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
