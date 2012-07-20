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

@interface SettingsViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate> 

- (IBAction)signUserOut:(id)sender;
- (IBAction)linkUserWithFacebook:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *facebookLinkButton;
@property (weak, nonatomic) IBOutlet UITableView *accountInfoTable;
@property (strong, nonatomic) IBOutlet UIView *footerView;

@end
