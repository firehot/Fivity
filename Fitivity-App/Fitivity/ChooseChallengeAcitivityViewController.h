//
//  ChooseChallengeAcitivityViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 12/21/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ChooseChallengeAcitivityViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *activityTable;

@end
