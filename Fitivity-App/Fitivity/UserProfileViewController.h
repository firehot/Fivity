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

#define kHeaderHeight		40

@interface UserProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, PF_FBRequestDelegate> {
	PFUser *userProfile;
	
	NSMutableArray *groupResults;
	NSMutableData *profilePictureData;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil initWithUser:(PFUser *)user;
- (IBAction)enlargePicture:(id)sender;

@property (nonatomic, getter = isMainUser) BOOL mainUser;

@property (nonatomic, retain) PFUser *userProfile;
@property (weak, nonatomic) IBOutlet UITableView *groupsTable;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *userPicture;

@end

