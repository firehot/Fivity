//
//  DiscoverFeedViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 8/8/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "AppDelegate.h"
#import "DiscoverFeedViewController.h"
#import "DiscoverCell.h"
#import "OHAttributedLabel.h"
#import "NSAttributedString+Attributes.h"
#import "GooglePlacesObject.h"
#import "GroupPageViewController.h"
#import "ProposedActivityViewController.h"
#import "UserProfileViewController.h"
#import "FTabBarViewController.h"
#import "SocialSharer.h"
#import "NSError+FITParseUtilities.h"


#define kFeedLimit			40
#define kCellHeight			92.0f
#define kHeaderHeight       20

#define kCellTypeGroup		0
#define kCellTypePA			1
#define kCellTypeComment	2

#define kRemindAfter		3

#define kMetersToMiles		0.000621371192
#define kMilesRadius		40.0

@interface DiscoverFeedViewController ()

@end

@implementation DiscoverFeedViewController

@synthesize locationManager;
@synthesize sortCriteria;

#pragma mark - Helper Methods 

- (void)shareApp {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share App" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"SMS", @"Email", nil];
	
	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
}

- (void)showSortPicker {
	SortView *sv = [[SortView alloc] initWithFrame:self.view.frame items:[[FConfig instance] searchActivities] selectedKey:[[FConfig instance] getSortedFeedKey]];
	[sv setDelegate:self];
	[sv show];
}

- (void)handleReminders {
	if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
		if ([[FConfig instance] getLaunchCount] % kRemindAfter == 0) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Link with Facebook!" message:@"If you link your Fitivity Account with Facebook your profile will be completed!:" delegate:self cancelButtonTitle:@"No Thanks" otherButtonTitles: @"Link Now", nil];
			[alert setTag:2];
			[alert show];
		}
	}
}

- (void)imageView:(PFImageView *)imgView setImage:(PFFile *)imageFile styled:(BOOL)styled {
	imgView.image = [UIImage imageNamed:@"b_avatar_settings.png"]; //Placeholder
	
	if (imageFile != [NSNull null]) {
		imgView.file = imageFile;
		[imgView loadInBackground];
	}
	
	if (styled) {
		//Style user photo
		[imgView.layer setCornerRadius:10.0f];
		[imgView.layer setMasksToBounds:YES];
		[imgView.layer setBorderColor:[[[FConfig instance] getFitivityBlue] CGColor]];
		[imgView.layer setBorderWidth:2];
	}
}

- (void)handlePushNotification:(PFObject *)pa {
	[pa fetchIfNeeded];
	
	ProposedActivityViewController *activity = [[ProposedActivityViewController alloc] initWithNibName:@"ProposedActivityViewController" bundle:nil proposedActivity:pa];
	[self.navigationController pushViewController:activity animated:YES];
}

- (NSAttributedString *)colorLabelString:(NSString *)string {
	NSArray *components = [string componentsSeparatedByString:@" at "];
	NSMutableAttributedString *attrStr = [NSMutableAttributedString attributedStringWithString:string];
	[attrStr setTextColor:[UIColor blackColor]];
	[attrStr setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14]];
	
	// now we change the color of the activity & location
	[attrStr setTextColor:[UIColor colorWithRed:42.0/255.0f green:89.0/255.0f blue:141.0/255.0f alpha:1] range:[string rangeOfString:[components objectAtIndex:0]]];
	[attrStr setTextColor:[UIColor colorWithRed:142.0/255.0f green:198.0/255.0f blue:250.0/255.0f alpha:1] range:[string rangeOfString:[components objectAtIndex:1]]];
	
	return attrStr;
}

- (NSString *)stringForDate:(NSDate *)date {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"hh:mm a"];
	return [formatter stringFromDate:date];
}

- (BOOL)happendToday:(int)cellIndex {
	BOOL ret = YES;
	
	if (todayCells != [self.objects count] && cellIndex >= todayCells-1){
		ret = NO;
	}
	
	return ret;
}

- (NSString *)getDistanceAwayString:(PFGeoPoint *)locationTo {
	double distance = 0.0;
	distance = [userGeoPoint distanceInMilesTo:locationTo];
	return [NSString stringWithFormat:@"%.1f miles", distance];
}

