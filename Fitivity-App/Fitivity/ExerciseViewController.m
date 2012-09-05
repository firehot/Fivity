//
//  ExerciseViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/3/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ExerciseViewController.h"

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
		[youtubeView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
		[youtubeView setHidden:NO];
		[image setHidden:YES];
		
		[self loadURL:[exercise objectForKey:@"url"] inFrame:youtubeView.frame];
	}
	else {
		[youtubeView setHidden:YES];
		[image setHidden:NO];
		
		PFFile *pic = [exercise objectForKey:@"picture"];
		NSData *picData = [pic getData];
		[image setImage:[UIImage imageWithData:picData]];
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
