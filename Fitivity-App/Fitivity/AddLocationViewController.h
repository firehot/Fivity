//
//  AddLocationViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 8/7/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface AddLocationViewController : UIViewController <MKMapViewDelegate> {
	CLLocationCoordinate2D location;
	CLGeocoder *geocoder;
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil location:(CLLocationCoordinate2D)userCoordinate;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
