//
//  DiscoverCell.h
//  Fitivity
//
//  Created by Nathaniel Doe on 7/16/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "OHAttributedLabel.h"

@protocol DiscoverCellDelegate;

@interface DiscoverCell : PFTableViewCell

- (IBAction)showUserProfile:(id)sender;

@property (nonatomic, assign) id <DiscoverCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *milesAwayLabel;
@property (weak, nonatomic) IBOutlet PFImageView *pictureView;
@property (weak, nonatomic) IBOutlet UIImageView *todayIndicator;
@property (nonatomic, retain) PFUser *user;

@end

@protocol DiscoverCellDelegate <NSObject>

- (void)showUserProfile:(PFUser *)user;

@end