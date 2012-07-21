//
//  GroupPageViewController.h
//  Fitivity
//
//  This view shows a certain group and all of the information about it
//
//  Created by Nathaniel Doe on 7/17/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "GooglePlacesObject.h"

@interface GroupPageViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate> {
    BOOL autoJoin, hasChallenge, alreadyJoined;

	PFObject *group;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)p activity:(NSString *)a challenge:(BOOL)c autoJoin:(BOOL)yn;

- (IBAction)showGroupMap:(id)sender;
- (IBAction)joinGroup:(id)sender;
- (IBAction)proposeGroupActivity:(id)sender;

@property (nonatomic, retain) GooglePlacesObject *place;
@property (nonatomic, retain) NSString *activity;

@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UITableView *proposedTable;

@end
