//
//  LoginViewViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/12/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "LoginViewController.h"
#import "SignUpViewController.h"
#import "NSError+FITParseUtilities.h"

#define kTextFieldMoveDistance          50
#define kTextFieldAnimationDuration    0.3f

@interface LoginViewController ()

@end

@implementation LoginViewController

@synthesize delegate;
@synthesize userNameField;
@synthesize passwordField;
@synthesize signUpButton;
@synthesize signInButton;
@synthesize facebookSignUpButton;
@synthesize resignButton;

#pragma mark - Helper Methods 

- (void)clearInput {
	[self.userNameField setText:@""];
	[self.passwordField setText:@""];
}

- (void)requestFacebookData {
	
	// Create request for user's facebook data
    NSString *requestPath = @"me/?fields=name,email,picture&type=large";
    
    // Send request to facebook
    [[PFFacebookUtils facebook] requestWithGraphPath:requestPath andDelegate:self];
}

#pragma mark - Facebook Delegate

-(void)request:(PF_FBRequest *)request didLoad:(id)result {
    NSDictionary *userData = (NSDictionary *)result; // The result is a dictionary
	
	if (userData) {
		PFUser *current = [PFUser currentUser];
		[current setUsername:[userData objectForKey:@"name"]];
		[current setEmail:[userData objectForKey:@"email"]];
		[current save];
		
		profilePictureData = [[NSMutableData alloc] init];
		NSString *picURL = [(NSDictionary *)[(NSDictionary *)[userData objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"];
		NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:picURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2];
		
		[NSURLConnection connectionWithRequest:urlRequest delegate:self];
	}
}

#pragma mark - NSURLConnectioin Delegate

// Called every time a chunk of the data is received
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [profilePictureData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
	
	//Upload to parse for future use
	PFFile *imageFile = [PFFile fileWithData:profilePictureData];
	[imageFile save];
	
	PFUser *user = [PFUser currentUser];
	[user setObject:imageFile forKey:@"image"];
	[user save];
	
}

#pragma mark - IBActions

- (IBAction)signUp:(id)sender {
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to the internet to sign up!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		
		return;
	}
	
	SignUpViewController *signUpView = [[SignUpViewController alloc] initWithNibName:@"SignUpViewController" bundle:nil];
    [signUpView setDelegate:self];
	[self presentModalViewController:signUpView animated:YES];
	[self clearInput];
}

- (IBAction)signIn:(id)sender {
	@synchronized(self) {
		if (![[FConfig instance] connected]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to the internet to sign in!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			
			return;
		}
		
		NSString *username = [[self.userNameField text] lowercaseString];
		NSString *password = [self.passwordField text];
		if (username && password) {
			if ([username length] > 0 && [password length] > 0) {
				[PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
					if (error || !user) {
						NSString *errorMessage = @"Could not login due to unknown error.";
						if (error) {
							errorMessage = [error userFriendlyParseErrorDescription:YES];
						}
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
						[alert show];
					}
					else {
						//Logged in successfully
						[delegate userLoggedIn];
						[self dismissModalViewControllerAnimated:YES];
					}
				}];
			}
		}
	}
}

- (IBAction)signInWithFacebook:(id)sender {
	@synchronized(self) {
		if (![[FConfig instance] connected]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to the internet to sign up!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			
			return;
		}
		
		NSArray *permissionsArray = [NSArray arrayWithObjects:@"user_about_me", @"user_location", @"email", @"publish_stream", @"offline_access", nil];
		
		[PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error){
			if (error || !user) {
				NSString *errorMessage = @"Couldn't login due to unknown error.";
				if (error) {
					errorMessage = [error userFriendlyParseErrorDescription:YES];
				}
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			}
			else {
				if (user.isNew) {
					NSLog(@"New User");
					[self requestFacebookData];
					//[self performSelectorInBackground:@selector(requestFacebookData) withObject:nil];
				}
				
			 //Logged in successfully 
			 [self dismissModalViewControllerAnimated:YES];
		 }
		}];

	}
}

- (IBAction)resignSignIn:(id)sender {
    [userNameField resignFirstResponder];
    [passwordField resignFirstResponder];
}

#pragma mark - SignUpViewController Delegate

//User canceled the signup process. Don't want to let them move on 
//until they sign up/in
-(void)userCancledSignUp:(SignUpViewController *)view {
    [self dismissModalViewControllerAnimated:YES];
}

//User successfully signed up, log them in and then load discover screen
-(void)userSignedUpSuccessfully:(SignUpViewController *)view {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"signedIn" object:self];
	[delegate userLoggedIn];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITextField Delegate 

//Move the text fields up so that the keyboard does not cover them
- (void) animateTextField:(UITextField*)textField Up:(BOOL)up {
    
    int movement = (up ? -kTextFieldMoveDistance : kTextFieldMoveDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: kTextFieldAnimationDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	if ([textField isEqual:passwordField]) {
		[self signIn:nil];
	}
	
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self animateTextField:textField Up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self animateTextField:textField Up:NO];
}

#pragma mark - view lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	[signInButton setImage:[UIImage imageNamed:@"b_sign_in_login_down.png"] forState:UIControlStateHighlighted];
	[signUpButton setImage:[UIImage imageNamed:@"b_sign_up_login_down.png"] forState:UIControlStateHighlighted];
	 
}

- (void)viewDidUnload {
	[self setUserNameField:nil];
	[self setPasswordField:nil];
	[self setSignUpButton:nil];
	[self setSignInButton:nil];
	[self setFacebookSignUpButton:nil];
    [self setResignButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
