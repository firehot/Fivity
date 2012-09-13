//
//  ProposeGroupActivityViewController.h
//  Fitivity
//
//	Allows a user to either propose an activity or comment on a proposed activity
//
//  Created by Nathaniel Doe on 7/22/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "MBProgressHUD.h"

#define kMaxCharCount	350

@interface CreateProposeActivityViewController : UIViewController <UITextFieldDelegate, MBProgressHUDDelegate> {
	
	PFObject *propActivity;
}

- (IBAction) textFieldDidUpdate:(id)sender;

@property (nonatomic, retain) PFObject *group;

@property (weak, nonatomic) IBOutlet UITextField *commentField;

@end
