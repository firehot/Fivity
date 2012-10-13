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
#import <QuartzCore/QuartzCore.h>

#import "ProposedActivityCell.h"
#import "GooglePlacesObject.h"
#import "MBProgressHUD.h"

@interface GroupPageViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, ProposedActivityCellDelegate, MBProgressHUDDelegate> {
    BOOL autoJoin, hasChallenge, alreadyJoined, joinFlag, shouldCancel;
	
	NSMutableArray *results;
	
	PFObject *groupMember, *group;
	UIBarButtonItem *joinButton;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)p activity:(NSString *)a challenge:(BOOL)c autoJoin:(BOOL)yn;

- (IBAction)showGroupMap:(id)sender;
- (IBAction)joinGroup:(id)sender;
- (IBAction)proposeGroupActivity:(id)sender;
- (IBAction)showChallenges:(id)sender;
- (IBAction)viewAboutGroup:(id)sender;

@property (nonatomic, retain) GooglePlacesObject *place;
@property (nonatomic, retain) NSString *activity;

@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UITableView *proposedTable;

@end
