//
//  GroupMembersCell.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/21/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "GroupMembersCell.h"

@implementation GroupMembersCell

@synthesize userNameLabel;
@synthesize userPhoto;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
