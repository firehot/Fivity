//
//  ChallengeOverviewViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/3/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ChallengeOverviewViewController.h"
#import "ExerciseViewController.h"
#import "ChallengeCell.h"

#define kCellHeight		72.0f

@interface ChallengeOverviewViewController ()

@end

@implementation ChallengeOverviewViewController

@synthesize exerciseTable;
@synthesize overview;

#pragma mark - Helper Methods

- (void)getExercises {
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"Exercise"];
		[query whereKey:@"parent" equalTo:day];
		
		objects = [query findObjects];
		[self.exerciseTable reloadData];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [objects count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	ChallengeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ChallengeCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }

	PFObject *current = [objects objectAtIndex:indexPath.row];
	[current fetchIfNeeded];
	
	[cell.exerciseLabel setText:[current objectForKey:@"description"]];
	[cell.amountLabel setText:[current objectForKey:@"amount"]];
	
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	ExerciseViewController *ex = [[ExerciseViewController alloc] initWithNibName:@"ExerciseViewController" bundle:nil event:[objects objectAtIndex:indexPath.row]];
	[self.navigationController pushViewController:ex animated:YES];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View Lifecycle 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil day:(PFObject *)d title:(NSString *)title {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        day = d;
		[day fetchIfNeeded];
		
		self.navigationItem.title = title;
		
		if (![[FConfig instance] connected]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You need to be connected to load this content" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
		else {
			[self getExercises];
		}
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[overview setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_chall_info.png"]]];
	[overview setText:[day objectForKey:@"overview"]];
}

- (void)viewDidUnload {
    [self setExerciseTable:nil];
    [self setOverview:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end