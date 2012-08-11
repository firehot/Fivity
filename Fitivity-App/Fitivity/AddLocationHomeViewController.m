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

@synthesize submitButton;
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

#pragma mark - GooglePlaceAdder Delegate 

- (void) didFinishSendingNewPlace:(NSDictionary *)ref {
	
	//Allow to submit again
	self.submitButton.enabled = YES;
	
	//Reset textfields
	for (UITextField *o in [self.view subviews]) {
		if ([o isKindOfClass:[UITextField class]]) {
			o.text = @"";
		}
	}
	
	NSString *status = [ref objectForKey:@"status"];
	NSString *title = @"";
	NSString *message = @"";
	
	//Check the status of the request
	if ([status isEqualToString:@"OK"]) {
		title = @"Success!";
		message = @"Your place has been created and can now be searched for.";
	} else if ([status isEqualToString:@"OVER_QUERY_LIMIT"]) {
		title = @"Out of Licenses";
		message = @"We are currently running low on licenses =0 try again later to create this place";
	} else if ([status isEqualToString:@"REQUEST_DENIED"]) {
		title = @"Denied";
		message = @"The request to create a place was denied. Sorry, try again later.";
	} else if ([status isEqualToString:@"INVALID_REQUEST"]) {
		title = @"Bad Request";
		message = @"Something doesn't seem right. Try adding the place again later.";
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) didFinishWithError:(NSError *)error {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create Error" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
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
	[self setSubmitButton:nil];
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
	for (UITextField *o in [self.view subviews]) {
		if ([o isKindOfClass:[UITextField class]]) {
			if ([o.text isEqualToString:@""]) {
				empty = YES;
			}
		}
		
	}
	
	if (empty) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty Field!" message:@"You must fill in ALL of the fields in order to create a place" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	//disable the submit button so multiple requests cant be submitted
	self.submitButton.enabled = NO;
	
	//Configure the object
	__block GooglePlaceAdder *adder = [[GooglePlaceAdder alloc]init];
	[adder setDelegate:self];
	
	//Create the data for googles API call
	//https://developers.google.com/places/documentation/#PlaceSearches
	CLGeocoder *geo = [[CLGeocoder alloc] init];
	[geo geocodeAddressString:[NSString stringWithFormat:@"%@ %@, %@ %@",addressField.text, cityField.text, stateField.text, zipField.text] completionHandler:^(NSArray *placemarks, NSError *error){
	
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
		[data setObject:[NSArray arrayWithObject:@"park"] forKey:@"types"];
		[data setObject:[NSNumber numberWithInt:100] forKey:@"accuracy"];
		
		//send the new place
		[adder sendPlace:data];
	}];
}

- (IBAction)hideKeyboard:(id)sender {
	for (UITextField *t in [self.view subviews]) {
		[t resignFirstResponder];
	}
}

@end
