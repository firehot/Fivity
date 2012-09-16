//
//  SocialSharer.m
//  Fitivity
//
//  Created by Nathan Doe on 8/27/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "SocialSharer.h"

#define kHUDShowDuration		1.75
#define kURLLength				23

@implementation SocialSharer

@synthesize delegate;
@synthesize facebookInstance;
@synthesize HUD;

static SocialSharer *instance;

+ (SocialSharer *)sharer {
    @synchronized([SocialSharer class]) {
		if (instance == nil) {
			instance = [[SocialSharer alloc] init];
			[instance initInstance];
		}
		
		if (![instance delegate]) {
			NSLog(@"Sharer has no delegate!");
		}
	}
	return instance;
}

+ (SocialSharer *)sharerWithDelegate:(id<SocialSharerDelegate>)d {
	@synchronized([SocialSharer class]) {
		if (instance == nil) {
			instance = [[SocialSharer alloc] init];
			[instance setDelegate:d];
			[instance initInstance];
		}
	}
	return instance;
}

- (void)initInstance {
	NSArray *windows = [[UIApplication sharedApplication] windows];
	if ([windows respondsToSelector:@selector(objectAtIndex:)]) {
		mainWindow = [windows objectAtIndex:0];
		HUD = [[MBProgressHUD alloc] initWithWindow:mainWindow];
	}
}

- (void)shareWithFacebookUsers:(NSMutableDictionary *)info facebook:(PF_Facebook *)facebook {
	
	fbInfo = info;
	self.facebookInstance = facebook;
	
	if (friendPicker == nil) {
		friendPicker = [[PF_FBFriendPickerViewController alloc] init];
		friendPicker.title = @"Pick Friends";
		friendPicker.delegate = self;
	}
	
	[friendPicker loadData];
	[friendPicker clearSelection];
	
	if ([delegate respondsToSelector:@selector(presentModalViewController:animated:)]) {
		[((UIViewController *)delegate) presentModalViewController:friendPicker animated:YES];
	}
}

- (void)shareWithFacebook:(NSMutableDictionary *)info facebook:(PF_Facebook *)facebook {
	
	if (![facebook isSessionValid]) {
        NSArray *permissions = [NSArray arrayWithObjects:@"offline_access", nil];
		[facebook authorize:permissions];
    }
    else {
        [facebook dialog:@"feed" andParams:info andDelegate:self];
    }
}

- (void)shareMessageWithTwitter:(NSString *)tweet image:(UIImage *)img link:(NSURL *)url {
	Class twitter = NSClassFromString(@"TWTweetComposeViewController"); // Check to make sure that they are using iOS5
	if (twitter) {
		
		//Make sure they have twitter set up and can send it
		if ([TWTweetComposeViewController canSendTweet]) {
			__block TWTweetComposeViewController *tweetController = [[TWTweetComposeViewController alloc] init];
			BOOL hasImg = NO;
			BOOL hasURL = NO;
			
			if (img) {
				if ([tweetController addImage:img]){
					hasImg = YES;
				}
			}
			if (url) {
				if ([tweetController addURL:url]) {
					hasURL = YES;
				}
			}
			if (tweet) {
				if (![tweetController setInitialText:tweet]) {
					NSInteger index = 137;
					if (hasImg)	{
						index -= kURLLength;
					}
					if (hasURL) {
						index -= kURLLength;
					}
					
					NSString *s = [tweet substringToIndex:index];
					s = [s stringByAppendingString:@"..."];
					[tweetController setInitialText:s];
				}
			}
			
			[tweetController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
				if (result == TWTweetComposeViewControllerResultDone) {
					[mainWindow addSubview:HUD];
					HUD.delegate = self;
					HUD.mode = MBProgressHUDModeCustomView;
					HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
					HUD.labelText = @"Sent Tweet";
					
					[HUD show:YES];
					[HUD hide:YES afterDelay:kHUDShowDuration];
				}
				
				if ([delegate respondsToSelector:@selector(didFinishPostingType:)]) {
					[delegate didFinishPostingType:TWITTER];
				}
				
				[tweetController dismissModalViewControllerAnimated:YES];
				tweetController = nil;
			}];
			
			if ([delegate respondsToSelector:@selector(presentModalViewController:animated:)]) {
				[((UIViewController *)delegate) presentModalViewController:tweetController animated:YES];
			}
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sending Error" message:@"There was an issue sending this message. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
				[alert show];
			}
		}
		
		else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Set Up!" message:@"You have not set up Twitter in Settings yet." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: @"Settings",nil];
			[alert show];
		}
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oh No!" message:@"You need iOS 5 in order to use this feature. Once you update your device this feature will work!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
}

