//
//  SettingsViewController.h
//  Fitivity
//
//	Shows settings for push notifications and user account
//
//  Created by Nathaniel Doe on 7/18/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Parse/Parse.h>

@interface SettingsViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate> 

- (IBAction)signUserOut:(id)sender;
- (IBAction)linkUserWithFacebook:(id)sender;
- (IBAction)turnOnPushNotifications:(id)sender;
- (IBAction)turnOffPushNotifications:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *facebookLinkButton;
@property (weak, nonatomic) IBOutlet UITableView *accountInfoTable;
@property (weak, nonatomic) IBOutlet UIButton *onButton;
@property (weak, nonatomic) IBOutlet UIButton *offButton;

@end
