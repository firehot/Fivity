//
//  DiscoverFeedViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 8/8/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import <QuartzCore/QuartzCore.h>

@interface DiscoverFeedViewController : PFQueryTableViewController <CLLocationManagerDelegate> {
	PFGeoPoint *userGeoPoint;
}

@property (nonatomic, retain) CLLocationManager *locationManager;

@end
