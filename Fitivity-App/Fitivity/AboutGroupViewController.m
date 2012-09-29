//
//  AboutGroupViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/29/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "AboutGroupViewController.h"
#import "GroupMembersViewController.h"

#import "FTabBarViewController.h"
#import "SocialSharer.h"
#import "AppDelegate.h"

@interface AboutGroupViewController ()

@end

@implementation AboutGroupViewController

#pragma mark - IBAction's 

- (IBAction)viewMembers:(id)sender {
	
}

- (IBAction)inviteMembers:(id)sender {
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share Group" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"SMS", @"Email", nil];
	
	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
}

- (IBAction)viewGroupPhotos:(id)sender {
	
}

- (IBAction)addPhoto:(id)sender {
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		UIImagePickerController *camera = [[UIImagePickerController alloc] init];
		[camera setDelegate:self];
		[camera setSourceType:UIImagePickerControllerSourceTypeCamera];
		[self presentViewController:camera animated:YES completion:nil];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"This feature is not available for your device" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
	}
}

- (IBAction)viewRateGroup:(id)sender {
	
}

- (IBAction)viewReviews:(id)sender {
	
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
		
		HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		HUD.mode = MBProgressHUDModeCustomView;
		HUD.labelText = @"Posted";
		
		[HUD show:YES];
		[HUD hide:YES afterDelay:1.5];
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
    
//    if ([title isEqualToString:@"Facebook"]) {
//		
//		NSString *message = [NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community.", [place name], activity];
//		
//		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//									   [[FConfig instance] getFacebookAppID], @"app_id",
//									   [[FConfig instance] getItunesAppLink], @"link",
//									   @"http://nathanieldoe.com/AppFiles/FitivityArtwork", @"picture",
//									   @"Fitivity", @"name",
//									   message, @"caption",
//									   @"You can download it in the Apple App Store or in Google Play", @"description",
//									   @"Go download this app!",  @"message",
//									   nil];
//		
//        [[SocialSharer sharer] shareWithFacebookUsers:params facebook:[PFFacebookUtils facebook]];
//    } else if ([title isEqualToString:@"Twitter"]) {
//		NSString *message = [NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community. Download it for free in the Apple App Store.", [place name], activity];
//        [[SocialSharer sharer] shareMessageWithTwitter:message image:nil link:nil];
//    } else if ([title isEqualToString:@"SMS"]) {
//        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community. Download it for free now in the Apple App Store. %@", [place name], activity, [[FConfig instance] getItunesAppLink]]];
//    } else if ([title isEqualToString:@"Email"]) {
//		NSString *bodyHTML = [NSString stringWithFormat:@"Join the %@ group to do %@ with me and other members of the Fitivity community. You can download the free fitivity app in the Apple App Store or in Google Play!<br><br>Download it now in the Apple App Store: <a href=\"%@\">%@</a>", [place name], activity, [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
//		
//		NSString *path = [[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"];
//		NSData *picture = [NSData dataWithContentsOfFile:path];
//		NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys: picture, @"data", @"image/png", @"mimeType", @"FitivityIcon", @"fileName", nil];
//		
//        [[SocialSharer sharer] shareEmailMessage:bodyHTML title:@"Fitivity App" attachment:data isHTML:YES];
//    }
}

#pragma mark - View Lifecycle 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
@end
