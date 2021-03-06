//
//  SocialSharer.h
//  Fitivity
//
//  Created by Nathan Doe on 8/27/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Twitter/Twitter.h>
#import <MessageUI/MessageUI.h>
#import <Parse/Parse.h>

#import "MBProgressHUD.h"

enum {
	FACEBOOK = 0,
	TWITTER = 1,
	SMS = 2,
	EMAIL = 3
};
typedef NSInteger ShareType;

@protocol SocialSharerDelegate;

@interface SocialSharer : NSObject <UIAlertViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, PF_FBDialogDelegate, PF_FBRequestDelegate, PF_FBFriendPickerDelegate, MBProgressHUDDelegate> {
	UIWindow *mainWindow;
	
	PF_FBFriendPickerViewController *friendPicker;
	NSMutableDictionary *fbInfo;
}

+ (SocialSharer *)sharer;
+ (SocialSharer *)sharerWithDelegate:(id<SocialSharerDelegate>)d;

- (void)shareWithFacebookUsers:(NSMutableDictionary *)info facebook:(PF_Facebook *)facebook;
- (void)shareWithFacebook:(NSMutableDictionary *)info facebook:(PF_Facebook *)facebook;
- (void)shareMessageWithTwitter:(NSString *)tweet image:(UIImage *)img link:(NSURL *)url;
- (void)shareTextMessage:(NSString *)text;
- (void)shareEmailMessage:(NSString *)messageBody title:(NSString *)subject attachment:(NSDictionary *)data isHTML:(BOOL)html;

@property (nonatomic, assign) id <SocialSharerDelegate> delegate;
@property (nonatomic, retain) MBProgressHUD *HUD;
@property (nonatomic, retain) PF_Facebook *facebookInstance;

@end

@protocol SocialSharerDelegate <NSObject>

- (void)didFinishPostingType:(ShareType)type;

@end

