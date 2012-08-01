//
//  ProposedActivityCell.m
//  Fitivity
//
//  Created by Nathan Doe on 7/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ProposedActivityCell.h"

@implementation ProposedActivityCell

@synthesize userPicture;
@synthesize userName;
@synthesize activityMessage;
@synthesize timeAgoLabel;
@synthesize notificationImage;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
