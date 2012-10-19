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

@synthesize delegate;
@synthesize submitButton;
@synthesize nameField;
@synthesize addressField;
@synthesize cityField;
@synthesize stateField;
@synthesize zipField;
@synthesize typeView;
@synthesize typePicker;
@synthesize selectedTypeLabel;

#pragma mark - Action's

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
		NSDictionary *types = [[FConfig instance] getTypes];
		[data setObject:[NSArray arrayWithObject:[types objectForKey:currentTypeSelection]] forKey:@"types"];
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

- (IBAction)showTypes:(id)sender {
    
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
    
	[self fadeTypeView:YES];
}

- (void)fadeTypeView:(BOOL)on {
	if (on) {
		[UIView beginAnimations:@"fade" context:NULL];
		[UIView setAnimationDuration:0.5];
		
		UIBarButtonItem *submit = [[UIBarButtonItem alloc] initWithTitle:@"Submit" style:UIBarButtonItemStyleBordered target:self action:@selector(submitNewLocation:)];
		[self.navigationItem setRightBarButtonItem:submit];
		
		[self.view bringSubviewToFront:typeView];
		[typeView setAlpha:1.0];
		[UIView commitAnimations];
	} else {
		[UIView beginAnimations:@"fade" context:NULL];
		[UIView setAnimationDuration:0.5];

		[self.navigationItem setRightBarButtonItem:nil];

		[typeView setAlpha:0.0];
		[self.view sendSubviewToBack:typeView];
		[UIView commitAnimations];
	}
}

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

#pragma mark - UIPickerViewController Data Source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [[[FConfig instance] getTypes] count];
}

#pragma mark - UIPickerViewController Delegate 

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	//Get the title based off the keys for the types
	NSArray *titles = [[[FConfig instance] getTypes] allKeys];
	return (NSString *)[titles objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	NSArray *titles = [[[FConfig instance] getTypes] allKeys];
	NSString *title = [NSString stringWithFormat:@"Selected Type: %@", [titles objectAtIndex:row]];;
	[selectedTypeLabel setText:title];
	currentTypeSelection = (NSString *)[titles objectAtIndex:row];
}

#pragma mark - GooglePlaceAdder Delegate 

- (void) didFinishSendingNewPlace:(NSDictionary *)ref {
	
	[self fadeTypeView:NO];
	
	//The status key if successful should be 'OK'
	NSString *status = [ref objectForKey:@"status"];
	if ([status isEqualToString:@"OK"]) {
		//Get the reference to the place we just created
		[googlePlacesConnection getGoogleObjectDetails:[ref objectForKey:@"reference"]];
	}
	
	NSString *title = @"";
	NSString *message = nil;
	
	//Check the status of the request
	if ([status isEqualToString:@"OVER_QUERY_LIMIT"]) {
		title = @"Out of Licenses";
		message = @"We are currently running low on licenses =0 try again later to create this place";
	}
	else if ([status isEqualToString:@"REQUEST_DENIED"]) {
		title = @"Denied";
		message = @"The request to create a place was denied. Sorry, try again later.";
	}
	else if ([status isEqualToString:@"INVALID_REQUEST"]) {
		title = @"Bad Request";
		message = @"Something doesn't seem right. Try adding the place again later.";
	}
	
	//If there is a message, it was unsuccessful... show user the message
	if (message) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
	
	//Allow to submit again
	self.submitButton.enabled = YES;
	
	//Reset textfields
	for (UITextField *o in [self.view subviews]) {
		if ([o isKindOfClass:[UITextField class]]) {
			o.text = @"";
		}
	}
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) didFinishWithError:(NSError *)error {
	
	[self fadeTypeView:NO];
	
	//Allow to submit again
	self.submitButton.enabled = YES;
	
	//Show error
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Create Error" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
}

#pragma mark - NSURLConnections

- (void)googlePlacesConnection:(GooglePlacesConnection *)conn didFinishLoadingWithGooglePlacesObjects:(NSMutableArray *)objects  {
    
    if ([objects count] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No matches found near this location"
                                                        message:@"Try another place name or address"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
	else {
		if (objects) {
			GooglePlacesObject *place = [objects objectAtIndex:0];
			
			if ([delegate respondsToSelector:@selector(userDidCreateNewLocation:)]) {
				[delegate userDidCreateNewLocation:place];
			}
		}
    }
}

- (void) googlePlacesConnection:(GooglePlacesConnection *)conn didFailWithError:(NSError *)error {
   [self fadeTypeView:NO];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reference Error" message:@"Your place was created, but it is not searchable yet. Try looking for it in a minute." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
}


#pragma mark - View Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil currentLocation:(CLLocationCoordinate2D)c {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        coordinate = c;
		googlePlacesConnection = [[GooglePlacesConnection alloc] initWithDelegate:self];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
    
	//Initialize the type view
	[typeView setAlpha:0.0];
	[typeView setFrame:CGRectMake(0, 0, 320, 367)];
	[typeView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_main_group.png"]]];
	[self.view addSubview:typeView];
	[self.view sendSubviewToBack:typeView];
	
	currentTypeSelection = @"";
}

- (void)viewDidUnload {
	[self setNameField:nil];
	[self setAddressField:nil];
	[self setCityField:nil];
	[self setStateField:nil];
	[self setZipField:nil];
	[self setSubmitButton:nil];
	[self setTypeView:nil];
	[self setTypePicker:nil];
	[self setSelectedTypeLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
}

@end
