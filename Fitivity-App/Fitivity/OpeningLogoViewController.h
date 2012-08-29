//
//  OpeningLogoViewController.h
//  Fitivity
//
//	Class to display the main logo upon app launch
//
//  Created by Nathaniel Doe on 7/10/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OpeningLogoViewControllerDelegate;

@interface OpeningLogoViewController : UIViewController 

@property (nonatomic, assign) id <OpeningLogoViewControllerDelegate> delegate;

@end

//	Delegate for opening view controller to optionally annimate the logo
@protocol OpeningLogoViewControllerDelegate <NSObject>

@optional
-(void)viewHasFinishedAnnimating:(OpeningLogoViewController *)view;

@end
