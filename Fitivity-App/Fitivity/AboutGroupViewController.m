//
//  AboutGroupViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/29/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "AboutGroupViewController.h"
#import "GroupMembersViewController.h"
#import "NSError+FITParseUtilities.h"
#import "RateGroupViewController.h"
#import "ReviewsViewController.h"

#import "FTabBarViewController.h"
#import "SocialSharer.h"
#import "AppDelegate.h"

@interface AboutGroupViewController ()

@end

@implementation AboutGroupViewController

@synthesize groupRef;
@synthesize photoResults;
@synthesize place;
@synthesize activityLabel, ratingLabel, descriptionView;
@synthesize starOne, starTwo, starThree, starFour, starFive;

#pragma mark - IBAction's 

- (IBAction)viewMembers:(id)sender {
	GroupMembersViewController *members = [[GroupMembersViewController alloc]	initWithNibName:@"GroupMembersViewController"
																				bundle:nil
																				place:place
																				activity:[groupRef objectForKey:@"activity"]];
	[self.navigationController pushViewController:members animated:YES];
}

- (IBAction)inviteMembers:(id)sender {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share Group" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"SMS", @"Email", nil];
	
	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
}

- (IBAction)viewGroupPhotos:(id)sender {	
	FGalleryViewController *gallery = [[FGalleryViewController alloc] initWithPhotoSource:self];
	[self.navigationController pushViewController:gallery animated:YES];
}

- (IBAction)addPhoto:(id)sender {
	if (!hasAccess) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access" message:@"You must be part of this group in order to add a photo" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	if ([[FConfig instance] connected]) {
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			UIImagePickerController *camera = [[UIImagePickerController alloc] init];
			[camera setDelegate:self];
			[camera setSourceType:UIImagePickerControllerSourceTypeCamera];
			[self presentViewController:camera animated:YES completion:nil];
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"This feature is not available for your device" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to the internet to upload a picture." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction)viewRateGroup:(id)sender {
	if (!hasAccess) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access" message:@"You must be part of this group in order to rate it" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return;
        }
	RateGroupViewController *rating = [[RateGroupViewController alloc] initWithNibName:@"RateGroupViewController" bundle:nil];
	[self.navigationController pushViewController:rating animated:YES];
}

- (IBAction)viewReviews:(id)sender {
	ReviewsViewController *reviews = [[ReviewsViewController alloc] initWithStyle:UITableViewStylePlain group:groupRef];
	[self.navigationController pushViewController:reviews animated:YES];
}

#pragma mark - Helper Methods 

- (void)attemptPhotosQuery {
	
	if (![[FConfig instance] connected]) {
		return;
	}
	
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"GroupPhotos"];
		[query whereKey:@"group" equalTo:groupRef];
		
		[query findObjectsInBackgroundWithBlock: ^(NSArray *objects, NSError *error){
			if (!error) {
				NSMutableArray *urls = [[NSMutableArray alloc] init];
				PFFile *pic;
				for (PFObject *o in objects) {
					pic = [o objectForKey:@"image"];
					if (pic != nil) {
						[urls addObject:[pic url]];
					}
				}
				photoResults = [NSArray arrayWithArray:urls];
			} else {
				photoResults = [[NSArray alloc] init];
			}
		}];
	}
}

- (void)setCorrectRating:(NSNumber *)num {
	int stars = [num intValue];
	UIImage *active = [UIImage imageNamed:@"star_active.png"];
	
	switch (stars) {
		case 1:
			[starOne setImage:active];
			break;
		case 2:
			[starOne setImage:active];
			[starTwo setImage:active];
			break;
		case 3:
			[starOne setImage:active];
			[starTwo setImage:active];
			[starThree setImage:active];
			break;
		case 4:
			[starOne setImage:active];
			[starTwo setImage:active];
			[starThree setImage:active];
			[starFour setImage:active];
			break;
		case 5:
			[starOne setImage:active];
			[starTwo setImage:active];
			[starThree setImage:active];
			[starFour setImage:active];
			[starFive setImage:active];
			break;
		default:
			break;
	}
}

