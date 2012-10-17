//
//  SecondChallengeCell.m
//  Fitivity
//
//  Created by Nathan Doe on 10/17/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "SecondChallengeCell.h"

@implementation SecondChallengeCell

@synthesize exerciseLabel, amountLabel;

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
