//
//  SettingsCell.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/19/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "SettingsCell.h"

@implementation SettingsCell
@synthesize categoryLabel;
@synthesize informationLabel;

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
