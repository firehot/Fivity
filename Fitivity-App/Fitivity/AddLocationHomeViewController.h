//
//  AddLocationHomeViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 8/8/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "AddLocationViewController.h"

@interface AddLocationHomeViewController : UIViewController <AddLocationViewControllerDelegate, UITextFieldDelegate> {
	CLLocationCoordinate2D coordinate;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil currentLocation:(CLLocationCoordinate2D)c;
- (IBAction)addFromMap:(id)sender;
- (IBAction)submitNewLocation:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *addressField;
@property (weak, nonatomic) IBOutlet UITextField *cityField;
@property (weak, nonatomic) IBOutlet UITextField *stateField;
@property (weak, nonatomic) IBOutlet UITextField *zipField;

@end