- (void)shareTextMessage:(NSString *)text {
	
	if (!text) {
		return;
	}
	
	MFMessageComposeViewController *smsView = [[MFMessageComposeViewController alloc] init];
    smsView.messageComposeDelegate = self;
	[smsView setBody:text];
	[smsView.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
	
	if ([delegate respondsToSelector:@selector(presentModalViewController:animated:)]) {
		[((UIViewController *)delegate) presentModalViewController:smsView animated:YES];
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sending Error" message:@"There was an issue sending this message. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
}

/*
 *	messageBody - The body of the email (can be in HTML format) : REQUIRED
 *	title - The title of the email : REQUIRED
 *	data - The (optional) attachment data
 *			- Should have 3 non-null keys
 *				- data : The NSData of the attachment
 *				- mimeType : The mime type of the data
 *				- fileName : The name of the file
 *	html - True if the messageBody is in HTML format 
 */
- (void)shareEmailMessage:(NSString *)messageBody title:(NSString *)subject attachment:(NSDictionary *)data isHTML:(BOOL)html {
	
	if (!messageBody || !subject) {
		return;
	}
	
	MFMailComposeViewController *message = [[MFMailComposeViewController alloc] init];
    message.mailComposeDelegate = self;
		
	if (data) {
		NSData *attachment = [data objectForKey:@"data"];
		NSString *mime = [data objectForKey:@"mimeType"];
		NSString *name = [data objectForKey:@"fileName"];
		
		if (attachment && mime && name) {
			[message addAttachmentData:attachment mimeType:mime fileName:name];
		}
	}
    
    [message setSubject:subject];
    [message setMessageBody:messageBody isHTML:html];
	
	[message.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
	
	if ([delegate respondsToSelector:@selector(presentModalViewController:animated:)]) {
		[((UIViewController *)delegate) presentModalViewController:message animated:YES];
	} else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sending Error" message:@"There was an issue sending this message. Please try again later." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
	}
}

#pragma mark - PF_FBFriendPickerDelegate

- (void)facebookViewControllerDoneWasPressed:(id)sender {

    NSMutableArray *ids = [[NSMutableArray alloc] init];
	
    // we pick up the users from the selection, and create a string that we use to update the text view
    // at the bottom of the display; note that self.selection is a property inherited from our base class
    for (id<PF_FBGraphUser> user in friendPicker.selection) {
		[ids addObject:user.id];
    }
		
	if (![self.facebookInstance isSessionValid]) {
		NSArray *permissions = [NSArray arrayWithObjects:@"offline_access, publish_stream", nil];
		[self.facebookInstance authorize:permissions];
	} else {
		//For each person chosen, post it to their wall.
		int index = 0;
		for (NSString *s in ids) {
			index ++;
			[[PF_FBRequest requestWithGraphPath:[NSString stringWithFormat:@"%@/feed",s] parameters:fbInfo HTTPMethod:@"POST"] startWithCompletionHandler:^(PF_FBRequestConnection *connection, id result, NSError *error) {
				
				if (!error) {
					if (index == [ids count]) {
						[self dialogDidComplete:nil];
					}
				}
				
			}];
		}
	}

    
	if ([delegate respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
		[((UIViewController *)delegate) dismissModalViewControllerAnimated:YES];
	}
}

- (void)facebookViewControllerCancelWasPressed:(id)sender {
	if ([delegate respondsToSelector:@selector(dismissModalViewControllerAnimated:)]) {
		[((UIViewController *)delegate) dismissModalViewControllerAnimated:YES];
	}
}


#pragma mark - PF_FBDialogBox Delegate 

/*
 *	Sent to the delegate when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidComplete:(PF_FBDialog *)dialog {
	
	[mainWindow addSubview:HUD];
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeCustomView;
	HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
	HUD.labelText = @"Done";
	
	[HUD show:YES];
	[HUD hide:YES afterDelay:kHUDShowDuration];
	
	if ([delegate respondsToSelector:@selector(didFinishPostingType:)]) {
		[delegate didFinishPostingType:FACEBOOK];
	}
}

/*
 *	Sent to the delegate when the dialog is cancelled and is about to be dismissed.
 */
- (void) dialogDidNotComplete:(PF_FBDialog *)dialog {
}

/*
 *	Sent to the delegate when the dialog failed to load due to an error.
 */
- (void)dialog:(PF_FBDialog *)dialog didFailWithError:(NSError *)error {
	[mainWindow addSubview:HUD];
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeText;
	HUD.margin = 15.0f;
	HUD.labelText = @"Failed to Post...";
	HUD.removeFromSuperViewOnHide = YES;
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	
	if (result == MessageComposeResultFailed) {
		[mainWindow addSubview:HUD];
		HUD.delegate = self;
		HUD.mode = MBProgressHUDModeText;
		HUD.margin = 15.0f;
		HUD.labelText = @"Message Failed to Send";
		HUD.removeFromSuperViewOnHide = YES;
	} else if (result == MessageComposeResultSent) {
		[mainWindow addSubview:HUD];
		HUD.delegate = self;
		HUD.mode = MBProgressHUDModeCustomView;
		HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		HUD.labelText = @"Sent Message";
		
		[HUD show:YES];
		[HUD hide:YES afterDelay:kHUDShowDuration];
		
		if ([delegate respondsToSelector:@selector(didFinishPostingType:)]) {
			[delegate didFinishPostingType:SMS];
		}
	}
	
	[controller dismissModalViewControllerAnimated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	[controller dismissModalViewControllerAnimated:YES];
	
	if (result == MFMailComposeResultFailed) {
		[mainWindow addSubview:HUD];
		HUD.delegate = self;
		HUD.mode = MBProgressHUDModeText;
		HUD.margin = 15.0f;
		HUD.labelText = @"Message Failed to Send";
		HUD.removeFromSuperViewOnHide = YES;
		
		[HUD hide:YES afterDelay:kHUDShowDuration];
	} else if (result == MFMailComposeResultSent) {
		[mainWindow addSubview:HUD];
		HUD.delegate = self;
		HUD.mode = MBProgressHUDModeCustomView;
		HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		HUD.labelText = @"Sent Message";
		
		[HUD show:YES];
		[HUD hide:YES afterDelay:kHUDShowDuration];
		
		if ([delegate respondsToSelector:@selector(didFinishPostingType:)]) {
			[delegate didFinishPostingType:EMAIL];
		}
	}
}

#pragma mark - MBProgressHUD Delegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
}

#pragma mark - UIAlertView Delegate 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:@"Settings"]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
	}
}

@end
