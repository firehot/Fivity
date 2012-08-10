//
//  AddLocationHomeViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 8/8/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "AddLocationHomeViewController.h"
#import "AddLocationViewController.h"

#define kTextFieldMoveDistance          120
#define kTextFieldAnimationDuration    0.3f

@interface AddLocationHomeViewController ()

@end

@implementation AddLocationHomeViewController

@synthesize nameField;
@synthesize addressField;
@synthesize cityField;
@synthesize stateField;
@synthesize zipField;

#pragma mark - AddLocationViewController Delegate

- (void)userDidSelectLocation:(NSDictionary *)addressInfo {
	//Update GUI
	[addressField setText:[addressInfo objectForKey:@"address"]];
	[cityField setText:[addressInfo objectForKey:@"city"]];
	[stateField setText:[addressInfo objectForKey:@"state"]];
	[zipField setText:[addressInfo objectForKey:@"zip_code"]];
	
	[self.navigationController popViewControllerAnimated:YES];
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
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	if ([textField isEqual:cityField] || [textField isEqual:zipField] || [textField isEqual:stateField]) {
		[self animateTextField:textField Up:YES];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if ([textField isEqual:cityField] || [textField isEqual:zipField] || [textField isEqual:stateField]) {
		[self animateTextField:textField Up:NO];
	}
}

#pragma mark - GooglePlacesConnection Delegate 

- (void) googlePlacesConnectionDidFinishSendingNewPlace:(GooglePlacesConnection *)conn {
	[self.navigationController popViewControllerAnimated:YES];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"A new place has been created" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];	
}

#pragma mark - View Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil currentLocation:(CLLocationCoordinate2D)c {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        coordinate = c;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload {
	[self setNameField:nil];
	[self setAddressField:nil];
	[self setCityField:nil];
	[self setStateField:nil];
	[self setZipField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)addFromMap:(id)sender {
	AddLocationViewController *add = [[AddLocationViewController alloc] initWithNibName:@"AddLocationViewController" bundle:nil location:coordinate];
	[add setDelegate:self];
	[self.navigationController pushViewController:add animated:YES];
}

- (IBAction)submitNewLocation:(id)sender {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected!" message:@"You must be online to create a new place!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	//Make sure that they didn't leave any fields empty
	BOOL empty = NO;
	for (UITextField *t in [self.view subviews]) {
		if ([t.text isEqualToString:@""]) {
			empty = YES;
		}
	}
	
	if (empty) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty Field!" message:@"You must fill in ALL of the fields in order to create a place" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	__block GooglePlacesConnection *googlePlacesConnection = [[GooglePlacesConnection alloc] initWithDelegate:self];
	
	//Create the data for googles API call
	//https://developers.google.com/places/documentation/#PlaceSearches
	
	CLGeocoder *geo = [[CLGeocoder alloc] init];
	[geo geocodeAddressString:@"" completionHandler:^(NSArray *placemarks, NSError *error){
	
		if (!placemarks) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to create place for this address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			return;
		}
		
		CLPlacemark *placemark = [placemarks objectAtIndex:0];
		
		NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
		[data setObject:[nameField text] forKey:@"name"];
		NSDictionary *location = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithDouble:placemark.location.coordinate.latitude], @"lat",
								  [NSNumber numberWithDouble:placemark.location.coordinate.longitude], @"lng", nil];
		[data setObject:location forKey:@"location"];
		[data setObject:@"" forKey:@"types"];
		[data setObject:@"" forKey:@"accuracy"];
		
		//send the new place
		[googlePlacesConnection sendNewGooglePlace:nil];
	}];
}

- (IBAction)hideKeyboard:(id)sender {
	for (UITextField *t in [self.view subviews]) {
		[t resignFirstResponder];
	}
}

@end
