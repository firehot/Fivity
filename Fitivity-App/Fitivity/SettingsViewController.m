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

#define kNumberOfRows		5

@interface SettingsViewController ()

@end

@implementation SettingsViewController

@synthesize facebookLinkButton;
@synthesize accountInfoTable;

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
			break;
		case kPasswordIndex:
			[cell.categoryLabel setText:@"Password:"];
			[cell.informationLabel setText:[user objectForKey:@"password"]];
			break;
		case kUserNameIndex:
			[cell.categoryLabel setText:@"Username:"];
			[cell.informationLabel setText:[user objectForKey:@"username"]];
			break;
		case kProfilePicIndex:
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
	return 55;
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

#pragma mark - UITableViewDataSource 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
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
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
