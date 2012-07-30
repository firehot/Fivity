//
//  StreamViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/11/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "StreamViewController.h"
#import "DiscoverCell.h"
#import "OHAttributedLabel.h"
#import "NSAttributedString+Attributes.h"
#import "GooglePlacesObject.h"
#import "GroupPageViewController.h"
#import "ProposedActivityViewController.h"

#define kFeedLimit			20
#define kCellHeight			92.0f

#define kCellTypeGroup		0
#define kCellTypePA			1
#define kCellTypeComment	2

#define kMetersToMiles		0.000621371192
#define kMilesRadius		100.0

@interface StreamViewController ()

@end

@implementation StreamViewController

#pragma mark - Helper Methods

- (void)attemptFeedQuery {
	@synchronized(self) {
		alreadyLoading = YES;
		
		//Need to find all groups/proposed activities that are close by
		PFQuery *innerGroupQuery = [PFQuery queryWithClassName:@"Groups"];
		[innerGroupQuery whereKey:@"location" nearGeoPoint:userGeoPoint withinMiles:kMilesRadius];
				
		PFQuery *query = [PFQuery queryWithClassName:@"ActivityEvent"];
		[query whereKey:@"group" matchesQuery:innerGroupQuery];
		[query addDescendingOrder: @"createdAt"];
		[query setLimit:kFeedLimit];
		[query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
			if (error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Load Error" message:@"Could not load your feed." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			else {
				fetchedQueryItems = [[NSMutableArray alloc] initWithArray:results];
				[self.tableView reloadData];
				alreadyLoading = NO;
			}
		}];
	}
}

- (void)imageView:(UIImageView *)imgView setImage:(PFFile *)imageFile styled:(BOOL)styled {
	NSData *picData = [imageFile getData];
	
	if (picData) {
		[imgView setImage:[UIImage imageWithData:picData]];
	}
	else {
		[imgView setImage:[UIImage imageNamed:@"FeedCellProfilePlaceholderPicture.png"]];
	}
	
	if (styled) {
		//Style user photo
		[imgView.layer setCornerRadius:10.0f];
		[imgView.layer setMasksToBounds:YES];
		[imgView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
		[imgView.layer setBorderWidth:4];
	}
}


- (NSAttributedString *)colorLabelString:(NSString *)string {
	NSArray *components = [string componentsSeparatedByString:@" at "];
	NSMutableAttributedString *attrStr = [NSMutableAttributedString attributedStringWithString:string];
	[attrStr setTextColor:[UIColor whiteColor]];
	[attrStr setFont:[UIFont fontWithName:@"Helvetica" size:14]];
	
	// now we change the color of the activity & location
	[attrStr setTextColor:[UIColor blueColor] range:[string rangeOfString:[components objectAtIndex:0]]];
	[attrStr setTextColor:[UIColor yellowColor] range:[string rangeOfString:[components objectAtIndex:1]]];
	
	return attrStr;
}

- (NSString *)stringForDate:(NSDate *)date {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"hh:mm a M/dd"];
	return [formatter stringFromDate:date];
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
	
	//Get the PA and the parent group 
	PFObject *pa = [object objectForKey:@"proposedActivity"];
	PFObject *group = [object objectForKey:@"group"];
	
	if (pa && group) {
		
		//Incase the data isn't loaded yet
		[pa fetchIfNeeded];
		[group fetchIfNeeded];
		
		PFUser *user = [pa objectForKey:@"creator"];
		[user fetchIfNeeded];
		
		PFFile *pic = [user objectForKey:@"image"];
		
		[cell.titleLabel setText:[NSString stringWithFormat:@"%@ proposed a group activity", [user username]]];
		[cell.activityLabel setText:[NSString stringWithFormat:@"at %@", [group objectForKey:@"place"]]];
		[cell.milesAwayLabel setText:[self getDistanceAwayString:[group objectForKey:@"location"]]];
		[cell.timeLabel setText:[self stringForDate:[pa updatedAt]]];
		[self imageView:cell.pictureView setImage:pic styled:YES];
	}
}

- (void)configureGroupCell:(DiscoverCell *)cell withObject:(PFObject *)object {
	if (!object) {
		return;
	}
	
	int numberOfMembers = [[object objectForKey:@"number"] integerValue];
	
	[cell.titleLabel setText:[NSString stringWithFormat:@"%i people are doing", numberOfMembers]];
	[cell.pictureView setImage:[UIImage imageNamed:@"FeedCellActiveGroupActivityIconImage.png"]];
	
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
	}
}

- (void)configureCommentCell:(DiscoverCell *)cell withObject:(PFObject *)object {
	if (!object) {
		return;
	}
}

