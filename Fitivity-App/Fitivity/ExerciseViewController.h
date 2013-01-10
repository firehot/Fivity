//
//  ExerciseViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 9/3/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "AnimatedGif.h"

@interface ExerciseViewController : UIViewController {
	PFObject *exercise;
	
	BOOL isVideo, firstView;
	NSURL *videoURL;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil event:(PFObject *)event;

@property (weak, nonatomic) IBOutlet UIWebView *youtubeView;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@end
