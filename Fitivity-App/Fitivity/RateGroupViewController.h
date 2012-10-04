//
//  RateGroupViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 9/30/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBProgressHUD.h"

@interface RateGroupViewController : UIViewController <UITextFieldDelegate, MBProgressHUDDelegate> {
	int starCount;
	BOOL alreadyRated;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil group:(PFObject *)g;

- (IBAction)postReview:(id)sender;
- (IBAction)rateOne:(id)sender;
- (IBAction)rateTwo:(id)sender;
- (IBAction)rateThree:(id)sender;
- (IBAction)rateFour:(id)sender;
- (IBAction)rateFive:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *starOne;
@property (weak, nonatomic) IBOutlet UIButton *starTwo;
@property (weak, nonatomic) IBOutlet UIButton *starThree;
@property (weak, nonatomic) IBOutlet UIButton *starFour;
@property (weak, nonatomic) IBOutlet UIButton *starFive;
@property (weak, nonatomic) IBOutlet UITextField *review;

@property (nonatomic, retain) PFObject *group;
@property (nonatomic, retain) PFObject *previousReview;

@end
