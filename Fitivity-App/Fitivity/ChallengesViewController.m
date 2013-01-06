//
//  ChallengesViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 8/21/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ChallengesViewController.h"
#import "ChallengeOverviewViewController.h"
#import "NSError+FITParseUtilities.h"
#import "FTabBarViewController.h"
#import "SocialSharer.h"
#import "AppDelegate.h"
#import "FirstChallengeCell.h"

#define kCellHeight			36.0f
#define kHeaderHeight		60.0f

@interface ChallengesViewController ()

@end

@implementation ChallengesViewController

@synthesize tableView;
@synthesize groupType, challenges, groupLocation;

#pragma mark - Helper Methods

//Create an array of arrays for each day of exercises
- (NSMutableArray *)orderDays:(NSArray *)days {
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	if (days != nil && [days count] > 0) {
		NSMutableArray *temp = [[NSMutableArray alloc] init];
		int level = 0;
		
		for (PFObject *o in days) {
			[o fetchIfNeeded];
			int x = [[o objectForKey:@"level"] intValue];
			if (x != level) {
				level = x;
				
				//Add the array of previous items and reinitialize it
				if ([temp count] != 0) {
					[array addObject:temp];
				}
				temp = [[NSMutableArray alloc] init];
				[temp addObject:o];
			}
			else {
				[temp addObject:o];
			}
		}
		
		//Add the last array
		[array addObject:temp];
	}
	
	return array;
}

- (void)attemptQuery {
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"ChallengeDay"];
		PFObject *parent = [PFObject objectWithoutDataWithClassName:@"Challenge" objectId:[[FConfig instance] getChallengeIDForActivityType:groupType]];
		[query whereKey:@"parent" equalTo:parent];
		[query addAscendingOrder:@"level"];
		[query addAscendingOrder:@"dayNum"];
		[query setLimit:300];
		[query setCachePolicy:kPFCachePolicyNetworkElseCache];
		[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
			if (error) {
				NSString *errorMessage = @"There was an error loading these challenges";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				return;
			}
			else if (objects) {
				self.challenges = [self orderDays:objects];
				[self.tableView reloadData];
			}
		}];
	}
}

- (void)shareViewChallenge {
	if ([[FConfig instance] shouldShareChallenge:groupType]) {
		
		[[FConfig instance] setSharedForChallenge:groupType];
		
		if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
			
			NSString *message = [NSString stringWithFormat:@"Do the %@ challenge with me at %@.", groupType, groupLocation];
			NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										   [[FConfig instance] getFacebookAppID], @"app_id",
										   [[FConfig instance] getItunesAppLink], @"link",
										   @"http://www.fitivitymovement.com/FitivityAppIcon.png", @"picture",
										   @"Fitivity", @"name",
										   @"Download the free fitivity app in the Apple App Store or in Google Play", @"description",
										   message,  @"message",
										   nil];
			
			[[SocialSharer sharer] shareWithFacebook:params facebook:[PFFacebookUtils facebook]];
		}
		if ([PFTwitterUtils isLinkedWithUser:[PFUser currentUser]]) {
			NSString *message = [NSString stringWithFormat:@"I’m doing the %@ challenge using fitivity. Download it in the Apple App store or Google Play store. Keyword search - fitivity", groupType];
			[[SocialSharer sharer] shareMessageWithTwitter:message image:nil link:nil];
		}
	}
	
}

