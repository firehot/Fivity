//
//  ProposedActivityCell.h
//  Fitivity
//
//  Created by Nathan Doe on 7/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProposedActivityCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *activityMessage;
@property (weak, nonatomic) IBOutlet UILabel *timeAgoLabel;

@end
