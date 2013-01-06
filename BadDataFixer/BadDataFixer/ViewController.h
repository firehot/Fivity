//
//  ViewController.h
//  BadDataFixer
//
//  Created by Nathan Doe on 11/27/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "MBProgressHUD.h"

@interface ViewController : UIViewController <UIAlertViewDelegate, MBProgressHUDDelegate>

- (IBAction)fixData:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *removeCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *fixButton;
@property (nonatomic, retain) NSMutableArray *acivityEvents;
@property (nonatomic, retain) NSMutableArray *users;
@property (nonatomic, retain) NSMutableArray *groupMembers;
@property (nonatomic, retain) NSMutableArray *pa;
@property (nonatomic, retain) NSMutableArray *comments;
@property (nonatomic, retain) NSMutableArray *reviews;

@end