- (void)configurePACell:(DiscoverCell *)cell withObject:(PFObject *)object {
	
	if (!object) {
		return;
	}
	
	[cell.pictureView setImage:[UIImage imageNamed:@"activity_icon.png"]];
	
	//Get the PA and the parent group
	PFObject *pa = [object objectForKey:@"proposedActivity"];
	PFObject *group = [object objectForKey:@"group"];
	
	if (pa && group) {
		
		//Incase the data isn't loaded yet
		[pa fetchIfNeeded];
		[group fetchIfNeeded];
		
		PFUser *user = [pa objectForKey:@"creator"];
		[user fetchIfNeeded];
				
		NSString *activity = [NSString stringWithFormat:@"%@ at %@", [group objectForKey:@"activity"], [group objectForKey:@"place"]];
		[cell.activityLabel setAttributedText:[self colorLabelString:activity]];
		[cell.titleLabel setText:[NSString stringWithFormat:@"%@ proposed an activity", [user username]]];
		[cell.milesAwayLabel setText:[self getDistanceAwayString:[group objectForKey:@"location"]]];
		[cell.timeLabel setText:[self stringForDate:[pa updatedAt]]];
		
	}
}

- (void)configurePACommentCell:(DiscoverCell *)cell withObject:(PFObject *)object {
	if (!object) {
		return;
	}
	
	//Get the PA and the parent group
	PFObject *pa = [object objectForKey:@"proposedActivity"];
	PFObject *group = [object objectForKey:@"group"];
	
	if (pa && group) {
		
		[cell setHasComment:YES];
		[cell.commentIndicator setImage:[UIImage imageNamed:@"NewActivityNotification.png"]];
		
		//Incase the data isn't loaded yet
		[pa fetchIfNeeded];
		[group fetchIfNeeded];
		
		PFUser *user = [pa objectForKey:@"creator"];
		[user fetchIfNeeded];
				
		NSString *activity = [NSString stringWithFormat:@"%@ at %@", [group objectForKey:@"activity"], [group objectForKey:@"place"]];
		[cell.activityLabel setAttributedText:[self colorLabelString:activity]];
		[cell.titleLabel setText:[NSString stringWithFormat:@"%@ proposed a group activity", [user username]]];
		[cell.milesAwayLabel setText:[self getDistanceAwayString:[group objectForKey:@"location"]]];
		[cell.timeLabel setText:[self stringForDate:[pa updatedAt]]];
	}
}

- (void)configureGroupCell:(DiscoverCell *)cell withObject:(PFObject *)object memberCount:(int)count {
	if (!object) {
		return;
	}
		
	[cell.titleLabel setText:[NSString stringWithFormat:@"%i people are doing", count]];
	[cell.pictureView setImage:[UIImage imageNamed:@"group_icon.png"]];
	
	//Get the group reference
	PFObject *group = [object objectForKey:@"group"];
	
	if (group) {
		[group fetchIfNeeded];
		
		NSString *activity = [NSString stringWithFormat:@"%@ at %@", [group objectForKey:@"activity"], [group objectForKey:@"place"]];
		[cell.activityLabel setAttributedText:[self colorLabelString:activity]];
		[cell.milesAwayLabel setText:[self getDistanceAwayString:[group objectForKey:@"location"]]];
		[cell.timeLabel setText:[self stringForDate:[group updatedAt]]];
	}
}

- (void)configureNewGroupCell:(DiscoverCell *)cell withObject:(PFObject *)object {
	if (!object) {
		return;
	}
	
	//Get the grour reference and the user that created it
	PFObject *group = [object objectForKey:@"group"];
	PFUser *user = [object objectForKey:@"creator"];
	
	if (group && user) {
		[group fetchIfNeeded];
		[user fetchIfNeeded];
				
		PFFile *pic = [user objectForKey:@"image"];
		
		NSString *activity = [NSString stringWithFormat:@"%@ at %@", [group objectForKey:@"activity"], [group objectForKey:@"place"]];
		[cell.activityLabel setAttributedText:[self colorLabelString:activity]];
		[cell.titleLabel setText:[NSString stringWithFormat:@"%@ is doing", [user username]]];
		[cell.milesAwayLabel setText:[self getDistanceAwayString:[group objectForKey:@"location"]]];
		[cell.timeLabel setText:[self stringForDate:[group updatedAt]]];
		[self imageView:cell.pictureView setImage:pic styled:YES];
		
		[cell setDelegate:self];
		[cell setUser:user];
	}
}

