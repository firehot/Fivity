//
//  ChooseChallengeAcitivityViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 12/21/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "ChooseLocationViewController.h"

@interface ChooseChallengeAcitivityViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, ChooseLocationViewControllerDelegate, MBProgressHUDDelegate>

@property (weak, nonatomic) IBOutlet UITableView *activityTable;
@property (nonatomic, retain) ChooseLocationViewController *chooseLocationView;
@property (nonatomic, retain) NSMutableArray *activities;
@property (nonatomic, retain) NSString *selectedActivity;
@property (nonatomic, retain) GooglePlacesObject *selectedPlace;
@property (nonatomic, retain) PFObject *groupRef;

@end