- (void)shareApp {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share Challenge" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"SMS", @"Email", nil];
	
//	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
	[sheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:@"Facebook"]) {
		
		NSString *message = [NSString stringWithFormat:@"Do the %@ challenge with me at %@.", groupType, groupLocation];
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [[FConfig instance] getFacebookAppID], @"app_id",
									   [[FConfig instance] getItunesAppLink], @"link",
									   @"http://www.fitivitymovement.com/FitivityAppIcon.png", @"picture",
									   @"Fitivity", @"name",
									   @"Download the free fitivity app in the Apple App Store or in Google Play", @"description",
									   message,  @"message",
									   nil];
		
        [[SocialSharer sharer] shareWithFacebookUsers:params facebook:[PFFacebookUtils facebook]];
    } else if ([title isEqualToString:@"Twitter"]) {
		NSString *message = [NSString stringWithFormat:@"Do the %@ training challenge using fitivity and accomplish your %@ goals. Download the free fitivity app using this link.", groupType, groupType];
		[[SocialSharer sharer] shareMessageWithTwitter:message image:nil link:nil];
    } else if ([title isEqualToString:@"SMS"]) {
        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"Do the %@ training challenge using fitivity and accomplish your %@ goals. Download the free fitivity app in the Apple App Store or in Google Play. %@", groupType, groupType, [[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"Email"]) {
		NSString *bodyHTML = [NSString stringWithFormat:@"Do the %@ training challenge using fitivity and accomplish your %@ goals. You can download it for free in the Apple App Store or in Google Play! Download it now in the Apple App Store: <a href=\"%@\">%@</a>", groupType, groupType, [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"];
		NSData *picture = [NSData dataWithContentsOfFile:path];
		NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys: picture, @"data", @"image/png", @"mimeType", @"FitivityIcon", @"fileName", nil];
		
        [[SocialSharer sharer] shareEmailMessage:bodyHTML title:@"Fitivity App" attachment:data isHTML:YES];
    }
}

#pragma mark - UIAlertViewDelegate 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:@"OK"]) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

#pragma mark - View Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil groupType:(NSString *)type groupLocation:(NSString *)location {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
		self.navigationItem.title = type;
		
        self.groupType = type;
		self.groupLocation = location;
		if (groupType) {
			
			if ([[FConfig instance] connected]) {
				[self attemptQuery];
			}
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to view this content." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an issue loading these challenges." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	UIImage *shareApp = [UIImage imageNamed:@"b_share.png"];
	UIImage *shareAppDown = [UIImage imageNamed:@"b_share_down.png"];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:shareApp forState:UIControlStateNormal];
	[button setImage:shareAppDown forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(shareApp) forControlEvents:UIControlEventTouchUpInside];
	button.frame = CGRectMake(0.0, 0.0, 65.0, 40.0);
	
	UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.rightBarButtonItem = share;

	tableView.backgroundColor = [UIColor clearColor];
	tableView.separatorColor = [UIColor clearColor];
	
	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_main_group.png"]]];
	
	[self shareViewChallenge];
}

- (void)viewDidUnload {
	[self setTableView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [challenges count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[challenges objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return kHeaderHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	FirstChallengeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FirstChallengeCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	NSMutableArray *a = [challenges objectAtIndex:indexPath.section];
	PFObject *current = [a objectAtIndex:indexPath.row];
	[current fetchIfNeeded];
	
	[cell.title setBackgroundColor:[UIColor clearColor]];
	[cell.title setTextColor:[UIColor blackColor]];
	cell.title.text = [NSString stringWithFormat:@"Day %d", [[current objectForKey:@"dayNum"] intValue]];
	
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	//Create the view for the header
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
	UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_challenge_header.png"]];
	[bg setFrame:view.frame];
	UILabel *level = [[UILabel alloc] initWithFrame:CGRectMake(5, 8, 53, 21)];
	UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(7, 30, 53, 21)];
	UILabel *length = [[UILabel alloc] initWithFrame:CGRectMake(74, 19, 234, 21)];
	
	
	[view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_main_group.png"]]];
	[level setBackgroundColor:[UIColor clearColor]];
	[level setTextColor:[UIColor whiteColor]];
	[title setBackgroundColor:[UIColor clearColor]];
	[title setTextColor:[UIColor whiteColor]];
	[length setBackgroundColor:[UIColor clearColor]];
	[length setTextColor:[UIColor whiteColor]];
	
	[level setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20]];
	[title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20]];
	[length setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14]];
	
	[length setAdjustsFontSizeToFitWidth:YES];
	[length setAdjustsLetterSpacingToFitWidth:YES];
	[level setMinimumFontSize:10];
	
	[level setTextAlignment:UITextAlignmentCenter];
	[level setText:@"Level"];
	[title setTextAlignment:UITextAlignmentCenter];
	[title setText:[NSString stringWithFormat:@"%d", section+1]];
	[length setTextAlignment:UITextAlignmentCenter];
	
	PFObject *o = [[challenges objectAtIndex:section] objectAtIndex:0];
	[o fetchIfNeeded];
	[length setText:[o objectForKey:@"levelLength"]];
	
	[view addSubview:bg];
	[view addSubview:level];
	[view addSubview:title];
	[view addSubview:length];
	
	return view;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	PFObject *o = [[challenges objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	ChallengeOverviewViewController *overview = [[ChallengeOverviewViewController alloc] initWithNibName:@"ChallengeOverviewViewController" bundle:nil day:o title:groupType];
	
	[self.navigationController pushViewController:overview animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
