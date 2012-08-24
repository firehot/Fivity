//
//  ChallengeCell.h
//  Fitivity
//
//  Created by Nathan Doe on 8/21/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChallengeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *description;
@property (weak, nonatomic) IBOutlet UIImageView *challengePicture;

@end