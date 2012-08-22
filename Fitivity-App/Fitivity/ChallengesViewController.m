//
//  ChallengesViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 8/21/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import "ChallengesViewController.h"
#import "NSError+FITParseUtilities.h"
#import "ChallengeCell.h"

#define kCellHeight			95.0f

@interface ChallengesViewController ()

@end

@implementation ChallengesViewController
@synthesize tableView;

@synthesize groupType, challenges;

#pragma mark - Helper Methods

- (void)attemptQuery {
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"ChallengeStep"];
		PFObject *parent = [PFObject objectWithoutDataWithClassName:@"Challenge" objectId:[[FConfig instance] getChallengeIDForActivityType:groupType]];
		[query whereKey:@"Parent" equalTo:parent];
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
				self.challenges = objects;
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
		
		self.navigationItem.title = @"Challenges";
		
        self.groupType = type;
		if (groupType) {
			[self attemptQuery];
		} else {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"There was an issue loading these challenges." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
	[self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [challenges count];
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
	// Configure the cell...
	PFObject *challenge = [challenges objectAtIndex:indexPath.row];
	[challenge fetchIfNeeded];
	
	PFFile *pic = [challenge objectForKey:@"Image"];
	NSData *picData = [pic getData];
	if (picData) {
		[cell.challengePicture setImage:[UIImage imageWithData:picData]];
	}
	
    [cell.description setText:[challenge objectForKey:@"Description"]];
	
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
