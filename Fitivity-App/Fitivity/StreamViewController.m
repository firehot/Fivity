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

@synthesize feedTable;

#pragma mark - Helper Methods

- (void)attemptFeedQuery {
	@synchronized(self) {
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
				[self.feedTable reloadData];
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
    if (distance > .65) {
        return NO;
    }
    return YES;
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
	NSString *typeString = [currentObject objectForKey:@"type"];
	
	int type = ([typeString isEqualToString:@"NORMAL"]) ? kCellTypeGroup : kCellTypePA;
	
	switch (type) {
		case kCellTypeGroup:
			[self configureGroupCell:cell withObject:currentObject];
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
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
	if (![self isValidDistance:newLocation oldLocation:oldLocation]) {
		return;
	}
	
	[locationManager stopUpdatingLocation];
	
	userGeoPoint = [PFGeoPoint geoPointWithLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
	[self attemptFeedQuery];
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
