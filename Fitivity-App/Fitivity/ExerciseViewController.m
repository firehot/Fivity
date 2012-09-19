//
//  ExerciseViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/3/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ExerciseViewController.h"
#import "FTabBarViewController.h"
#import "AppDelegate.h"
#import "SocialSharer.h"

@interface ExerciseViewController ()

@end

@implementation ExerciseViewController

@synthesize youtubeView;
@synthesize image;


#pragma mark - Helper Methods

//Load the html to show the youtube player
- (void)loadURL:(NSString *)url inFrame:(CGRect)frame {
    NSString *youTubeVideoHTML = @"<html><head>\
    <body style=\"margin:0\">\
    <embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
    width=\"%0.0f\" height=\"%0.0f\"></embed>\
    </body></html>";
    
    NSString *html = [NSString stringWithFormat:youTubeVideoHTML, url, frame.size.width, frame.size.height];
	[youtubeView loadHTMLString:html baseURL:nil];
	videoURL = [NSURL URLWithString:url];
}

#pragma mark - 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil event:(PFObject *)event {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        exercise = event;
		[exercise fetchIfNeeded];
		
		self.navigationItem.title = [exercise objectForKey:@"description"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	//Parse gives boolean types back as integers 
	int video = [[exercise objectForKey:@"isLink"] intValue];
	if (video == 1) {
		
		isVideo = YES;
		
		[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_chall_img.png"]]];
		[youtubeView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_chall_img.png"]]];
		[youtubeView setHidden:NO];
		[image setHidden:YES];
		
		[self loadURL:[exercise objectForKey:@"url"] inFrame:youtubeView.frame];
	}
	else {
		
		isVideo = NO;
		
		[youtubeView setHidden:YES];
		[image setHidden:NO];
				
		PFFile *pic = [exercise objectForKey:@"picture"];

		if (pic) {
			AnimatedGif *ag = [[AnimatedGif alloc] init];
			[ag decodeGIF:[pic getData]];
			UIImageView *imageView = [ag getAnimation];
			[imageView setFrame:image.frame];
			[imageView setContentMode:UIViewContentModeScaleAspectFill];
			[image addSubview:imageView];
			[image setContentMode:UIViewContentModeScaleAspectFill];
		}
	}
}

- (void)viewDidUnload {
    [self setYoutubeView:nil];
    [self setImage:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
