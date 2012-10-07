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
#import "ReviewsViewController.h"

#import "FTabBarViewController.h"
#import "SocialSharer.h"
#import "AppDelegate.h"

#define kMoveDistance		30

@interface AboutGroupViewController ()

@end

@implementation AboutGroupViewController

@synthesize groupRef;
@synthesize photoResults, photoURLResults;
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
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share Group" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"SMS", @"Email", nil];
	
	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
}

- (IBAction)viewGroupPhotos:(id)sender {
	
	UIImage *trashIcon = [UIImage imageNamed:@"photo-gallery-trashcan.png"];
	UIBarButtonItem *trashButton = [[UIBarButtonItem alloc] initWithImage:trashIcon style:UIBarButtonItemStylePlain target:self action:@selector(handleTrashButtonTouch:)];
	NSArray *barItems = [NSArray arrayWithObject:trashButton];
	
	if ([photoURLResults count] > 0) {
		gallery = [[FGalleryViewController alloc] initWithPhotoSource:self barItems:barItems];
		[self.navigationController pushViewController:gallery animated:YES];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Photos" message:@"There are no photo's for this group yet..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
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
	RateGroupViewController *rating = [[RateGroupViewController alloc] initWithNibName:@"RateGroupViewController" bundle:nil group:groupRef];
	[rating setDelegate:self];
	[self.navigationController pushViewController:rating animated:YES];
}

- (IBAction)viewReviews:(id)sender {
	ReviewsViewController *reviews = [[ReviewsViewController alloc] initWithStyle:UITableViewStylePlain group:groupRef];
	[self.navigationController pushViewController:reviews animated:YES];
}

#pragma mark - Helper Methods 

/*
 *	Using cloud code get the average rating of the group
 */
- (void)getAverageRating {
	NSDictionary *params = [[NSDictionary alloc] initWithObjectsAndKeys:[groupRef objectId], @"groupID", nil];
	[PFCloud callFunctionInBackground:@"getAverageRating" withParameters:params  block:^(id object, NSError *error) {
		if (!error) {
			[self setCorrectRating:(NSNumber *)object];
			[self.ratingLabel setText:[self getGroupRatingString:(NSNumber *)object]];
		} else {
			[self.ratingLabel setText:[self getGroupRatingString:[NSNumber numberWithInt:0]]];
			NSLog(@"%@",[error description]);
		}
	}];
}

/*
 *	Retrieve all of the photos for this group
 */
- (void)attemptPhotosQuery {
	
	if (![[FConfig instance] connected]) {
		return;
	}
	
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"GroupPhotos"];
		[query whereKey:@"group" equalTo:groupRef];
		
		[query findObjectsInBackgroundWithBlock: ^(NSArray *objects, NSError *error){
			if (!error) {
				photoResults = objects;
				NSMutableArray *urls = [[NSMutableArray alloc] init];
				PFFile *pic;
				for (PFObject *o in objects) {
					pic = [o objectForKey:@"image"];
					if (pic != nil) {
						[urls addObject:[pic url]];
					}
				}
				photoURLResults = urls;
			} else {
				photoURLResults = [[NSMutableArray alloc] init];
			}
		}];
	}
}

/*
 *	Set the number of stars to the average
 */
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

/*
 *	Set the group rating label based on the number of stars
 */
- (NSString *)getGroupRatingString:(NSNumber *)rating {
	NSString *s;
	
	int r = [rating integerValue];
	
	switch (r) {
		case 1:
			s = @"Never Reliable";
			break;
		case 2:
			s = @"Occasionally Reliable";
			break;
		case 3:
			s = @"Pretty Reliable";
			break;
		case 4:
			s = @"Frequently Reliable";
			break;
		case 5:
			s = @"Always Reliable";
			break;
		default:
			s = @"Not Enough Ratings...";
			break;
	}
	
	return s;
}

#pragma mark - UIImagePickerViewController Delegate 

