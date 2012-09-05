//
//  ChallengesViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 8/21/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ChallengesViewController.h"
#import "ChallengeOverviewViewController.h"
#import "NSError+FITParseUtilities.h"

#define kCellHeight			95.0f
#define kHeaderHeight		35.0f

@interface ChallengesViewController ()

@end

@implementation ChallengesViewController
@synthesize tableView;

@synthesize groupType, challenges;

#pragma mark - Helper Methods

//Create an array of arrays for each day of exercises
- (NSMutableArray *)orderDays:(NSArray *)days {
	NSMutableArray *array = [[NSMutableArray alloc] init];
	
	if (days != nil && [days count] > 0) {
		NSMutableArray *temp = [[NSMutableArray alloc] init];
		int level = 0;
		
		for (PFObject *o in days) {
			[o fetchIfNeeded];
			int x = [[o objectForKey:@"level"] intValue];
			if (x != level) {
				level = x;
				
				//Add the array of previous items and reinitialize it
				if ([temp count] != 0) {
					[array addObject:temp];
				}
				temp = [[NSMutableArray alloc] init];
				[temp addObject:o];
			}
			else {
				[temp addObject:o];
			}
		}
		
		//Add the last array
		[array addObject:temp];
	}
	
	return array;
}

- (void)attemptQuery {
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"ChallengeDay"];
		PFObject *parent = [PFObject objectWithoutDataWithClassName:@"Challenge" objectId:[[FConfig instance] getChallengeIDForActivityType:groupType]];
		[query whereKey:@"parent" equalTo:parent];
		[query addAscendingOrder:@"level"];
		[query addAscendingOrder:@"dayNum"];
		[query setCachePolicy:kPFCachePolicyNetworkElseCache];
		[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
			if (error) {
				NSString *errorMessage = @"There was an error loading these challenges";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				return;
			}
			else if (objects) {
				self.challenges = [self orderDays:objects];
				[self.tableView reloadData];
			}
		}];
	}
}

#pragma mark - UIAlertViewDelegate 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	
	if ([title isEqualToString:@"OK"]) {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

#pragma mark - View Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil groupType:(NSString *)type {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
		self.navigationItem.title = type;
		
        self.groupType = type;
		if (groupType) {
			
			if ([[FConfig instance] connected]) {
				[self attemptQuery];
			}
			else {
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to view this content." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an issue loading these challenges." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
	[self setTableView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [challenges count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [[challenges objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return kHeaderHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	NSMutableArray *a = [challenges objectAtIndex:indexPath.section];
	PFObject *current = [a objectAtIndex:indexPath.row];
	[current fetchIfNeeded];
	
	cell.textLabel.text = [NSString stringWithFormat:@"Day %d", [[current objectForKey:@"dayNum"] intValue]];
	
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	//Create the view for the header
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
	UILabel *title = [[UILabel alloc] initWithFrame:view.frame];
	
	[view setBackgroundColor:[UIColor blueColor]];
	[title setBackgroundColor:[UIColor clearColor]];
	[title setTextColor:[UIColor whiteColor]];
	
	[title setTextAlignment:UITextAlignmentCenter];
	[title setText:[NSString stringWithFormat:@"Level %d", section+1]];
	
	[view addSubview:title];
	return view;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	PFObject *o = [[challenges objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	ChallengeOverviewViewController *overview = [[ChallengeOverviewViewController alloc] initWithNibName:@"ChallengeOverviewViewController" bundle:nil day:o title:groupType];
	
	[self.navigationController pushViewController:overview animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
