//
//  GroupPageViewController.h
//  Fitivity
//
//  This view shows a certain group and all of the information about it
//
//  Created by Nathaniel Doe on 7/17/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "GooglePlacesObject.h"

@interface GroupPageViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    BOOL autoJoin;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)p activity:(NSString *)a;

- (BOOL)isAutoJoin;
- (void)setAutoJoin:(BOOL)join;

@property (nonatomic, retain) GooglePlacesObject *place;
@property (nonatomic, retain) NSString *activity;

@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UITableView *proposedTable;

@end
