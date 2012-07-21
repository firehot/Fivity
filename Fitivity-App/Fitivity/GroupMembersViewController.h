//
//  GroupMembersViewController.h
//  Fitivity
//
//  Created by Nathaniel Doe on 7/21/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "GooglePlacesObject.h"

@interface GroupMembersViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	NSArray *members;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)p activity:(NSString *)a;

@property (weak, nonatomic) IBOutlet UITableView *membersTable;
@property (nonatomic, retain) GooglePlacesObject *place;
@property (nonatomic, retain) NSString *activity;

@end
