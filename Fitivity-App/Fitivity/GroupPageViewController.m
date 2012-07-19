//
//  GroupPageViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/17/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "GroupPageViewController.h"
#import "NSError+FITParseUtilities.h"

@interface GroupPageViewController ()

@end

@implementation GroupPageViewController

@synthesize activityLabel;
@synthesize proposedTable;
@synthesize place, activity;

#pragma mark - Helper Methods

- (BOOL)isAutoJoin {
    return autoJoin;
}

- (void)setAutoJoin:(BOOL)join {
    autoJoin = join;
}

- (void)attemptJoinGroup {
    
    if (![[FConfig instance] connected]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to join a group" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
    }
    
    CLLocationCoordinate2D point = [place coordinate];
    PFGeoPoint *loc = [PFGeoPoint geoPointWithLatitude:point.latitude longitude:point.longitude];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Groups"];
    [query whereKey:@"activity" equalTo:activity];
    [query whereKey:@"place" equalTo:[place name]];
    [query whereKey:@"location" equalTo:loc];
    NSArray *usersPosts = [query findObjects];
    
    PFObject *retrievedGroup = nil;
    if ([usersPosts count] > 0) {
        retrievedGroup = (PFObject *)[usersPosts objectAtIndex:0];
    }
    
    if (retrievedGroup) {
        PFUser *user = [PFUser currentUser];
        PFObject *post = [PFObject objectWithClassName:@"GroupMembers"];
        [post setObject:user forKey:@"user"];
        [post setObject:[retrievedGroup objectId] forKey:@"group"];
        [post setObject:activity forKey:@"activity"];
        [post setObject:[place name] forKey:@"place"];
        [post setObject:loc forKey:@"lcation"];
        [post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            NSString *errorMessage = @"An unknown error uccoured while joining group.";
            if (succeeded) {
                NSLog(@"Created Group");
            }
            else {
                if (error) {
                    errorMessage = [error userFriendlyParseErrorDescription:YES];
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Join Group Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
            }
        }];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Join Group Error" message:@"Error loading group metadata. You were not joined." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }

}

#pragma mark - UITableViewDelegate 

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    }
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;//CHANGE TO DYNAMIC VALUE OF # OF GROUPS USER IN
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 80;
}

#pragma mark - UITableViewDataSource 

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil place:(GooglePlacesObject *)p activity:(NSString *)a {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.place = p;
        self.activity = a;
        
        [self.navigationItem setTitle:[self.place name]];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (autoJoin) {
        //Join the user to the group
        [self attemptJoinGroup];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
    self.activityLabel.text = activity;
}

- (void)viewDidUnload {
    [self setActivityLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
