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

@protocol SocialSharerDelegate;

@interface SocialSharer : NSObject <UIAlertViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, PF_FBDialogDelegate, MBProgressHUDDelegate> {
	UIWindow *mainWindow;
}

+ (SocialSharer *)sharer;
+ (SocialSharer *)sharerWithDelegate:(id<SocialSharerDelegate>)d;

- (void)shareWithFacebook:(NSMutableDictionary *)info facebook:(PF_Facebook *)facebook;
- (void)shareMessageWithTwitter:(NSString *)tweet image:(UIImage *)img link:(NSURL *)url;
- (void)shareTextMessage:(NSString *)text;
- (void)shareEmailMessage:(NSString *)messageBody title:(NSString *)subject attachment:(NSDictionary *)data isHTML:(BOOL)html;

@property (nonatomic, assign) id <SocialSharerDelegate> delegate;
@property (nonatomic, retain) MBProgressHUD *HUD;

@end

@protocol SocialSharerDelegate <NSObject>

- (void)didFinishPosting;

@end

