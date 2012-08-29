//
//  LoginViewViewController.h
//  Fitivity
//
//  Created by Nathaniel Doe on 7/12/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "SignUpViewController.h"

@interface LoginViewController : UIViewController <UITextFieldDelegate, PF_FBRequestDelegate, SignUpViewControllerDelegate> {
	NSMutableData *profilePictureData;
}

- (IBAction)signUp:(id)sender;
- (IBAction)signIn:(id)sender;
- (IBAction)signInWithFacebook:(id)sender;
- (IBAction)resignSignIn:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookSignUpButton;
@property (weak, nonatomic) IBOutlet UIButton *resignButton;

@end
