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

@interface UserProfileViewController ()

@end

@implementation UserProfileViewController

@synthesize mainUser;
@synthesize userProfile;
@synthesize groupsTable;
@synthesize userNameLabel;
@synthesize userPicture;

#pragma mark - Helper Methods 

- (void) showSettings {
	SettingsViewController *settings = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
	[self.navigationController pushViewController:settings animated:YES];
}

- (void)attemptGetUserGroups {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to create a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query addDescendingOrder:@"updatedAt"];
	[query whereKey:@"user" equalTo:[PFUser currentUser]];
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

- (void)setCorrectPicture {
	PFFile *pic = [userProfile objectForKey:@"image"];
	NSData *picData = [pic getData];
	
	if (picData) {
		[self.userPicture setImage:[UIImage imageWithData:picData]];
	}
	else if ([PFFacebookUtils isLinkedWithUser:userProfile]) {
		[self requestFacebookData];
	}
	
	//Round the pictures edges and add border
	[self.userPicture.layer setCornerRadius:10.0f];
	[self.userPicture.layer setMasksToBounds:YES];
	[self.userPicture.layer setBorderColor:[[UIColor whiteColor] CGColor]];
	[self.userPicture.layer setBorderWidth:5.5];
}

- (BOOL)deleteUserFromGroupAtIndex:(NSInteger)index {
	PFObject *deleteObject = [groupResults objectAtIndex:index];
	BOOL ret = [deleteObject delete];
	
	//Only delete the group from the GUI if the delete was successful 
	if (ret) {
		[groupResults removeObjectAtIndex:index];
	}
	return ret;
}

- (void)requestFacebookData { 
	
	// Create request for user's facebook data
    NSString *requestPath = @"me/?fields=name,picture&type=large";
    
    // Send request to facebook
    [[PFFacebookUtils facebook] requestWithGraphPath:requestPath andDelegate:self];
}

#pragma mark - Facebook Delegate 

-(void)request:(PF_FBRequest *)request didLoad:(id)result {
    NSDictionary *userData = (NSDictionary *)result; // The result is a dictionary
	
	self.userNameLabel.text = [userData objectForKey:@"name"];
	
	profilePictureData = [[NSMutableData alloc] init];
	NSString *picURL = [(NSDictionary *)[(NSDictionary *)[userData objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:picURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
	
	[NSURLConnection connectionWithRequest:urlRequest delegate:self];
}

#pragma mark - NSURLConnectioin Delegate 

// Called every time a chunk of the data is received
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [profilePictureData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Set the image in the header imageView
    [self.userPicture setImage:[UIImage imageWithData:profilePictureData]];
	
	//Upload to parse for future use
	PFFile *imageFile = [PFFile fileWithData:profilePictureData];
	[imageFile save];
	
	PFUser *user = [PFUser currentUser];
	[user setObject:imageFile forKey:@"image"];
	[user save];
	
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
	
	PFObject *currentGroup = [groupResults objectAtIndex:indexPath.row];
	
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
		[header setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
		
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //Get the group and present it
	PFObject *currentGroup = [groupResults objectAtIndex:indexPath.row];
	PFGeoPoint *point = [currentGroup objectForKey:@"location"];
	
	GooglePlacesObject *place = [[GooglePlacesObject alloc] initWithName:[currentGroup objectForKey:@"place"] latitude:point.latitude longitude:point.longitude placeIcon:nil rating:nil vicinity:nil type:nil reference:nil url:nil addressComponents:nil formattedAddress:nil formattedPhoneNumber:nil website:nil internationalPhone:nil searchTerms:nil distanceInFeet:nil distanceInMiles:nil];
	GroupPageViewController *group = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:place activity:[currentGroup objectForKey:@"activity"] challenge:NO];
	
	[self.navigationController pushViewController:group animated:YES];
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
	//Check to make sure that the table can be edited by the current user
	if (!mainUser) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Permissions" message:@"You don't have permissions to delete this group." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}
	else if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You need to be connected to edit your groups." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
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

- (IBAction)enlargePicture:(id)sender {
	PFFile *pic = [userProfile objectForKey:@"image"];
	NDArtworkPopout *pop = [[NDArtworkPopout alloc] initWithImage:[UIImage imageWithData:[pic getData]]];
	[pop show];
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil initWithUser:(PFUser *)user {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.userProfile = user;
		
		//Make sure that the user exists first (for first launch)
		if ([PFUser currentUser]) {
			[self attemptGetUserGroups];
		}
		
		if (userProfile && [PFFacebookUtils isLinkedWithUser:userProfile]) {
			//Load FB name and Pic
			[self requestFacebookData];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attemptGetUserGroups) name:@"createdGroup" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestFacebookData) name:@"facebookLogin" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidLoad) name:@"changedInformation" object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	
	//If there is no user yet (hasn't logged in yet), and it is the users profile set it up with the current user
	if (mainUser && userProfile == nil) {
		[self setCorrectPicture];
	}
	else {
		[self setCorrectPicture];
	}
	
	[self.userNameLabel setText:[userProfile username]];
	
	//If the results didn't load at init, try to reload them.
	if (!groupResults) {
		[self attemptGetUserGroups];
	}
	
	//Only display settings button if on the main users profile
	if (mainUser) {
		UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UserProfileSettingsWrench.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(showSettings)];
		self.navigationItem.rightBarButtonItem = settings;
	}
    
}

- (void)viewDidUnload {
	[self setUserPicture:nil];
	[self setUserNameLabel:nil];
	[self setGroupsTable:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
