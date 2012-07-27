//
//  ProposedActivityViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 7/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ProposedActivityViewController.h"
#import "NSError+FITParseUtilities.h"
#import "NSAttributedString+Attributes.h"
#import "ProposedActivityCell.h"

#define kCellHeight				96.0f
#define kHeaderHeight			110.0f

@interface ProposedActivityViewController ()

@end

@implementation ProposedActivityViewController

@synthesize activityHeader;
@synthesize creatorPicture;
@synthesize creatorName;
@synthesize activityMessage;
@synthesize activityCreateTime;
@synthesize commentsTable;
@synthesize parent;

#pragma Actions

- (void)postComment {
	@synchronized(self) {
		PFObject *comment = [PFObject objectWithClassName:@"Comments"];
		[comment setObject:@"" forKey:@"message"];
		[comment setObject:[PFUser currentUser] forKey:@"user"];
		//Make sure that we have a good reference to the ProposedActivity
		if (parent) {
			[comment setObject:parent forKey:@"parent"];
		}
		else {
			[comment setObject:[NSNull null] forKey:@"parent"];
		}
		
		//Try to save the comment, if can't show error message
		[comment saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				[[NSNotificationCenter defaultCenter] postNotificationName:@"addedComment" object:self];
			}
			else if (error) {
				NSString *errorMessage = @"An unknown error occurred while posting event.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Posting Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			
			[self.navigationController popViewControllerAnimated:YES];
		}];
	}
	
}

- (void)getProposedActivityReference {
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"ProposedActivity"];
		[query whereKey:@"activityMessage" equalTo:[parent objectForKey:@"activityMessage"]];
		[query whereKey:@"creator" equalTo:[parent objectForKey:@"creator"]];
		[query whereKey:@"group" equalTo:[parent objectForKey:@"group"]];
		
		parent = [query getFirstObject];
	}

}

- (void)getProposedActivityHistory {
	
	@synchronized(self) {
		PFQuery *query = [PFQuery queryWithClassName:@"Comments"];
		[query whereKey:@"parent" equalTo:parent];
		[query addAscendingOrder:@"createdAt"];
		
		[query findObjectsInBackgroundWithBlock: ^(NSArray *objects, NSError *error) {
			if (error) {
				NSString *errorMessage = @"An unknown error occurred while loading event.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Loading Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			
			results = [[NSMutableArray alloc] initWithArray:objects];
			[commentsTable reloadData];
		}];
	}
	
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    // Dequeue or create a cell of the appropriate type.
    ProposedActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ProposedActivityCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	//Seperate the objects within a P.A.
	PFObject *currentPA = [results objectAtIndex:indexPath.row];
	[currentPA fetchIfNeeded];
	
	PFObject *user = [currentPA objectForKey:@"user"];
	
	[user fetchIfNeeded];
	
	//Get the image
	PFFile *pic = [user objectForKey:@"image"];
	NSData *picData = [pic getData];
	if (picData) {
		[cell.userPicture setImage:[UIImage imageWithData:picData]];
	}
	else {
		[cell.userPicture setImage:[UIImage imageNamed:@"FeedCellProfilePlaceholderPicture.png"]];
	}
	
	//Style picture
	[cell.userPicture.layer setCornerRadius:10.0f];
	[cell.userPicture.layer setMasksToBounds:YES];
	[cell.userPicture.layer setBorderColor:[[UIColor whiteColor] CGColor]];
	[cell.userPicture.layer setBorderWidth:4];
	
	//Set cell text
	cell.activityMessage.text = [currentPA objectForKey:@"message"];
	cell.userName.text = [user objectForKey:@"username"];
	cell.timeAgoLabel.text = @"";
	
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [results count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	
	PFObject *creator = [parent objectForKey:@"creator"];
	[creator fetchIfNeeded];
	
	//Get the image
	PFFile *pic = [creator objectForKey:@"image"];
	NSData *picData = [pic getData];
	if (picData) {
		[creatorPicture setImage:[UIImage imageWithData:picData]];
	}
	else {
		[creatorPicture setImage:[UIImage imageNamed:@"FeedCellProfilePlaceholderPicture.png"]];
	}
	
	//Style picture
	[creatorPicture.layer setCornerRadius:10.0f];
	[creatorPicture.layer setMasksToBounds:YES];
	[creatorPicture.layer setBorderColor:[[UIColor whiteColor] CGColor]];
	[creatorPicture.layer setBorderWidth:4];
	
	creatorName.text = [creator objectForKey:@"username"];
	NSMutableAttributedString *attStr = [NSMutableAttributedString attributedStringWithString:[parent objectForKey:@"activityMessage"]];
	[attStr setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
	[attStr setTextColor:[UIColor whiteColor]];
	activityMessage.attributedText = attStr;
	
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterMediumStyle];
	
	//activityCreateTime.text = [formatter stringFromDate:[parent createdAt]];
	
	return activityHeader;
}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil proposedActivity:(PFObject *)pa {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.parent = pa;
		
		if (![[FConfig instance] connected]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected!" message:@"you must be connected to view this content" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
		else {
			[self getProposedActivityReference];
			[self getProposedActivityHistory];
		}
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
}

- (void)viewDidUnload {
	[self setCommentsTable:nil];
	[self setActivityHeader:nil];
	[self setCreatorPicture:nil];
	[self setCreatorName:nil];
	[self setActivityMessage:nil];
	[self setActivityCreateTime:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
