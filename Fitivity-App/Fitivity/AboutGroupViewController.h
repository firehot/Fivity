//
//  AboutGroupViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 9/29/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"

@interface AboutGroupViewController : UIViewController <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, MBProgressHUDDelegate>

- (IBAction)viewMembers:(id)sender;
- (IBAction)inviteMembers:(id)sender;
- (IBAction)viewGroupPhotos:(id)sender;
- (IBAction)addPhoto:(id)sender;
- (IBAction)viewRateGroup:(id)sender;
- (IBAction)viewReviews:(id)sender;

@end
