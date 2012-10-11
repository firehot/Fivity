//
//  CommentCell.h
//  Fitivity
//
//  Created by James Forkey on 8/26/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OHAttributedLabel.h"

@protocol CommentCellDelegate;

@interface CommentCell : UITableViewCell

- (IBAction)showCreator:(id)sender;

@property (nonatomic, assign) id <CommentCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *userPicture;
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *commentMessage;
@property (weak, nonatomic) IBOutlet UILabel *time;
@property (weak, nonatomic) IBOutlet UIImageView *moreIcon;

@end


@protocol CommentCellDelegate <NSObject>

- (void)userWantsProfileAtRow:(NSInteger)row;

@end
