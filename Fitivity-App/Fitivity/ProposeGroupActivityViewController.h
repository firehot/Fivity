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

#define kMaxCharCount	350

@interface ProposeGroupActivityViewController : UIViewController <UITextFieldDelegate> {
	BOOL isCommentView;
	
	PFObject *propActivity;
}

- (IBAction) textFieldDidUpdate:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil isComment:(BOOL)comment;

@property (nonatomic, retain) PFObject *proposedActivity;
@property (nonatomic, retain) PFObject *group;

@property (weak, nonatomic) IBOutlet UITextField *commentField;

@end
