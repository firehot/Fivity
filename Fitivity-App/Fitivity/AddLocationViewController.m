//
//  AddLocationViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 8/7/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "AddLocationViewController.h"
#import "MapPin.h"
#import "DDAnnotation.h"
#import "DDAnnotationView.h"

@interface AddLocationViewController ()

@end

@implementation AddLocationViewController

@synthesize mapView;
@synthesize addressSearchField;
@synthesize searchBar;
@synthesize delegate;
@synthesize currentAddress;

#pragma mark - MKMapView Delegate 

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    
	if (oldState == MKAnnotationViewDragStateDragging) {
		DDAnnotation *annotation = (DDAnnotation *)annotationView.annotation;
		
		//Get a CLLocation ref where the user just dropped the pin
		CLLocation *loc = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
		
		//Revers-Geocode the location and get the address
		[geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
			
			if (!placemarks) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results" message:@"Could not find address for location pin is in." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				return;
			}
			
			//Get nearby address
			CLPlacemark *placemark = [placemarks objectAtIndex:0];
			
			//String to hold address
			NSArray *values = [placemark.addressDictionary valueForKey:@"FormattedAddressLines"];
			if ([values count] > 1) {
				currentAddress = [NSString stringWithFormat:@"%@ %@", [values objectAtIndex:0], [values objectAtIndex:1]]; 
			}
			else {
				currentAddress = [NSString stringWithFormat:@"%@", [values objectAtIndex:0]];
			}
			
			annotation.subtitle = currentAddress;
			
			[self.mapView selectAnnotation:annotation animated:NO];
		}];
		
		//Move the map to center the pin
		MKCoordinateRegion region = MKCoordinateRegionMake(annotation.coordinate, self.mapView.region.span);
		[self.mapView setRegion:region animated:YES];
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
	}
	
	static NSString * const kPinAnnotationIdentifier = @"PinIdentifier";
	MKAnnotationView *draggablePinView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationIdentifier];
	
	if (draggablePinView) {
		draggablePinView.annotation = annotation;
	} else {
		// Use class method to create DDAnnotationView (on iOS 3) or built-in draggble MKPinAnnotationView (on iOS 4).
		draggablePinView = [DDAnnotationView annotationViewWithAnnotation:annotation reuseIdentifier:kPinAnnotationIdentifier mapView:self.mapView];
		
		if ([draggablePinView isKindOfClass:[DDAnnotationView class]]) {
			// draggablePinView is DDAnnotationView on iOS 3.
		} else {
			// draggablePinView instance will be built-in draggable MKPinAnnotationView when running on iOS 4.
		}
	}
	
	return draggablePinView;
}

#pragma mark - Helper Methods

- (IBAction)zoomToUser:(id)sender {
	
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([[FConfig instance] mostRecentCoordinate], 1000, 1000);
	[mapView setRegion:region animated:YES];
	
	MapPin *pin = [[MapPin alloc] initWithCoordinates:[[FConfig instance] mostRecentCoordinate] placeName:@"My Location" description:@""];
	[mapView addAnnotation:pin];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state != UIGestureRecognizerStateBegan) {
        return;
	}
	
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
	
    MapPin *annot = [[MapPin alloc] init];
    annot.coordinate = touchMapCoordinate;
    [self.mapView addAnnotation:annot];
}

- (void)refreshCurrentAddressString {
	
	// Reverse Geocode the location
	CLLocation *loc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
	[geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
		//Get nearby address
		CLPlacemark *placemark = [placemarks objectAtIndex:0];
		
		//String to hold address
		currentAddress = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
	}];

}

- (void)dropPinFromSearchAddress {
	
	[geocoder geocodeAddressString:addressSearchField.text completionHandler:^(NSArray *placemarks, NSError *error){
		
		if (!placemarks) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results" message:@"Unable to find address you typed" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			return;
		}
		
		CLPlacemark *placemark = [placemarks objectAtIndex:0];
		
		//[mapView setRegion:region animated:YES];
		[mapView removeAnnotations:[mapView annotations]]; //remove previous annotations
		
		//Add the found address
		DDAnnotation *annotation = [[DDAnnotation alloc] initWithCoordinate:placemark.region.center addressDictionary:nil];
		annotation.title = @"Drag to Move Pin";
		annotation.subtitle = addressSearchField.text;
		
		//Add the annotation and update the map
		[self.mapView addAnnotation:annotation];
		[self.mapView selectAnnotation:annotation animated:NO];
		location = placemark.region.center;
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 3000, 3000);
		[mapView setRegion:region animated:YES];
		
		[self refreshCurrentAddressString];
	}];
	
}

#pragma mark - UITextField Delegate 

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self dropPinFromSearchAddress];
	return YES;
}

#pragma mark - View Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil location:(CLLocationCoordinate2D)userCoordinate {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        location = userCoordinate;
    }
    return self;
}

- (IBAction)submitNewLocation:(id)sender {
	if ([delegate respondsToSelector:@selector(userDidSelectLocation:)]) {
		NSMutableDictionary *returnData = [[NSMutableDictionary alloc] init];
		
		NSArray *components = [currentAddress componentsSeparatedByString:@", "];
		
		if (components) {
			if ([components count] >= 2) {
				NSString *preState = [components objectAtIndex:0];
				NSArray *preStateComponents = [[preState stringByReplacingOccurrencesOfString:@", " withString:@""] componentsSeparatedByString:@" "];
				
				NSString *postState = [components objectAtIndex:1];
				NSArray *postStateComponents = [[postState stringByReplacingOccurrencesOfString:@"  " withString:@" "] componentsSeparatedByString:@" "];
				
				NSString *address = @"";
				for (int i = 0; i < [preStateComponents count] - 1; i++) {
					address = [address stringByAppendingString:[NSString stringWithFormat:@"%@ ", [preStateComponents objectAtIndex:i]]];
				}
				
				NSString *city = [preStateComponents objectAtIndex: [preStateComponents count] - 1];
				NSString *state = [postStateComponents objectAtIndex:0];
				NSString *zip = [postStateComponents objectAtIndex:[postStateComponents count] - 1]; //instead of index 1, use count - 1 incase it does not return a zip
				
				[returnData setObject:address forKey:@"address"];
				[returnData setObject:city forKey:@"city"];
				[returnData setObject:state forKey:@"state"];
				[returnData setObject:zip forKey:@"zip_code"];
			}
		}		
		
		[delegate userDidSelectLocation:returnData];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	geocoder = [[CLGeocoder alloc] init];
	
	currentAddress = @"";
	
	DDAnnotation *annotation = [[DDAnnotation alloc] initWithCoordinate:location addressDictionary:nil];
	annotation.title = @"Drag to Move Pin";
	
	[geocoder reverseGeocodeLocation:annotation.location completionHandler:^(NSArray *placemarks, NSError *error) {
		//Get nearby address
		CLPlacemark *placemark = [placemarks objectAtIndex:0];
		
		//String to hold address
		currentAddress = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
		annotation.subtitle = currentAddress;
	}];
	
	[self.mapView addAnnotation:annotation];
	[self.mapView selectAnnotation:annotation animated:NO];
	
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 3000, 3000);
	[mapView setRegion:region];
	
//	UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
//	lpgr.minimumPressDuration = 0.5;
//	[self.mapView addGestureRecognizer:lpgr];
}

- (void)viewDidUnload {
	mapView.delegate = nil;
    [self setMapView:nil];
	[self setAddressSearchField:nil];
	[self setSearchBar:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
