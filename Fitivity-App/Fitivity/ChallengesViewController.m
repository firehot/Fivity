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

#define kCellHeight			36.0f
#define kHeaderHeight		62.0f

@interface ChallengesViewController ()

@end

@implementation ChallengesViewController
@synthesize tableView;

@synthesize groupType, challenges;

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
	                                   @"", @"caption",
									   @"Download fitivity in the Apple App Store or in Google Play", @"description",
									   @"Go download this app!",  @"message",
									   nil];
		
        [[SocialSharer sharer] shareWithFacebook:params facebook:[PFFacebookUtils facebook]];
    } else if ([title isEqualToString:@"Twitter"]) {
		NSString *message = @"";
		[[SocialSharer sharer] shareMessageWithTwitter:message image:nil link:[NSURL URLWithString:[[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"SMS"]) {
        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"Download fitivity in in the Apple App Store or in Google Play. %@", [[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"Email"]) {
		NSString *bodyHTML = [NSString stringWithFormat:@"Join our fitivity community to get active with myself and other people interested in pick-up sports, fitness, running, or recreation. You can download it in in the Apple App Store or in Google Play! Download it now in the Apple App Store: <a href=\"%@\">%@</a>", [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
		
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil groupType:(NSString *)type {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
		self.navigationItem.title = type;
		
        self.groupType = type;
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
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ChallengeDayCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }

	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	NSMutableArray *a = [challenges objectAtIndex:indexPath.section];
	PFObject *current = [a objectAtIndex:indexPath.row];
	[current fetchIfNeeded];
	
	[cell.textLabel setBackgroundColor:[UIColor clearColor]];
	[cell.textLabel setTextColor:[UIColor whiteColor]];
	cell.textLabel.text = [NSString stringWithFormat:@"Day %d", [[current objectForKey:@"dayNum"] intValue]];
	
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	//Create the view for the header
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
	UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 9, 280, 28)];
	UILabel *length = [[UILabel alloc] initWithFrame:CGRectMake(20, 38, 280, 21)];
	
	[view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_agenda_level.png"]]];
	[title setBackgroundColor:[UIColor clearColor]];
	[title setTextColor:[UIColor blackColor]];
	[length setBackgroundColor:[UIColor clearColor]];
	[length setTextColor:[UIColor blackColor]];
	
	
	[title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:21]];
	[length setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14]];
	[title setTextAlignment:UITextAlignmentCenter];
	[title setText:[NSString stringWithFormat:@"Level %d", section+1]];
	[length setTextAlignment:UITextAlignmentCenter];
	
	PFObject *o = [[challenges objectAtIndex:section] objectAtIndex:0];
	[o fetchIfNeeded];
	[length setText:[o objectForKey:@"levelLength"]];
	
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
