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
@synthesize delegate;

#pragma mark - MKMapView Delegate 

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    
	if (oldState == MKAnnotationViewDragStateDragging) {
		DDAnnotation *annotation = (DDAnnotation *)annotationView.annotation;
		
		//Get a CLLocation ref where the user just dropped the pin
		CLLocation *loc = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude longitude:annotation.coordinate.longitude];
		
		//Revers-Geocode the location and get the address
		[geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
			//Get nearby address
			CLPlacemark *placemark = [placemarks objectAtIndex:0];
						
			//String to hold address
			NSArray *values = [placemark.addressDictionary valueForKey:@"FormattedAddressLines"];
			NSString *locatedAt = [NSString stringWithFormat:@"%@ %@", [values objectAtIndex:0], [values objectAtIndex:1]];
			annotation.subtitle = locatedAt;
			
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
		[delegate userDidSelectLocation:nil];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	geocoder = [[CLGeocoder alloc] init];
	
	DDAnnotation *annotation = [[DDAnnotation alloc] initWithCoordinate:location addressDictionary:nil];
	annotation.title = @"Drag to Move Pin";
	
	[geocoder reverseGeocodeLocation:annotation.location completionHandler:^(NSArray *placemarks, NSError *error) {
		//Get nearby address
		CLPlacemark *placemark = [placemarks objectAtIndex:0];
		
		//String to hold address
		NSString *locatedAt = [[placemark.addressDictionary valueForKey:@"FormattedAddressLines"] componentsJoinedByString:@", "];
		annotation.subtitle = locatedAt;
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
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
