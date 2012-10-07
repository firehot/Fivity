//
//  UserProfileViewController.h
//  Fitivity
//
//	Displays a users Fitivity profile
//
//  Created by Nathaniel Doe on 7/14/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#import "MBProgressHUD.h"
#import "EditProfileViewController.h"

#define kHeaderHeight		40

@interface UserProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, EditProfileViewControllerDelegate, MBProgressHUDDelegate> {
	PFUser *userProfile;
	
	NSMutableArray *groupResults;
	NSMutableDictionary *updatedGroups;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil initWithUser:(PFUser *)user;
- (IBAction)enlargePicture:(id)sender;
- (IBAction)updateViews:(id)sender;

@property (nonatomic, getter = isMainUser) BOOL mainUser;

@property (nonatomic, retain) IBOutlet UIView *groupsView;
@property (nonatomic, retain) IBOutlet UIView *aboutMeView;
@property (weak, nonatomic) IBOutlet UIView *displayView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;

@property (nonatomic, retain) PFUser *userProfile;
@property (weak, nonatomic) IBOutlet UITableView *groupsTable;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userAgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *userOcupationLabel;
@property (weak, nonatomic) IBOutlet UILabel *userHometownLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UITextView *userBioView;
@property (strong, nonatomic) IBOutlet PF_FBProfilePictureView *facebookProfilePicture;

@end

