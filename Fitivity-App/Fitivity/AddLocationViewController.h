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

@protocol AddLocationViewControllerDelegate;

@interface AddLocationViewController : UIViewController <MKMapViewDelegate, UITextFieldDelegate> {
	CLLocationCoordinate2D location;
	CLGeocoder *geocoder;
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil location:(CLLocationCoordinate2D)userCoordinate;
- (IBAction)submitNewLocation:(id)sender;
- (IBAction)zoomToUser:(id)sender;

@property (nonatomic, assign) id <AddLocationViewControllerDelegate> delegate;
@property (nonatomic, retain) NSString *currentAddress;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextField *addressSearchField;
@property (weak, nonatomic) IBOutlet UIToolbar *searchBar;

@end

@protocol AddLocationViewControllerDelegate <NSObject>

@optional
- (void)userDidSelectLocation:(NSDictionary *)addressInfo;

@end