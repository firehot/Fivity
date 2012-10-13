//
//  EditProfileViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 10/7/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditProfileViewControllerDelegate;

@interface EditProfileViewController : UIViewController <UITextFieldDelegate>

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *ageField;
@property (weak, nonatomic) IBOutlet UITextField *locationField;
@property (weak, nonatomic) IBOutlet UITextField *occupationField;
@property (weak, nonatomic) IBOutlet UITextField *bioField;
@property (weak, nonatomic) IBOutlet UITextField *workplaceField;

@property (weak, nonatomic) IBOutlet UIToolbar *bar;

@property (nonatomic, assign) id <EditProfileViewControllerDelegate> delegate;

@end

@protocol EditProfileViewControllerDelegate <NSObject>

-(void)userDidUpdateProfile;

@end
