//
//  AddLocationHomeViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 8/8/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "AddLocationHomeViewController.h"
#import "AddLocationViewController.h"

@interface AddLocationHomeViewController ()

@end

@implementation AddLocationHomeViewController

#pragma mark - AddLocationViewController Delegate 
@synthesize nameField;
@synthesize addressField;
@synthesize cityField;
@synthesize stateField;
@synthesize zipField;

- (void)userDidSelectLocation:(NSDictionary *)addressInfo {
	//Update GUI
}

#pragma mark - View Life Cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil currentLocation:(CLLocationCoordinate2D)c {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        coordinate = c;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload {
	[self setNameField:nil];
	[self setAddressField:nil];
	[self setCityField:nil];
	[self setStateField:nil];
	[self setZipField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)addFromMap:(id)sender {
	AddLocationViewController *add = [[AddLocationViewController alloc] initWithNibName:@"AddLocationViewController" bundle:nil location:coordinate];
	[add setDelegate:self];
	[self.navigationController pushViewController:add animated:YES];
}

- (IBAction)submitNewLocation:(id)sender {
	
}

@end
