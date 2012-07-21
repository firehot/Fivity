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
	
	CLLocationCoordinate2D loc = [place coordinate];
	PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:loc.latitude longitude:loc.longitude];
	
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query whereKey:@"activity" equalTo:activity];
	[query whereKey:@"location" nearGeoPoint:point withinMiles:0.5];
	[query whereKey:@"place" equalTo:[place name]];
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

#pragma mark - UITableViewDelegate 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
    GroupMembersCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"GroupMembersCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];

    }
	
	PFObject *current = [members objectAtIndex:indexPath.row];
	PFUser *user = [current objectForKey:@"user"];
	[user fetchIfNeeded];
	PFFile *pic = [user objectForKey:@"image"];
	NSData *picData = [pic getData];
	
	if (picData) {
		[cell.userPhoto setImage:[UIImage imageWithData:picData]];
	}
	else {
		[cell.userPhoto setImage:[UIImage imageNamed:@"FeedCellProfilePlaceholderPicture.png"]];
	}
	
	[cell.userNameLabel setText:[user objectForKey:@"username"]];
		
	//Style user photo
	[cell.userPhoto.layer setCornerRadius:10.0f];
	[cell.userPhoto.layer setMasksToBounds:YES];
	[cell.userPhoto.layer setBorderColor:[[UIColor whiteColor] CGColor]];
	[cell.userPhoto.layer setBorderWidth:4];
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [members count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 96;
}

/**
 *	Since this header is so basic no need for a .xib file
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	if (section == 0) {
		UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kHeaderHeight)];
		[header setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
		
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
		[self attemptGetMembers];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
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
