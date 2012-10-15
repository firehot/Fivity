//
//  ChallengeOverviewViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 9/3/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ChallengeOverviewViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
	PFObject *day;
	NSArray *objects;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil day:(PFObject *)d title:(NSString *)title;

@property (weak, nonatomic) IBOutlet UITableView *exerciseTable;
@property (weak, nonatomic) IBOutlet UITextView *overview;

@end
