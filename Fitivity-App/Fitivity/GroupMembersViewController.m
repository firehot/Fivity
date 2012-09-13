//
//  GroupMembersViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/21/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "GroupMembersViewController.h"
#import "UserProfileViewController.h"
#import "NSError+FITParseUtilities.h"
#import "GroupMembersCell.h"

#import "FTabBarViewController.h"
#import "SocialSharer.h"
#import "AppDelegate.h"

@interface GroupMembersViewController ()

@end

@implementation GroupMembersViewController

@synthesize membersTable;
@synthesize place, activity;

#pragma mark - Helper Methods 

- (void)attemptGetMembers {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to view this information" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	//Query for members in a group that has all the attributes of the parent view's group
	CLLocationCoordinate2D loc = [place coordinate];
	PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:loc.latitude longitude:loc.longitude];
	
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query whereKey:@"activity" equalTo:activity];
	[query whereKey:@"location" nearGeoPoint:point withinMiles:0.5];
	[query whereKey:@"place" equalTo:[place name]];
	[query addDescendingOrder:@"username"];
	[query findObjectsInBackgroundWithBlock: ^(NSArray *objects, NSError *error) {
		if (error) {
			NSString *errorMessage = @"An unkown error occured while fetching members.";
			errorMessage = [error userFriendlyParseErrorDescription:YES];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
		members = [[NSArray alloc] initWithArray:objects];
		[membersTable reloadData];
	}];
}

- (void)shareApp {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share App" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"SMS", @"Email", nil];
	
	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:@"Facebook"]) {
		
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [[FConfig instance] getFacebookAppID], @"app_id",
									   [[FConfig instance] getItunesAppLink], @"link",
									   @"http://nathanieldoe.com/AppFiles/FitivityArtwork", @"picture",
									   @"Fitivity", @"name",
	                                   @"Join our fitivity community to get active with myself and other people interested in pick-up sports, fitness, running, or recreation.", @"caption",
									   @"You can download it in the Apple App Store or in Google Play", @"description",
									   @"Go download this app!",  @"message",
									   nil];
		
        [[SocialSharer sharer] shareWithFacebook:params facebook:[PFFacebookUtils facebook]];
    } else if ([title isEqualToString:@"Twitter"]) {
        [[SocialSharer sharer] shareMessageWithTwitter:@"Join #fitivity, the community for people interested in sports & fitness. Download it now in the Apple App Store." image:nil link:[NSURL URLWithString:[[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"SMS"]) {
        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"Join our fitivity community to get active with myself and other people interested in pick-up sports, fitness, running, or recreation. You can download it in in the Apple App Store or in Google Play. %@", [[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"Email"]) {
		NSString *bodyHTML = [NSString stringWithFormat:@"Join our fitivity community to get active with myself and other people interested in pick-up sports, fitness, running, or recreation. You can download it in in the Apple App Store or in Google Play!<br><br>Download it now in the Apple App Store: <a href=\"%@\">%@</a>", [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"];
		NSData *picture = [NSData dataWithContentsOfFile:path];
		NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys: picture, @"data", @"image/png", @"mimeType", @"FitivityIcon", @"fileName", nil];
		
        [[SocialSharer sharer] shareEmailMessage:bodyHTML title:@"Fitivity App" attachment:data isHTML:YES];
    }
}

#pragma mark - UITableViewDelegate 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
    GroupMembersCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"GroupMembersCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];

    }
	
	//Get a reference to the object and set up the cell
	PFObject *current = [members objectAtIndex:indexPath.row];
	PFUser *user = [current objectForKey:@"user"];
	[user fetchIfNeeded];
	PFFile *pic = [user objectForKey:@"image"];
	NSData *picData = [pic getData];
	
	if (picData) {
		[cell.userPhoto setImage:[UIImage imageWithData:picData]];
	}
	else {
		[cell.userPhoto setImage:[UIImage imageNamed:@"b_avatar_settings.png"]];
	}
	
	[cell.userNameLabel setText:[user objectForKey:@"username"]];
    [cell.userNameLabel setTextColor:[UIColor blackColor]];
		
	//Style user photo
	[cell.userPhoto.layer setCornerRadius:10.0f];
	[cell.userPhoto.layer setMasksToBounds:YES];
	[cell.userPhoto.layer setBorderColor:[[[FConfig instance] getFitivityBlue] CGColor]];
	[cell.userPhoto.layer setBorderWidth:2];
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [members count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 76;
}

/**
 *	Since this header is so basic no need for a .xib file
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section == 0) {
		UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kHeaderHeight)];
		[header setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_activity_header.png"]]];
		
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
		[title setText:activity];
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
    //Get the user
	PFObject *current = [members objectAtIndex:indexPath.row];
	PFUser *user = [current objectForKey:@"user"];
	[user fetchIfNeeded];
	
	//Push the user profile onto the navigation stack
	UserProfileViewController *profile = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil initWithUser:user];
	[profile setMainUser:NO];
	[self.navigationController pushViewController:profile animated:YES];
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)p activity:(NSString *)a {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.place = p;
		self.activity = a;
		[self performSelectorInBackground:@selector(attemptGetMembers) withObject:nil];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Members";
	self.membersTable.backgroundColor = [UIColor whiteColor];
	
	UIImage *shareApp = [UIImage imageNamed:@"b_share.png"];
	UIImage *shareAppDown = [UIImage imageNamed:@"b_share_down.png"];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:shareApp forState:UIControlStateNormal];
	[button setImage:shareAppDown forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(shareApp) forControlEvents:UIControlEventTouchUpInside];
	button.frame = CGRectMake(0.0, 0.0, 65.0, 40.0);
	
	UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.rightBarButtonItem = share;
}

- (void)viewDidUnload {
    [self setMembersTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
