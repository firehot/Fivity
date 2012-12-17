//
//  ChallengesViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 8/21/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ChallengesViewController : UIViewController <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, retain) NSString *groupType;
@property (nonatomic, retain) NSString *groupLocation;
@property (nonatomic, retain) NSMutableArray *challenges;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil groupType:(NSString *)type groupLocation:(NSString *)location;

@end
