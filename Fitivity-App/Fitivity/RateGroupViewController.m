//
//  RateGroupViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/30/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "RateGroupViewController.h"

@interface RateGroupViewController ()

@end

@implementation RateGroupViewController

@synthesize starOne, starTwo, starThree, starFour, starFive;
@synthesize review, group, previousReview;
@synthesize delegate;

#pragma mark - Helper Methods

- (void)rateWithNum:(int)rating {
	__block MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Posting...";
	
	[HUD show:YES];
	
	PFObject *r = [PFObject objectWithClassName:@"GroupReviews"];
	[r setObject:[NSNumber numberWithInt:rating] forKey:@"rating"];
	[r setObject:review.text forKey:@"review"];
	
	PFObject *user = [PFObject objectWithoutDataWithClassName:@"User" objectId:[[PFUser currentUser] objectId]];
	[r setObject:user forKey:@"user"];
	[r setObject:group forKey:@"group"];
	
	[r saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
		if (succeeded) {
			HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
			HUD.mode = MBProgressHUDModeCustomView;
			HUD.labelText = @"Posted";
			[HUD hide:YES afterDelay:1.5];
			
			if ([delegate respondsToSelector:@selector(viewFinishedRatingGroup:)]) {
				[delegate viewFinishedRatingGroup:self];
			}
		} else {
			[HUD hide:YES];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Posting" message:@"Something went wrong while posting your review." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
	}];
}

- (void)updateRatingWithNum:(int)rating {
	__block MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Posting...";
	
	[HUD show:YES];
	
	[previousReview setObject:[NSNumber numberWithInt:rating] forKey:@"rating"];
	if (![review.text isEqualToString:@""]) {
		[previousReview setObject:review.text forKey:@"review"];
	}
	
	[previousReview saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
		if (succeeded) {
			HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
			HUD.mode = MBProgressHUDModeCustomView;
			HUD.labelText = @"Posted";
			[HUD hide:YES afterDelay:1.5];
			
			if ([delegate respondsToSelector:@selector(viewFinishedRatingGroup:)]) {
				[delegate viewFinishedRatingGroup:self];
			}
		} else {
			[HUD hide:YES];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Posting" message:@"Something went wrong while posting your review." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
	}];
}

- (void)setActiveStars:(int)num {
	UIImage *active = [UIImage imageNamed:@"star_active.png"];
	UIImage *inactive = [UIImage imageNamed:@"star_inactive.png"];
	
	//reset all images
	[starOne setImage:inactive forState:UIControlStateNormal];
	[starTwo setImage:inactive forState:UIControlStateNormal];
	[starThree setImage:inactive forState:UIControlStateNormal];
	[starFour setImage:inactive forState:UIControlStateNormal];
	[starFive setImage:inactive forState:UIControlStateNormal];
	
	switch (num) {
		case 1:
			[starOne setImage:active forState:UIControlStateNormal];
			break;
		case 2:
			[starOne setImage:active forState:UIControlStateNormal];
			[starTwo setImage:active forState:UIControlStateNormal];
			break;
		case 3:
			[starOne setImage:active forState:UIControlStateNormal];
			[starTwo setImage:active forState:UIControlStateNormal];
			[starThree setImage:active forState:UIControlStateNormal];
			break;
		case 4:
			[starOne setImage:active forState:UIControlStateNormal];
			[starTwo setImage:active forState:UIControlStateNormal];
			[starThree setImage:active forState:UIControlStateNormal];
			[starFour setImage:active forState:UIControlStateNormal];
			break;
		case 5:
			[starOne setImage:active forState:UIControlStateNormal];
			[starTwo setImage:active forState:UIControlStateNormal];
			[starThree setImage:active forState:UIControlStateNormal];
			[starFour setImage:active forState:UIControlStateNormal];
			[starFive setImage:active forState:UIControlStateNormal];
			break;
		default:
			break;
	}
}

- (void)checkIfUserAlreadyRated {
	PFQuery *query = [PFQuery queryWithClassName:@"GroupReviews"];
	[query whereKey:@"group" equalTo:group];
	[query whereKey:@"user" equalTo:[PFObject objectWithoutDataWithClassName:@"User" objectId:[[PFUser currentUser] objectId]]];
	
	previousReview = [query getFirstObject];
	if (previousReview == nil) {
		alreadyRated = NO;
	} else {
		[self setActiveStars:[[previousReview objectForKey:@"rating"] integerValue]];
		alreadyRated = YES;
	}
}

#pragma mark - IBActions

- (IBAction)postReview:(id)sender {
	if ([[FConfig instance] connected]) {
		if (starCount != 0) {
			if (!alreadyRated) {
				[self rateWithNum:starCount];
			} else {
				[self updateRatingWithNum:starCount];
			}
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Rating" message:@"You haven't rated the app yet..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to the internet to post a review" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
	[self.review resignFirstResponder];
}

- (IBAction)rateOne:(id)sender {
	[self setActiveStars:1];
	starCount = 1;
}

- (IBAction)rateTwo:(id)sender {
	[self setActiveStars:2];
	starCount = 2;
}

- (IBAction)rateFour:(id)sender {
	[self setActiveStars:4];
	starCount = 4;
}

- (IBAction)rateFive:(id)sender {
	[self setActiveStars:5];
	starCount = 5;
}

- (IBAction)rateThree:(id)sender {
	[self setActiveStars:3];
	starCount = 3;
}

#pragma mark - UITextField Delegate 

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	[self postReview:nil];
	return YES;
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil  group:(PFObject *)g {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.group = g;
        [self.navigationItem setTitle:@"Review Group"];
		
		UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(postReview:)];
		[self.navigationItem setRightBarButtonItem:postButton];
		
		[self checkIfUserAlreadyRated];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (alreadyRated && previousReview) {
		[self.review setText:[previousReview objectForKey:@"review"]];
		[self setActiveStars:[[previousReview objectForKey:@"rating"] integerValue]];
	} else {
		starCount = 0;
	}
	
	[self.review becomeFirstResponder];
	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setStarOne:nil];
    [self setStarTwo:nil];
    [self setStarThree:nil];
    [self setStarFour:nil];
    [self setStarFive:nil];
	[self setReview:nil];
    [super viewDidUnload];
}

@end