/*
 *	Take in an image and scale it to the given size
 */
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize {
	UIGraphicsBeginImageContext(newSize);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

/*
 *	Once done picking the image, scale it to reduce the data size then upload to parse
 */
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[picker dismissModalViewControllerAnimated:YES];
	
	__block MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
	[self.navigationController.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Posting Picture";
	
	[HUD show:YES];
	
	UIImage *selected = [info objectForKey:UIImagePickerControllerOriginalImage];
	CGSize size;
	
	//landscape photo
	if (selected.size.height < selected.size.width) {
		size = CGSizeMake(480, 320);
	} else {
		size = CGSizeMake(320, 480);
	}
	
	PFFile *pic = [PFFile fileWithData:UIImagePNGRepresentation([self scaleImage:selected toSize:size])];
	
	PFObject *groupPic = [PFObject objectWithClassName:@"GroupPhotos"];
	[groupPic setObject:groupRef forKey:@"group"];
	[groupPic setObject:pic forKey:@"image"];
	[groupPic saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){		
		if (succeeded) {
			//Update the photos
			[self attemptPhotosQuery];
			
			HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
			HUD.mode = MBProgressHUDModeCustomView;
			HUD.labelText = @"Posted";
			
			[HUD hide:YES afterDelay:1.5];
		} else {
			[HUD hide:YES];
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

#pragma mark - UITextView Delegate 

- (void) animateTextView:(UITextView *)textView Up:(BOOL)up {
    
    int movement = (up ? -kMoveDistance : kMoveDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: 0.3];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
	if (hasAccess) {
		[self animateTextView:textView Up:YES];
		return YES;
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Access" message:@"You must be part of the group to edit the description" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	
	return NO;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	[self animateTextView:textView Up:NO];
	
	if (textView == descriptionView) {
		//Don't use an api call if it is the same... 
		if (![[groupRef objectForKey:@"description"] isEqualToString:descriptionView.text]) {
			__block MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
			[self.navigationController.view addSubview:HUD];
			
			HUD.delegate = self;
			HUD.mode = MBProgressHUDModeIndeterminate;
			HUD.labelText = @"Posting...";
			
			[HUD show:YES];
			
			PFObject *g = [PFObject objectWithoutDataWithClassName:@"Groups" objectId:[groupRef objectId]];
			[g setObject:descriptionView.text forKey:@"description"];
			
			[g saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
				if (succeeded) {
					HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
					HUD.mode = MBProgressHUDModeCustomView;
					HUD.labelText = @"Posted";
					[HUD hide:YES afterDelay:1.5];
				} else {
					UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Posting" message:@"Something went wrong while posting your description." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
					[alert show];
				}
			}];
		}
	}
	
	return YES;
}

- (BOOL)textView:(UITextView *)txtView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound) {
        return YES;
    }
	
    [txtView resignFirstResponder];
    return NO;
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
	return [photoURLResults count];
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
    return [photoURLResults objectAtIndex:index];
}

- (void)handleTrashButtonTouch:(id)sender {
    [gallery removeImageAtIndex:[gallery currentIndex]];
	
	int index = [gallery currentIndex];
	if ([photoResults count] >= index+1) {
		PFObject *image = [photoResults objectAtIndex:index];
		if (![image delete]) {
			[image deleteEventually];
		}
	}
		
	if ([photoURLResults count] >= index+1) {
		[photoURLResults removeObjectAtIndex:index];
	}
	
	if ([photoURLResults count] == 0) {
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		[gallery reloadGallery];
	}
}

- (void)handleEditCaptionButtonTouch:(id)sender {
    // here we could implement some code to change the caption for a stored image
}

#pragma mark - RateGroupViewController Delegate 

- (void)viewFinishedRatingGroup:(RateGroupViewController *)view {
	[self getAverageRating];
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
		[self getAverageRating];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[ratingLabel setTextColor:[[FConfig instance] getFitivityGreen]];
	
	if (groupRef != nil) {
		[descriptionView setText:[groupRef objectForKey:@"description"]];
		
		// If they are part of the group and there is no description yet
		if (hasAccess && [descriptionView.text isEqualToString:@""]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Write Description" message:@"Take a minute and complete this group's information by writing a brief description!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
	}
	
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
