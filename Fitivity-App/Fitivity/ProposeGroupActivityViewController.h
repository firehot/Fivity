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

#define kMaxCharCount	350

@interface ProposeGroupActivityViewController : UIViewController <UITextFieldDelegate> {
	NSInteger charCount, charLeft;
}

- (IBAction)updateCharCount:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *commentField;

@end