#pragma mark - SortViewDelegate 

- (void)sortView:(SortView *)view didFinishPickingSortCriteria:(NSString *)criteria {
	[view dismiss];
	
	if (![sortCriteria isEqualToString:criteria]) {
		sortCriteria = criteria;
		
		MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
		[self.navigationController.view addSubview:HUD];
		
		HUD.delegate = self;
		HUD.mode = MBProgressHUDModeIndeterminate;
		HUD.labelText = @"Loading...";
		[HUD show:YES];
		
		NSTimeInterval delay = 5.5;
		if ([[FConfig instance] connected]) {
			if ([[FConfig instance] currentNetworkStatus] == ReachableViaWiFi) {
				delay = 3.0;
			}
		}
		
		[HUD hide:YES afterDelay:delay];
		
		[self loadObjects];
	}
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
									   @"You can download it for free in the Apple App Store or in Google Play", @"description",
									   @"Go download this app!",  @"message",
									   nil];
		
		[[SocialSharer sharer] shareWithFacebookUsers:params facebook:[PFFacebookUtils facebook]];
    } else if ([title isEqualToString:@"Twitter"]) {
		
        [[SocialSharer sharer] shareMessageWithTwitter:@"Do physical activities with me using fitivity. Download it for free in the Apple App store or Google Play. Keyword search - fitivity" image:nil link:[NSURL URLWithString:[[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"SMS"]) {
        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"Join our fitivity community to get active with myself and other people interested in pick-up sports, fitness, running, or recreation. You can download it for free in the Apple App Store or in Google Play. %@", [[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"Email"]) {
		NSString *bodyHTML = [NSString stringWithFormat:@"Join our fitivity community to get active with myself and other people interested in pick-up sports, fitness, running, or recreation. You can download it for free in the Apple App Store or in Google Play!<br><br>Download it now in the Apple App Store: <a href=\"%@\">%@</a>", [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"];
		NSData *picture = [NSData dataWithContentsOfFile:path];
		NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys: picture, @"data", @"image/png", @"mimeType", @"FitivityIcon", @"fileName", nil];
		
        [[SocialSharer sharer] shareEmailMessage:bodyHTML title:@"Fitivity App" attachment:data isHTML:YES];
    }
}

#pragma mark - UIAlertView Delegate 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if (!shownAlert && alertView.tag == 2) {
		if ([title isEqualToString:@"Link Now"]) {
			shownAlert = YES;
			[PFFacebookUtils linkUser:[PFUser currentUser] permissions:[[FConfig instance] getFacebookPermissions] block:^(BOOL succeeded, NSError *error) {
				if (succeeded) {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your Fitivity account is now linked with Facebook!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
					
					// Automatically set sharing to on
					[[FConfig instance] setShareGroupPost:YES];
					[[FConfig instance] setSharePAPost:YES];
					[[FConfig instance] setShareChallenge:YES];
				}
				
				if (error) {
					NSString *errorMessage = @"An unknown error occurred while linking with Facebook";
					errorMessage = [error userFriendlyParseErrorDescription:YES];
					
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Link Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
					[alert show];
				}
			}];
		}
	}
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
}

#pragma mark - LoginViewController Delegate

- (void)userLoggedIn {
	if ([self.objects count] == 0) {
		MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
		[self.navigationController.view addSubview:HUD];
		
		HUD.delegate = self;
		HUD.mode = MBProgressHUDModeIndeterminate;
		HUD.labelText = @"Loading...";
		[HUD show:YES];
		[HUD hide:YES afterDelay:3.0];
		
		[self loadObjects];
	}
}

#pragma mark - DiscoverCell Delegate

- (void)showUserProfile:(PFUser *)user {
	[user fetchIfNeeded];
	UserProfileViewController *profile = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil initWithUser:user];
	[self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - PFQueryTableViewController 

- (void)objectsDidLoad:(NSError *)error {
	[super objectsDidLoad:error];
	
	// Use the user's current calendar and time zone
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    [calendar setTimeZone:timeZone];
	
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
	
    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
	
    // Convert back
    NSDate *beginningOfDay = [calendar dateFromComponents:dateComps];
	beginningOfDay = [beginningOfDay dateByAddingTimeInterval:-14400];
	
	PFUser *c = nil;
	todayCells = 0;
	NSDate *temp = nil;
	
	for (PFObject *o in [self objects]) {
		[o fetchInBackgroundWithBlock:nil];
		temp = [o updatedAt];
				
		if ([beginningOfDay compare:temp] == (NSOrderedSame | NSOrderedAscending)) {
			todayCells++;
		}
		
		c = [o objectForKey:@"creator"];
		[c fetch];
		[c objectForKey:@"image"];
	}
	
	[self performSelector:@selector(handleReminders) withObject:nil afterDelay:1.0];
}

// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.className];
	
	// If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
	
	//Need to find all groups/proposed activities that are close by
	PFQuery *innerGroupQuery = [PFQuery queryWithClassName:@"Groups"];
	[innerGroupQuery whereKey:@"location" nearGeoPoint:userGeoPoint withinMiles:kMilesRadius];
	
	if (sortCriteria != nil && ![sortCriteria isEqualToString:@"All Activities"]) {
		[innerGroupQuery whereKey:@"activity" equalTo:sortCriteria];
	}
	
	[query whereKey:@"group" matchesQuery:innerGroupQuery];
    [query orderByDescending:@"updatedAt"];

    return query;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
	static NSString *CellIdentifier = @"Cell";

	DiscoverCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DiscoverCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	[object fetchIfNeeded];
	
	//Get the type of the activity
	int type = [[object objectForKey:@"postType"] integerValue];
	int numberOfMemebers = 0;
	
	if (type == kCellTypeGroup) {
		numberOfMemebers = [[object objectForKey:@"number"] integerValue];
	}
	
	switch (type) {
		case kCellTypeGroup:
			if (numberOfMemebers > 1) {
				[self configureGroupCell:cell withObject:object memberCount:numberOfMemebers];	//Configure for multiple people doing this
			}
			else {
				[self configureNewGroupCell:cell withObject:object];	//New event with only one user
			}
			break;
		case kCellTypePA:
			[self configurePACell:cell withObject:object];
			break;
		case kCellTypeComment:
			[self configurePACommentCell:cell withObject:object];
			break;
		default:
			break;
	}
	
	if ([self happendToday:indexPath.row]) {
		[cell.todayIndicator setHidden:NO];
	}
	else {
		[cell.todayIndicator setHidden:YES];
	}
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
    [label setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_heading_header.png"]]];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setTextColor:[UIColor whiteColor]];
    [label setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
    [label setText:@"Newsfeed"];
   
    [header addSubview:label];
    return header;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
	
	if ([[self objects] count] <= indexPath.row) {
		return;
	}
	
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeText;
	HUD.labelText = @"Loading...";
	[HUD show:YES];
	
	PFObject *object = [self objectAtIndexPath:indexPath];
	
	//Get the data if it hasn't been pulled from the server yet
	[object fetchIfNeeded];
	
	NSString *typeString = [object objectForKey:@"type"];
	int type = ([typeString isEqualToString:@"NORMAL"]) ? kCellTypeGroup : kCellTypePA;
	
	if (!object) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Loading" message:@"Cannot load this activity at this time" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	PFObject *group = [object objectForKey:@"group"];
	[group fetchIfNeeded];
	
	switch (type) {
		case kCellTypeGroup: {
			BOOL challenge = [[FConfig instance] groupHasChallenges:[group objectForKey:@"activity"]];
			PFGeoPoint *point = [group objectForKey:@"location"];
			GooglePlacesObject *place = [[GooglePlacesObject alloc] initWithName:[group objectForKey:@"place"] latitude:point.latitude longitude:point.longitude placeIcon:nil rating:nil vicinity:nil type:nil reference:nil url:nil addressComponents:nil formattedAddress:nil formattedPhoneNumber:nil website:nil internationalPhone:nil searchTerms:nil distanceInFeet:nil distanceInMiles:nil];
			GroupPageViewController *groupPage = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:place
																						 activity:[group objectForKey:@"activity"] challenge:challenge autoJoin:NO];
			[self.navigationController pushViewController:groupPage animated:YES];
			[HUD hide:YES];
			break;
		}
		case kCellTypePA: {
			PFObject *selectedPA = [object objectForKey:@"proposedActivity"];
			[selectedPA fetchIfNeeded];
			ProposedActivityViewController *pa = [[ProposedActivityViewController alloc] initWithNibName:@"ProposedActivityViewController" bundle:nil proposedActivity:selectedPA];
			
			[self.navigationController pushViewController:pa animated:YES];
			[HUD hide:YES];
			break;
		}
		default:
			break;
	}
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - CLLocationManager Delegate

- (BOOL) isValidDistance:(CLLocation *)newLocation oldLocation:(CLLocation *)oldLocation {
    double distance = [newLocation distanceFromLocation:oldLocation] * kMetersToMiles;
    if (distance > .5) {
        return NO;
    }
    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	
	if (![self isValidDistance:newLocation oldLocation:oldLocation]) {
		return;
	}
	
	if (self.loadedInitialData) {
		return;
	}
	
	[[FConfig instance] setMostRecentCoordinate:newLocation.coordinate];
	[locationManager stopUpdatingLocation];
	
	userGeoPoint = [PFGeoPoint geoPointWithLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
	
	if ([self.objects count] == 0) {
		MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
		[self.navigationController.view addSubview:HUD];
		
		HUD.delegate = self;
		HUD.mode = MBProgressHUDModeIndeterminate;
		HUD.labelText = @"Loading...";
		[HUD show:YES];
		[HUD hide:YES afterDelay:3.0];
		
		[self loadObjects];
	}
	
	[self setLoadedInitialData:YES];
	[self.tableView reloadData];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error  {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Find You"
													message:@"We could not find your location. Try again when you are in a better service area" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}


#pragma mark - View Life Cycle

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
		
		if (userGeoPoint == nil) {
			userGeoPoint = [PFGeoPoint geoPoint];
		}
		
		if ([[FConfig instance] connected]) {
			locationManager = [[CLLocationManager alloc] init];
			[locationManager setDesiredAccuracy:kCLLocationAccuracyKilometer];
			[locationManager setDelegate:self];
			[locationManager setPurpose:@"To find activities close to you."];
			[locationManager startUpdatingLocation];
		}
		
		[self setLoadedInitialData:NO];
		
        // The className to query on
        self.className = @"ActivityEvent";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 10;
        
		UIImage *shareApp = [UIImage imageNamed:@"b_share.png"];
        UIImage *shareAppDown = [UIImage imageNamed:@"b_share_down.png"];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:shareApp forState:UIControlStateNormal];
        [button setImage:shareAppDown forState:UIControlStateHighlighted];
        [button addTarget:self action:@selector(shareApp) forControlEvents:UIControlEventTouchUpInside];
        button.frame = CGRectMake(0.0, 0.0, 65.0, 40.0);
        
		UIButton *sortButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[sortButton setImage:[UIImage imageNamed:@"b_sort.png"] forState:UIControlStateNormal];
		[sortButton setImage:[UIImage imageNamed:@"b_sort_down.png"] forState:UIControlStateHighlighted];
		[sortButton addTarget:self action:@selector(showSortPicker) forControlEvents:UIControlEventTouchUpInside];
		sortButton.frame = CGRectMake(0.0, 0.0, 65.0, 40.0);
		
        UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:button];
		UIBarButtonItem *sort = [[UIBarButtonItem alloc] initWithCustomView:sortButton];
        self.navigationItem.leftBarButtonItem = share;
		self.navigationItem.rightBarButtonItem = sort;
		
		sortCriteria = [[FConfig instance] getSortedFeedKey];
		shownAlert = NO;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shownAlert = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
    
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.pngg"]];
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
    self.tableView.separatorColor = [UIColor colorWithRed:178.0/255.0f green:216.0/255.0f blue:254.0/255.0f alpha:1];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
    [locationManager stopUpdatingLocation];
	[locationManager setDelegate:nil];
	locationManager = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
