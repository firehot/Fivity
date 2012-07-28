//
//  StreamViewController.h
//  Fitivity
//
//  Shows the users discovery stream 
//
//  Created by Nathaniel Doe on 7/11/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>

@interface StreamViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate> {
	
	NSMutableArray *fetchedQueryItems;
	
	CLLocationManager *locationManager;
	PFGeoPoint *userGeoPoint;
}

@property (nonatomic, retain) IBOutlet UITableView *feedTable;
@property (nonatomic, retain) CLLocationManager *locationManager;

@end
