//
//  AppDelegate.h
//  Fitivity
//
//  Created by Nathaniel Doe on 7/10/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "OpeningLogoViewController.h"
#import "LoginViewController.h"
#import "SocialSharer.h"

@class OpeningLogoViewController, FTabBarViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, OpeningLogoViewControllerDelegate, SocialSharerDelegate> {
	NSDictionary *tempPushInfo;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) OpeningLogoViewController *openingView;
@property (strong, nonatomic) UITabBarController *tabBarController;
//@property (strong, nonatomic) FTabBarViewController *tabBarView;

@end
