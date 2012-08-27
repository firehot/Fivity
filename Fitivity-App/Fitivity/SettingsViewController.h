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

@interface SettingsViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

- (IBAction)signUserOut:(id)sender;
- (IBAction)linkUserWithFacebook:(id)sender;
- (IBAction)togglePushNotifications:(id)sender;
- (IBAction)selectImage:(id)sender;
- (IBAction)shareGroup:(id)sender;
- (IBAction)shareActivity:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *facebookLinkButton;
@property (weak, nonatomic) IBOutlet UITableView *accountInfoTable;
@property (weak, nonatomic) IBOutlet UIButton *pushNotificationsButton;
@property (weak, nonatomic) IBOutlet UIButton *pictureButton;
@property (weak, nonatomic) IBOutlet UIButton *shareGroupButton;
@property (weak, nonatomic) IBOutlet UIButton *shareActivityButton;

@end
