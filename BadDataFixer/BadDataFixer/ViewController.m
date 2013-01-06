//
//  ViewController.m
//  BadDataFixer
//
//  Created by Nathan Doe on 11/27/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize removeCountLabel;
@synthesize acivityEvents, users, comments, reviews, groupMembers, pa;
@synthesize fixButton;

- (void)getInitialData {
	
	__block MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Getting Data...";
	[HUD show:YES];
	
	PFQuery *query = [PFQuery queryWithClassName:@"ActivityEvent"];
	[query setLimit:300];
	
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		} else {
			acivityEvents = [NSMutableArray arrayWithArray:objects];
		}
	}];
	
	PFQuery *userQuery = [PFQuery queryWithClassName:@"_User"];
	[userQuery setLimit:5000];
	
	[userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		} else {
			users = [[NSMutableArray alloc] init];
			HUD.labelText = @"Parsing Data...";
			
			for (PFUser *u in objects) {
				[users addObject:[u objectId]];
			}
		}
	}];
	
	PFQuery *commentQuery = [PFQuery queryWithClassName:@"Comments"];
	[commentQuery setLimit:1000];
	
	[commentQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		} else {
			comments = [NSMutableArray arrayWithArray:objects];
		}
	}];
	
	PFQuery *paQuery = [PFQuery queryWithClassName:@"ProposedActivity"];
	[paQuery setLimit:1000];
	
	[paQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		} else {
			pa = [NSMutableArray arrayWithArray:objects];
		}
	}];
	
	PFQuery *groupQuery = [PFQuery queryWithClassName:@"GroupMembers"];
	[groupQuery setLimit:1000];
	
	[groupQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		} else {
			groupMembers = [NSMutableArray arrayWithArray:objects];
		}
	}];
	
	PFQuery *reviewsQuery = [PFQuery queryWithClassName:@"GroupReviews"];
	[reviewsQuery setLimit:1000];
	
	[reviewsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
		if (error) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:[error description] delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		} else {
			reviews = [NSMutableArray arrayWithArray:objects];
		}
		[HUD hide:YES];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	int64_t delayInSeconds = 0.2;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self getInitialData];
	});
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)fixData:(id)sender {
	NSString *objectID = @"";
	int counter = 0;
	[removeCountLabel setText:[NSString stringWithFormat:@"%i", counter]];
	
	MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:HUD];
	
	HUD.delegate = self;
	HUD.mode = MBProgressHUDModeIndeterminate;
	HUD.labelText = @"Removing Bad Data...";
	[HUD show:YES];
	
	for (PFObject *o in acivityEvents) {
		objectID = [[o objectForKey:@"creator"] objectId];
		if ([users indexOfObject:objectID] == NSNotFound) {
			if (![o delete]) {
				[o deleteEventually];
			} else {
				counter++;
			}
		}
	}
	
	for (PFObject *o in pa) {
		objectID = [[o objectForKey:@"creator"] objectId];
		
		if ([users indexOfObject:objectID] == NSNotFound) {
			if (![o delete]) {
				[o deleteEventually];
			} else {
				counter++;
			}
		}
	}

	for (PFObject *o in comments) {
		objectID = [[o objectForKey:@"user"] objectId];
		
		if ([users indexOfObject:objectID] == NSNotFound) {
			if (![o delete]) {
				[o deleteEventually];
			} else {
				counter++;
			}
		}
	}
	
	for (PFObject *o in reviews) {
		objectID = [[o objectForKey:@"creator"] objectId];
		
		if ([users indexOfObject:objectID] == NSNotFound) {
			if (![o delete]) {
				[o deleteEventually];
			} else {
				counter++;
			}
		}
	}
	
	for (PFObject *o in groupMembers) {
		objectID = [[o objectForKey:@"user"] objectId];
		
		if ([users indexOfObject:objectID] == NSNotFound) {
			if (![o delete]) {
				[o deleteEventually];
			} else {
				counter++;
			}
		}
	}
	
	[HUD hide:YES];
	[removeCountLabel setText:[NSString stringWithFormat:@"%i", counter]];
	[fixButton setEnabled:NO];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Finished" message:[NSString stringWithFormat:@"There were %i entries removed. To run again you will need to restart the app.", counter] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

#pragma mark - MBProgressHUDDelegate methods

- (void)hudWasHidden:(MBProgressHUD *)hud {
	// Remove HUD from screen when the HUD was hidded
	[hud removeFromSuperview];
}



@end
