//
//  LocationMapViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/14/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "LocationMapViewController.h"
#import "MapPin.h"

@interface LocationMapViewController ()

@end

@implementation LocationMapViewController

@synthesize place;
@synthesize mapView;
@synthesize userLocationButton;

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	static NSString* showAnnotationIdentifier = @"showAnnotationIdentifier";
	MKPinAnnotationView* pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:showAnnotationIdentifier];
	if (!pinView){
		// if an existing pin view was not available, create one
		MKPinAnnotationView* customPinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:showAnnotationIdentifier];
		customPinView.pinColor = MKPinAnnotationColorRed;
		customPinView.animatesDrop = YES;
		customPinView.canShowCallout = YES;
		
		return customPinView;
	}
	else {
		pinView.annotation = annotation;
	}
	return pinView;
}

#pragma mark - Directions

- (void)openDirectionsToAddress:(NSString *)address {
	CLLocationCoordinate2D currentLocation = [[FConfig instance] mostRecentCoordinate];
    NSString *url = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%@",currentLocation.latitude, currentLocation.longitude,[address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)getDirectionsToPlace {
	
	__block NSString *address = @"";
	NSArray *addr = [place addressComponents];
	if (addr) {
		for (int i = 0; i < [addr count]; i++) {
			address = [address stringByAppendingString:[addr objectAtIndex:i]];
		}
		[self openDirectionsToAddress:address];
	} else {
		CLGeocoder *geocoder = [[CLGeocoder alloc] init];
		CLLocationCoordinate2D currentLocation = [place coordinate];
		CLLocation *loc = [[CLLocation alloc] initWithLatitude:currentLocation.latitude longitude:currentLocation.longitude];
		[geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
			
			if (error) {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Error" message:@"There was an error getting directions to this place" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
				return;
			}
			
			//Get nearby address
			CLPlacemark *placemark = [placemarks objectAtIndex:0];
			
			//String to hold address
			address = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
			[self openDirectionsToAddress:address];
		}];
	}
}

#pragma mark - 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)thePlace {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.place = thePlace;
		self.navigationItem.title = @"Map";
		
		UIBarButtonItem *directions = [[UIBarButtonItem alloc] initWithTitle:@"Directions" style:UIBarButtonItemStyleBordered target:self action:@selector(getDirectionsToPlace)];
        [directions setTitle:@"Directions"];
        self.navigationItem.rightBarButtonItem = directions;
    }
    return self;
}

- (IBAction)zoomToUser:(id)sender {
	
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([[FConfig instance] mostRecentCoordinate], 1000, 1000);
	[mapView setRegion:region animated:YES];
	
	MapPin *pin = [[MapPin alloc] initWithCoordinates:[[FConfig instance] mostRecentCoordinate] placeName:@"My Location" description:@""];
	[mapView addAnnotation:pin];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
	
	//Create the visible region for the map
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([place coordinate], 1000, 1000);
	[mapView setRegion:region];
	
	MapPin *pin = [[MapPin alloc] initWithCoordinates:[place coordinate] placeName:[place name] description:[place vicinity]];
	[mapView addAnnotation:pin];
}

- (void)viewDidUnload {
	[self setMapView:nil];
    [self setUserLocationButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