- (BOOL) isValidDistance:(CLLocation *)newLocation oldLocation:(CLLocation *)oldLocation {
    double distance = [newLocation distanceFromLocation:oldLocation] * kMetersToMiles;
    if (distance > .5) {
        return NO;
    }
    return YES;
}

#pragma mark - PullToRefresh

- (void)reloadTableViewDataSource {
    
    [self attemptFeedQuery];
    
	[super performSelector:@selector(dataSourceDidFinishLoadingNewData) withObject:nil afterDelay:3.0];
}

- (void)dataSourceDidFinishLoadingNewData {
    [refreshHeaderView setCurrentDate];  //  should check if data reload was successful
    [super dataSourceDidFinishLoadingNewData];
}

#pragma mark - UITableViewDelegate 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    DiscoverCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DiscoverCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
    
	PFObject *currentObject = [fetchedQueryItems objectAtIndex:indexPath.row];
	[currentObject fetchIfNeeded];
	
	//Get the type of the activity
	NSString *typeString = [currentObject objectForKey:@"type"];
	int type = ([typeString isEqualToString:@"NORMAL"]) ? kCellTypeGroup : kCellTypePA;
	int numberOfMemebers = 0;
	
	if (type == kCellTypeGroup) {
		numberOfMemebers = [[currentObject objectForKey:@"number"] integerValue];
	}
	
	switch (type) {
		case kCellTypeGroup:
			if (numberOfMemebers > 1) {
				[self configureGroupCell:cell withObject:currentObject];	//Configure for multiple people doing this
			}
			else {
				[self configureNewGroupCell:cell withObject:currentObject];	//New event with only one user
			}
			break;
		case kCellTypePA:
			[self configurePACell:cell withObject:currentObject];
			break;
		default: {
			NSString *text = @"Basketball at YMCA";
			NSMutableAttributedString *attrStr = [NSMutableAttributedString attributedStringWithString:text];
			[attrStr setTextColor:[UIColor whiteColor]];
			[attrStr setFont:[UIFont fontWithName:@"Helvetica" size:14]];
			
			// now we change the color of the activity & location
			[attrStr setTextColor:[UIColor blueColor] range:[text rangeOfString:@"Basketball"]];
			[attrStr setTextColor:[UIColor yellowColor] range:[text rangeOfString:@"YMCA"]];
			cell.activityLabel.attributedText = attrStr;
			
			[cell.pictureView setImage:[UIImage imageNamed:@"FeedCellActiveGroupActivityIconImage.png"]];
			[cell.timeLabel setText:@"3:45 PM"];
			[cell.titleLabel setText:@"6 people are doing"];
			[cell.milesAwayLabel setText:@"3.4 Miles"];
			break;
		}
	}
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [fetchedQueryItems count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1; 
}

#pragma mark - UITableViewDataSource 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PFObject *object = [fetchedQueryItems objectAtIndex:indexPath.row];
	
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
			PFGeoPoint *point = [group objectForKey:@"location"];
			GooglePlacesObject *place = [[GooglePlacesObject alloc] initWithName:[group objectForKey:@"place"] latitude:point.latitude longitude:point.longitude placeIcon:nil rating:nil vicinity:nil type:nil reference:nil url:nil addressComponents:nil formattedAddress:nil formattedPhoneNumber:nil website:nil internationalPhone:nil searchTerms:nil distanceInFeet:nil distanceInMiles:nil];
			GroupPageViewController *groupPage = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:place
																						 activity:[group objectForKey:@"activity"] challenge:NO autoJoin:NO];
			[self.navigationController pushViewController:groupPage animated:YES];
			break;
		}
		case kCellTypePA: {
			PFObject *selectedPA = [object objectForKey:@"proposedActivity"];
			[selectedPA fetchIfNeeded];
			ProposedActivityViewController *pa = [[ProposedActivityViewController alloc] initWithNibName:@"ProposedActivityViewController" bundle:nil proposedActivity:selectedPA];
			
			[self.navigationController pushViewController:pa animated:YES];
			break;
		}
		default:
			break;
	}
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
	if (![self isValidDistance:newLocation oldLocation:oldLocation]) {
		return;
	}
	
	[locationManager stopUpdatingLocation];
	
	userGeoPoint = [PFGeoPoint geoPointWithLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
	
	if (!alreadyLoading) {
		[self attemptFeedQuery];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error  {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Find You"
													message:@"We could not find your location. Try again when you are in a better service area" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}


#pragma mark - 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
		alreadyLoading = NO;
		
		if ([[FConfig instance] connected]) {
			locationManager = [[CLLocationManager alloc] init];
			[locationManager setDesiredAccuracy:kCLLocationAccuracyKilometer];
			[locationManager setDelegate:self];
			[locationManager setPurpose:@"To find activities close to you."];
			[locationManager startUpdatingLocation];
		}
	}
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
		
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
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
