//
//  EditProfileViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 10/7/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "EditProfileViewController.h"

#define kTextFieldAnimationDuration			0.25

@interface EditProfileViewController ()

@end

@implementation EditProfileViewController

@synthesize ageField,workplaceField,locationField,occupationField,bioField;
@synthesize bar;
@synthesize delegate;	

#pragma mark - IBAction's

- (IBAction)cancel:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
	
	PFUser *user = [PFUser currentUser];
	
	if (locationField.text != nil) {
		[user setObject:locationField.text forKey:@"hometown"];
	}
	if (ageField.text != nil) {
		[user setObject:[NSNumber numberWithInt:[ageField.text integerValue]] forKey:@"age"];
	}
	if (occupationField.text != nil) {
		[user setObject:occupationField.text forKey:@"occupation"];
	}
	if (bioField.text != nil) {
		[user setObject:bioField.text forKey:@"bio"];
	}
	if (workplaceField.text != nil) {
		[user setObject:workplaceField.text forKey:@"workPlace"];
	}
	
	[user saveInBackground];
	
	if ([delegate respondsToSelector:@selector(userDidUpdateProfile)]) {
		[delegate userDidUpdateProfile];
	}
	
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextField Delegate

//Move the text fields up so that the keyboard does not cover them
- (void) animateTextField:(UITextField*)textField Up:(BOOL)up distance:(int)distance {
    
    int movement = (up ? -distance : distance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: kTextFieldAnimationDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	int distance = 0;
	
	if (textField == ageField || textField == locationField || textField == occupationField) {
		distance = 0;
	} else if (textField == workplaceField) {
		distance = 70;
	} else if (textField == bioField) {
		distance = 140;
	}
	
	[self animateTextField:textField Up:YES distance:distance];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
	int distance = 0;
	
	if (textField == ageField || textField == locationField || textField == occupationField) {
		distance = 0;
	} else if (textField == workplaceField) {
		distance = 70;
	} else if (textField == bioField) {
		distance = 140;
	}
	
	[self animateTextField:textField Up:NO distance:distance];
}

#pragma mark - View Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_main_group.png"]]];
	[bar setTintColor:[[FConfig instance] getFitivityBlue]];
	
	PFUser *user = [PFUser currentUser];
	[ageField setText:[NSString stringWithFormat:@"%i", [[user objectForKey:@"age"] integerValue]]];
	[locationField setText:[user objectForKey:@"hometown"]];
	[occupationField setText:[user objectForKey:@"occupation"]];
	[bioField setText:[user objectForKey:@"bio"]];
	[workplaceField setText:[user objectForKey:@"workPlace"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[self setAgeField:nil];
	[self setLocationField:nil];
	[self setOccupationField:nil];
	[self setBioField:nil];
    [self setBar:nil];
    [self setWorkplaceField:nil];
	[super viewDidUnload];
}

@end
