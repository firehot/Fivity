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
#import "MBProgressHUD.h"
#import "SortView.h"

@interface DiscoverFeedViewController : PFQueryTableViewController <CLLocationManagerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, DiscoverCellDelegate, LoginViewControllerDelegate, MBProgressHUDDelegate, SortViewDelegate> {
	PFGeoPoint *userGeoPoint;
	
	int todayCells;
	BOOL shownAlert, shownLogin, reloading;
	MBProgressHUD *HUD;
}

- (void)shareApp;
- (void)handlePushNotification:(PFObject *)pa;

@property (nonatomic, retain) LoginViewController *loginView;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) NSString *sortCriteria;
@property (nonatomic, assign) BOOL loadedInitialData;
@property (nonatomic, assign) BOOL cancelLoad;

@end
