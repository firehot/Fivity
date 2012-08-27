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

#import "DiscoverCell.h"

@interface DiscoverFeedViewController : PFQueryTableViewController <CLLocationManagerDelegate, DiscoverCellDelegate> {
	PFGeoPoint *userGeoPoint;
}

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL loadedInitialData;

@end
