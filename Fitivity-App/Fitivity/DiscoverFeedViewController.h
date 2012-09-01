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

#import "LoginViewController.h"
#import "DiscoverCell.h"

@interface DiscoverFeedViewController : PFQueryTableViewController <CLLocationManagerDelegate, UIActionSheetDelegate, DiscoverCellDelegate, LoginViewControllerDelegate> {
	PFGeoPoint *userGeoPoint;
}

- (void)shareApp;

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL loadedInitialData;

@end
