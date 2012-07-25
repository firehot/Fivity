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

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	static NSString* showAnnotationIdentifier = @"showAnnotationIdentifier";
	MKPinAnnotationView* pinView = (MKPinAnnotationView *)
	[mapView dequeueReusableAnnotationViewWithIdentifier:showAnnotationIdentifier];
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

#pragma mark - 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)thePlace {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.place = thePlace;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Create the visible region for the map
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([place coordinate], 1000, 1000);
	[mapView setRegion:region];
	
	MapPin *pin = [[MapPin alloc] initWithCoordinates:[place coordinate] placeName:[place name] description:[place vicinity]];
	[mapView addAnnotation:pin];
}

- (void)viewDidUnload {
	[self setMapView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
