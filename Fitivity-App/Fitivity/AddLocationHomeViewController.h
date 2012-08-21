//
//  AddLocationHomeViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 8/8/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "GooglePlacesConnection.h"
#import "GooglePlaceAdder.h"
#import "AddLocationViewController.h"

@protocol AddLocationHomeViewController;

@interface AddLocationHomeViewController : UIViewController <AddLocationViewControllerDelegate, GooglePlaceAdderDelegate, GooglePlacesConnectionDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
	CLLocationCoordinate2D coordinate;
	NSString *currentTypeSelection;
	
	GooglePlacesConnection	*googlePlacesConnection;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil currentLocation:(CLLocationCoordinate2D)c;
- (IBAction)addFromMap:(id)sender;
- (IBAction)submitNewLocation:(id)sender;
- (IBAction)hideKeyboard:(id)sender;
- (IBAction)showTypes:(id)sender;

@property (nonatomic, assign) id <AddLocationHomeViewController> delegate;

@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *addressField;
@property (weak, nonatomic) IBOutlet UITextField *cityField;
@property (weak, nonatomic) IBOutlet UITextField *stateField;
@property (weak, nonatomic) IBOutlet UITextField *zipField;

@property (strong, nonatomic) IBOutlet UIView *typeView;
@property (weak, nonatomic) IBOutlet UIPickerView *typePicker;
@property (weak, nonatomic) IBOutlet UILabel *selectedTypeLabel;

@end

@protocol AddLocationHomeViewController <NSObject>

@optional
- (void)userDidCreateNewLocation:(GooglePlacesObject *)place;

@end
