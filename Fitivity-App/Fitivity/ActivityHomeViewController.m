//
//  ActivityHomeViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/14/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ActivityHomeViewController.h"
#import "GroupPageViewController.h"

#define kGroupCreateMax     2

@interface ActivityHomeViewController ()

@end

@implementation ActivityHomeViewController

@synthesize chooseActivityButton;
@synthesize chooseLocationButton;

#pragma mark - IBAction's 

- (IBAction)chooseActivity:(id)sender {
	ChooseActivityViewController *activity = [[ChooseActivityViewController alloc] initWithNibName:@"ChooseActivityViewController" bundle:nil];
	[activity setDelegate: self];
	[self.navigationController pushViewController:activity animated:YES];
}

- (IBAction)chooseLocation:(id)sender {
	ChooseLocationViewController *location = [[ChooseLocationViewController alloc] initWithNibName:@"ChooseLocationViewController" bundle:nil];
	[location setDelegate: self];
	[self.navigationController pushViewController:location animated:YES];
}

#pragma mark - Helper Methods

- (void)attemptCreateGroup {
    
    //TODO: Query to make sure they havent created more than 2 groups today
    //TODO: Create query to create the group 
    
    //If both have been selected present the group
	if (hasPickedActivity && hasPickedLocation) {
		GroupPageViewController *group = [[GroupPageViewController alloc] initWithNibName:@"GroupPageViewController" bundle:nil place:selectedPlace activity:selectedActivity];
        [self.navigationController popViewControllerAnimated:NO];
        [self.navigationController pushViewController:group animated:YES];
        
        //Reset GUI and vars 
        [chooseActivityButton setEnabled:YES];
        [chooseLocationButton setEnabled:YES];
        selectedPlace = nil;
        selectedActivity = nil;
        hasPickedActivity = NO;
        hasPickedLocation = NO;
	}
}

#pragma mark - ChooseActivityViewController Delegate

- (void)userPickedActivity:(NSString *)activityName {
	hasPickedActivity = YES;
	[chooseActivityButton setEnabled:NO];
    selectedActivity = activityName;
    NSLog(@"%@", selectedActivity);
    [self attemptCreateGroup];
}

#pragma mark - ChoosLocationViewController Delegate

- (void)userPickedLocation:(GooglePlacesObject *)place {
	hasPickedLocation = YES;
	[chooseLocationButton setEnabled:NO];
    selectedPlace = place;
    [self attemptCreateGroup];
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	hasPickedActivity = NO; //Nothing picked when loaded
	hasPickedLocation = NO;
}

- (void)viewDidUnload {
	[self setChooseActivityButton:nil];
	[self setChooseLocationButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
