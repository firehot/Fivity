//
//  DiscoverCell.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/16/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "DiscoverCell.h"

@implementation DiscoverCell

@synthesize titleLabel;
@synthesize activityLabel;
@synthesize timeLabel;
@synthesize milesAwayLabel;
@synthesize pictureView;
@synthesize todayIndicator;
@synthesize user;
@synthesize delegate;

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

- (IBAction)showUserProfile:(id)sender {
	if ([delegate respondsToSelector:@selector(showUserProfile:)]) {
		[delegate showUserProfile:self.user];
	}
}

@end
