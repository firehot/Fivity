//
//  AboutGroupViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 9/29/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "RateGroupViewController.h"
#import "FGalleryViewController.h"
#import "MBProgressHUD.h"
#import "GooglePlacesObject.h"

@interface AboutGroupViewController : UIViewController <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextViewDelegate, MBProgressHUDDelegate, FGalleryViewControllerDelegate, RateGroupViewControllerDelegate> {
	BOOL hasAccess;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil group:(PFObject *)group joined:(BOOL)j activity:(NSString *)a place:(GooglePlacesObject *)p;

- (IBAction)viewMembers:(id)sender;
- (IBAction)inviteMembers:(id)sender;
- (IBAction)viewGroupPhotos:(id)sender;
- (IBAction)addPhoto:(id)sender;
- (IBAction)viewRateGroup:(id)sender;
- (IBAction)viewReviews:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *activityLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UITextView *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *starOne;
@property (weak, nonatomic) IBOutlet UIImageView *starTwo;
@property (weak, nonatomic) IBOutlet UIImageView *starThree;
@property (weak, nonatomic) IBOutlet UIImageView *starFour;
@property (weak, nonatomic) IBOutlet UIImageView *starFive;

@property (nonatomic, retain) PFObject *groupRef;
@property (nonatomic, retain) NSArray *photoResults;
@property (nonatomic, retain) GooglePlacesObject *place;

@end
