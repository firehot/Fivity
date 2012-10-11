//
//  ProposedActivityCell.h
//  Fitivity
//
//  Created by Nathan Doe on 7/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OHAttributedLabel.h"

@protocol ProposedActivityCellDelegate;

@interface ProposedActivityCell : UITableViewCell

- (IBAction)showCreator:(id)sender;

@property (nonatomic, assign) id <ProposedActivityCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *activityMessage;
@property (weak, nonatomic) IBOutlet UILabel *timeAgoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *notificationImage;
@property (weak, nonatomic) IBOutlet UIImageView *moreIcon;

@end

@protocol ProposedActivityCellDelegate <NSObject>

- (void)userWantsProfileAtRow:(NSInteger)row;

@end