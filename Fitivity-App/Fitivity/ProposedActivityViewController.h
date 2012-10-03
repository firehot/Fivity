//
//  ProposedActivityViewController.h
//  Fitivity
//
//	Displays all comments/activity within the proposed activity
//
//  Created by Nathan Doe on 7/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#import "ProposedActivityCell.h"
#import "OHAttributedLabel.h"
#import "MBProgressHUD.h"
#import "CommentCell.h"

@interface ProposedActivityViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MBProgressHUDDelegate, ProposedActivityCellDelegate, CommentCellDelegate> {
	NSMutableArray *results;
	
	BOOL posting, autoJoined;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil proposedActivity:(PFObject *)pa;
- (IBAction) textFieldDidUpdate:(id)sender;
- (IBAction)showHeaderMessage:(id)sender;
- (IBAction)showPostCreator:(id)sender;
- (IBAction)postImIn:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *activityHeader;
@property (weak, nonatomic) IBOutlet UIImageView *creatorPicture;
@property (weak, nonatomic) IBOutlet UILabel *creatorName;
@property (weak, nonatomic) IBOutlet UILabel *activityMessage;
@property (weak, nonatomic) IBOutlet UILabel *activityCreateTime;
@property (weak, nonatomic) IBOutlet UILabel *placeLabel;
@property (weak, nonatomic) IBOutlet UIButton *inButton;
@property (weak, nonatomic) IBOutlet UIImageView *moreIcon;

@property (strong, nonatomic) IBOutlet UIView *activityFooter;
@property (weak, nonatomic) IBOutlet UITextField *activityComment;

@property (weak, nonatomic) IBOutlet UITableView *commentsTable;
@property (nonatomic, retain) PFObject *parent;

@end
