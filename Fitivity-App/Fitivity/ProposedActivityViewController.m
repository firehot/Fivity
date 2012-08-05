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
#define kFooterHeight			45.0f

#define kTextFieldMoveDistance          165
#define kTextFieldAnimationDuration    0.3f
#define kMaxCharCount	350

@interface ProposedActivityViewController ()

@end

@implementation ProposedActivityViewController

@synthesize activityHeader;
@synthesize creatorPicture;
@synthesize creatorName;
@synthesize activityMessage;
@synthesize activityCreateTime;
@synthesize activityFooter;
@synthesize activityComment;
@synthesize commentsTable;
@synthesize parent;

#pragma mark - Actions

- (IBAction) textFieldDidUpdate:(id)sender {
	
	//Get the text field, then determine what the current count is.
	UITextField * textField = (UITextField *)sender;
	int charsLeft = kMaxCharCount - [textField.text length];
	
	if (charsLeft < 0) {
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"No more characters"
														 message:[NSString stringWithFormat:@"You have reached the character limit of %d.",kMaxCharCount]
														delegate:nil
											   cancelButtonTitle:@"Ok"
											   otherButtonTitles:nil];
		[alert show];
		
		//Remove the text that went over
		[textField setText:[[textField text] substringToIndex:kMaxCharCount]];
		return;
	}
	
	self.navigationItem.rightBarButtonItem.title = [NSString stringWithFormat:@"%d",charsLeft];
}

- (void)postToFeedWithID:(NSString *)id {
	@synchronized(self) {
		PFObject *feed = [PFObject objectWithClassName:@"ActivityEvent"];
		[feed setObject:parent forKey:@"proposedActivity"];
		[feed setObject:[parent objectForKey:@"group"] forKey:@"group"];
		[feed setObject:[NSNumber numberWithInt:1] forKey:@"number"];
		[feed setObject:@"COMMENT" forKey:@"status"];
		[feed setObject:@"GROUP" forKey:@"type"];
		[feed setObject:[PFUser currentUser] forKey:@"creator"];
		
		PFObject *comment = [PFObject objectWithoutDataWithClassName:@"Comments" objectId:id];
		[comment fetch];
		
		if (comment) {
			[feed setObject:comment forKey:@"comment"];
		} else {
			[feed setObject:[NSNull null] forKey:@"comment"];
		}
		
		if (![feed save]) {
			[feed saveEventually];
		}
}
}

- (void)postComment {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be connected to post a comment" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	if ([[self.activityComment text] isEqualToString:@""]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Valid" message:@"You must put something in the comment message." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	if (![self userIsPartOfParentGroup]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not a Member" message:@"You must be part of a group in order to comment on a proposed activity." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		return;
	}
	
	if (posting) {
		return;
	}
	
	@synchronized(self) {
		PFObject *comment = [PFObject objectWithClassName:@"Comments"];
		[comment setObject:[self.activityComment text] forKey:@"message"];
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
				[self postToFeedWithID:[comment objectId]];
				[self.activityComment setText:@""];
				[self getProposedActivityHistory];
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!" message:@"Your comment has been posted" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
				posting = NO;
			}
			else if (error) {
				NSString *errorMessage = @"An unknown error occurred while posting event.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Posting Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
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

- (BOOL)userIsPartOfParentGroup {
	BOOL ret = NO;
	
	//Get the P.A's parent group
	PFObject *parentGroup = [parent objectForKey:@"group"];
	[parentGroup fetchIfNeeded];
	
	//Search for the user in the group's members
	PFQuery *query = [PFQuery queryWithClassName:@"GroupMembers"];
	[query whereKey:@"user" equalTo:[PFUser currentUser]];
	[query whereKey:@"activity" equalTo:[parentGroup objectForKey:@"activity"]];
	[query whereKey:@"place" equalTo:[parentGroup objectForKey:@"place"]];
	
	//If we get a result we know the user is part of the group
	PFObject *result = [query getFirstObject];
	if (result) {
		ret = YES;
	}
	
	return ret;
}

#pragma mark - Helper Methods 

- (NSString *)getFormattedStringForDate:(NSDate *)date {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"hh:mm a MM/dd"];
	return [formatter stringFromDate:date];
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
	NSMutableAttributedString *attStr = [NSMutableAttributedString attributedStringWithString:[currentPA objectForKey:@"message"]];
	[attStr setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
	[attStr setTextColor:[UIColor whiteColor]];
	
	cell.activityMessage.attributedText = attStr;
	cell.userName.text = [user objectForKey:@"username"];
	cell.timeAgoLabel.text = [self getFormattedStringForDate:[currentPA createdAt]];
	
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return kFooterHeight;
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
	
	activityCreateTime.text = [self getFormattedStringForDate:[parent createdAt]];
	
	return activityHeader;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	return activityFooter;
}

#pragma mark - UITableViewDataSource

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextField Delegate

//Move the text fields up so that the keyboard does not cover them
- (void) animateTextField:(UITextField*)textField Up:(BOOL)up {
    
	if ([results count] != 0) {
		int movement = (up ? -kTextFieldMoveDistance : kTextFieldMoveDistance);
		
		[UIView beginAnimations: @"anim" context: nil];
		[UIView setAnimationBeginsFromCurrentState: YES];
		[UIView setAnimationDuration: kTextFieldAnimationDuration];
		self.view.frame = CGRectOffset(self.view.frame, 0, movement);
		[UIView commitAnimations];

	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self animateTextField:textField Up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self animateTextField:textField Up:NO];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	if ([textField isEqual:self.activityComment]) {
	}
	
	return NO;
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
		
		UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleBordered target:self action:@selector(postComment)];
		[self.navigationItem setRightBarButtonItem:button];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	posting = NO;
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
}

- (void)viewDidUnload {
	[self setCommentsTable:nil];
	[self setActivityHeader:nil];
	[self setCreatorPicture:nil];
	[self setCreatorName:nil];
	[self setActivityMessage:nil];
	[self setActivityCreateTime:nil];
	[self setActivityFooter:nil];
	[self setActivityComment:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