#pragma mark - UIImagePickerViewController Delegate 

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[picker dismissModalViewControllerAnimated:YES];
	
	__block MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeDeterminate;
	HUD.labelText = @"Posting Picture";
	
	[HUD show:YES];
	
	UIImage *selected = [info objectForKey:UIImagePickerControllerOriginalImage];
	PFFile *pic = [PFFile fileWithData:UIImagePNGRepresentation(selected)];
	
	PFObject *groupPic = [PFObject objectWithClassName:@"GroupPhoto"];
	[groupPic setObject:pic forKey:@"image"];
	[groupPic saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
		[HUD hide:YES afterDelay:0];
		
		if (succeeded) {
			HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
			HUD.mode = MBProgressHUDModeCustomView;
			HUD.labelText = @"Posted";
			
			[HUD show:YES];
			[HUD hide:YES afterDelay:1.5];
		} else {
			NSString *errorMessage = [error userFriendlyParseErrorDescription:YES];
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Failed" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
	}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissModalViewControllerAnimated:YES];
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
	NSString *p, *activity;
	p = [groupRef objectForKey:@"place"];
	activity = [groupRef objectForKey:@"activity"];
	
    if ([title isEqualToString:@"Facebook"]) {
		
		NSString *message = [NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community.", p, activity];
		
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [[FConfig instance] getFacebookAppID], @"app_id",
									   [[FConfig instance] getItunesAppLink], @"link",
									   @"http://nathanieldoe.com/AppFiles/FitivityArtwork", @"picture",
									   @"Fitivity", @"name",
									   message, @"caption",
									   @"You can download it in the Apple App Store or in Google Play", @"description",
									   @"Go download this app!",  @"message",
									   nil];
		
        [[SocialSharer sharer] shareWithFacebookUsers:params facebook:[PFFacebookUtils facebook]];
    } else if ([title isEqualToString:@"Twitter"]) {
		NSString *message = [NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community. Download it for free in the Apple App Store.", p, activity];
        [[SocialSharer sharer] shareMessageWithTwitter:message image:nil link:nil];
    } else if ([title isEqualToString:@"SMS"]) {
        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community. Download it for free now in the Apple App Store. %@", p, activity, [[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"Email"]) {
		NSString *bodyHTML = [NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community. You can download the free fitivity app in the Apple App Store or in Google Play!<br><br>Download it now in the Apple App Store: <a href=\"%@\">%@</a>", p, activity, [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"];
		NSData *picture = [NSData dataWithContentsOfFile:path];
		NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys: picture, @"data", @"image/png", @"mimeType", @"FitivityIcon", @"fileName", nil];
		
        [[SocialSharer sharer] shareEmailMessage:bodyHTML title:@"Fitivity App" attachment:data isHTML:YES];
    }
}

#pragma mark - FGalleryViewControllerDelegate Methods


- (int)numberOfPhotosForPhotoGallery:(FGalleryViewController *)gallery {
	return [photoResults count];
}


- (FGalleryPhotoSourceType)photoGallery:(FGalleryViewController *)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
	return FGalleryPhotoSourceTypeNetwork;
}


- (NSString*)photoGallery:(FGalleryViewController *)gallery captionForPhotoAtIndex:(NSUInteger)index {
	return @"";
}


- (NSString*)photoGallery:(FGalleryViewController*)gallery filePathForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    return @"";
}

- (NSString*)photoGallery:(FGalleryViewController *)gallery urlForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    return [photoResults objectAtIndex:index];
}

- (void)handleTrashButtonTouch:(id)sender {
    // here we could remove images from our local array storage and tell the gallery to remove that image
    // ex:
    //[localGallery removeImageAtIndex:[localGallery currentIndex]];
}

- (void)handleEditCaptionButtonTouch:(id)sender {
    // here we could implement some code to change the caption for a stored image
}


#pragma mark - View Lifecycle 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil group:(PFObject *)group joined:(BOOL)j activity:(NSString *)a place:(GooglePlacesObject *)p {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.groupRef = group;
		self.place = p;
		hasAccess = j;

		if (groupRef == nil) {
			groupRef = [PFObject objectWithClassName:@"Groups"];
		}
		[groupRef fetchIfNeeded];
		
		photoResults = [[NSArray alloc] init];
		
		[self.navigationItem setTitle:a];
		
		NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[groupRef objectId], @"groupID", nil];
		[PFCloud callFunctionInBackground:@"getAverageRating" withParameters:params  block:^(id object, NSError *error) {
			if (!error) {
				[self setCorrectRating:(NSNumber *)object];
			} else {
				NSLog(@"%@",[error description]);
			}
		}];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]]];
	self.activityLabel.text = [place name];

	[self attemptPhotosQuery];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[self setActivityLabel:nil];
	[self setRatingLabel:nil];
	[self setDescriptionView:nil];
	[self setStarOne:nil];
	[self setStarTwo:nil];
	[self setStarThree:nil];
	[self setStarFour:nil];
	[self setStarFive:nil];
    [super viewDidUnload];
}

@end
