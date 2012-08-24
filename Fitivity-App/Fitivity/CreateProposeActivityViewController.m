//
//  ProposeGroupActivityViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/22/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "CreateProposeActivityViewController.h"
#import "NSError+FITParseUtilities.h"

@interface CreateProposeActivityViewController ()

@end

@implementation CreateProposeActivityViewController

@synthesize group;
@synthesize commentField;

#pragma mark - IBAction's 

- (PFObject *)getPARefFromServer {
	PFObject *ret;
	
	PFQuery *query = [PFQuery queryWithClassName:@"ProposedActivity"];
	[query whereKey:@"creator" equalTo:[PFUser currentUser]];
	[query whereKey:@"group" equalTo:group];
	[query whereKey:@"activityMessage" equalTo:[commentField text]];
	ret = [query getFirstObject];
	
	//If for some reason can't find the p.a. return nil
	if (!ret) {
		return nil;
	}
	
	return ret;
}

- (void)updateGroupActivityCount {
	@synchronized(self) {
		if (group) {
			//Get reference to the group from server 
			PFObject *updateGroup = [PFObject objectWithoutDataWithClassName:@"Groups" objectId:[group objectId]];
			[updateGroup fetchIfNeeded];
			
			//Get the count from the server and increment it
			NSNumber *num = [updateGroup objectForKey:@"activityCount"];
			[updateGroup setObject:[NSNumber numberWithInt:[num integerValue] + 1] forKey:@"activityCount"];
			
			//Save the group
			if (![updateGroup save]) {
				[updateGroup saveEventually];
			}
		}
	}
}

- (void)postToFeedWithPAID:(NSString *)id {
    @synchronized(self) {
        PFObject *activity = [PFObject objectWithClassName:@"ActivityEvent"];
        [activity setObject:[PFUser currentUser] forKey:@"creator"];
        [activity setObject:[NSNumber numberWithInt:1] forKey:@"number"];
        [activity setObject:@"N/A" forKey:@"status"];
        [activity setObject:@"GROUP" forKey:@"type"];
		
		//Get a reference to the proposed activity we just created and make sure it is valid
		PFObject *pa = [self getPARefFromServer];
		if (pa) {
			[activity setObject:pa forKey:@"proposedActivity"];
		}
		else {
			[activity setObject:[NSNull null] forKey:@"proposedAcitivity"];
		}
        
        //Make sure that we have a good reference to the group
		if (group) {
			[activity setObject:self.group forKey:@"group"];
		}
		else {
			[activity setObject:[NSNull null] forKey:@"group"];
		}
        
        //Try to save the comment, if can't show error message
		[activity saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
			if (error) {
				NSString *errorMessage = @"An unknown error occurred while posting to feed.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Posting Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
		}];
        
    }
}

- (void)postProposedActivity {
	@synchronized(self) {
		PFObject *activity = [PFObject objectWithClassName:@"ProposedActivity"];
		[activity setObject:[PFUser currentUser] forKey:@"creator"];
		[activity setObject:[commentField text] forKey:@"activityMessage"];
		//Make sure that we have a good reference to the group
		if (group) {
			[activity setObject:self.group forKey:@"group"];
		}
		else {
			[activity setObject:[NSNull null] forKey:@"group"];
		}
		
		//Try to save the comment, if can't show error message
		[activity saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
			if (succeeded) {
				
				//push notification to everyone in the group
				if (group && [[FConfig instance] doesHavePushNotifications]) {
					NSString *channel = [NSString stringWithFormat:@"Fitivity%@", [group objectId]];
					NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
										  [NSString stringWithFormat:@"%@ proposed an activity in the group %@", [[PFUser currentUser] username], [group objectForKey:@"activity"]], @"alert",
										  @"increment", @"badge_type",
										  [activity objectId], @"pa_id", nil];
					
					PFPush *push = [[PFPush alloc] init];
					[push setChannel:channel];
					[push setData:data];
					[push expireAfterTimeInterval:86400];
					[push sendPushInBackground];
				}
				
				[self updateGroupActivityCount];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"addedPA" object:self];
			}
			else if (error) {
				NSString *errorMessage = @"An unknown error occurred while posting event.";
				errorMessage = [error userFriendlyParseErrorDescription:YES];
				
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Posting Error" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[alert show];
			}
			
			[self.navigationController popViewControllerAnimated:YES];
		}];
        
		//Wait before trying to post to feed to ensure that the PA is created in the DB 
		[self performSelector:@selector(postToFeedWithPAID:) withObject:[activity objectId] afterDelay:3];
	}
}

- (void)post {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to post this." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	else if ([[commentField text] isEqualToString:@""]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nothing There!" message:@"You must write something!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	else {
		[self postProposedActivity];
	}
}


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

#pragma mark - UITextField Delegate 

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	if ([textField isEqual:self.commentField]) {
		[self post];
	}
	
	return NO;
}

#pragma mark - View Lifecycle 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		[self.navigationItem setTitle:@"New Activity"];
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", kMaxCharCount] style:UIBarButtonItemStyleBordered target:self action:@selector(post)];
		[self.navigationItem setRightBarButtonItem:button];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"bg_location_header.png"] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Bring up the keyboard when view is shown
	[self.commentField becomeFirstResponder];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
}

- (void)viewDidUnload {
	[self setCommentField:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
