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
- (void)loadURL:(NSString *)url inFrame:(CGRect)frame ios6:(BOOL)version {
    NSString *youTubeVideoHTML, *html;
	
	if (version) {
		
		//For iOS6 need to use iFrame html 
		NSRange range;
		NSString *urlID = @"";
		url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
		
		if ([url length] == 35) {
			NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"v="];
			range = [url rangeOfCharacterFromSet:charSet];
		} else if ([url length] == 20) {
			NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];
			range = [url rangeOfCharacterFromSet:charSet];
		}
		
		if (range.location != NSNotFound) {
			if (range.location < [url length]) {
				urlID = [[url substringFromIndex:range.location] stringByReplacingOccurrencesOfString:@"/" withString:@""];
				urlID = [urlID stringByReplacingOccurrencesOfString:@"v=" withString:@""];
				
			}
		}
		
		youTubeVideoHTML = @"<html><head>\
		<body style=\"margin:0\">\
		<iframe class=\"youtube-player\" type=\"text/html\" width=\"%0.0f\" height=\"%0.0f\" src=\"http://www.youtube.com/embed/%@\" frameborder=\"0\"></iframe> \
		</body></html>";
		
		html = [NSString stringWithFormat:youTubeVideoHTML, frame.size.width, frame.size.height, urlID];
	} else {
		youTubeVideoHTML = @"<html><head>\
		<body style=\"margin:0\">\
		<embed id=\"yt\" src=\"%@\" type=\"application/x-shockwave-flash\" \
		width=\"%0.0f\" height=\"%0.0f\"></embed>\
		</body></html>";
		
		html = [NSString stringWithFormat:youTubeVideoHTML, url, frame.size.width, frame.size.height];
	}

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
		
		if ([[[UIDevice currentDevice] systemVersion] integerValue] < 6) {
			[self loadURL:[exercise objectForKey:@"url"] inFrame:youtubeView.frame ios6:NO];
		} else {
			[self loadURL:[exercise objectForKey:@"url"] inFrame:youtubeView.frame ios6:YES];
		}
		
		
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

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
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
