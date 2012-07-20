//
//  SettingsCell.h
//  Fitivity
//
//  Created by Nathaniel Doe on 7/19/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *categoryLabel;
@property (weak, nonatomic) IBOutlet UILabel *informationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *pictureView;

@end
