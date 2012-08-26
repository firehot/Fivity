//
//  CommentCell.m
//  Fitivity
//
//  Created by James Forkey on 8/26/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import "CommentCell.h"

@implementation CommentCell

@synthesize delegate;
@synthesize userPicture;
@synthesize userName;
@synthesize time;
@synthesize commentMessage;

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

- (IBAction)showCreator:(id)sender {
if ([delegate respondsToSelector:@selector(userWantsProfileAtRow:)]) {
    [delegate userWantsProfileAtRow:self.tag];
}
}

@end