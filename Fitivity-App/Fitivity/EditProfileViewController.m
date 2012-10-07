//
//  EditProfileViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 10/7/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "EditProfileViewController.h"

@interface EditProfileViewController ()

@end

@implementation EditProfileViewController

@synthesize ageField,nameField,locationField,occupationField,bioField;
@synthesize delegate;	

#pragma mark - IBAction's

- (IBAction)cancel:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
	
	PFUser *user = [PFUser currentUser];
	[user setUsername:nameField.text];
	[user setObject:locationField.text forKey:@"hometown"];
	[user setObject:[NSNumber numberWithInt:[ageField.text integerValue]] forKey:@"age"];
	[user setObject:occupationField.text forKey:@"occupation"];
	[user setObject:bioField.text forKey:@"bio"];
	
	if (![user save]) {
		[user saveEventually];
	}
	
	if ([delegate respondsToSelector:@selector(userDidUpdateProfile)]) {
		[delegate userDidUpdateProfile];
	}
	
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	return YES;
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

	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	
	PFUser *user = [PFUser currentUser];
	[nameField setText:[user username]];
	[ageField setText:[NSString stringWithFormat:@"%i", [[user objectForKey:@"age"] integerValue]]];
	[locationField setText:[user objectForKey:@"hometown"]];
	[occupationField setText:[user objectForKey:@"occupation"]];
	[bioField setText:[user objectForKey:@"bio"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[self setNameField:nil];
	[self setAgeField:nil];
	[self setLocationField:nil];
	[self setOccupationField:nil];
	[self setBioField:nil];
	[super viewDidUnload];
}

@end
