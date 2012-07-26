//
//  ProposeGroupActivityViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/22/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ProposeGroupActivityViewController.h"
#import "NSError+FITParseUtilities.h"

@interface ProposeGroupActivityViewController ()

@end

@implementation ProposeGroupActivityViewController

@synthesize group, proposedActivity;
@synthesize commentField;

#pragma mark - IBAction's 

- (void)postToFeedWithPAID:(NSString *)id {
    @synchronized(self) {
        PFObject *activity = [PFObject objectWithClassName:@"ActivityEvent"];
        [activity setObject:[PFUser currentUser] forKey:@"creator"];
        [activity setObject:[NSNumber numberWithInt:1] forKey:@"number"];
        [activity setObject:@"N/A" forKey:@"status"];
        [activity setObject:@"GROUP" forKey:@"type"];
        [activity setObject:@"" forKey:@"proposedActivity"];
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

- (void)postComment {
	@synchronized(self) {
		PFObject *comment = [PFObject objectWithClassName:@"Comments"];
		[comment setObject:[self.commentField text] forKey:@"message"];
		[comment setObject:[PFUser currentUser] forKey:@"user"];
		//Make sure that we have a good reference to the ProposedActivity
		if (proposedActivity) {
			[comment setObject:proposedActivity forKey:@"parent"];
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
        
        [self postToFeedWithPAID:[activity objectId]];
	}
}

- (void)post {
	
	if (![[FConfig instance] connected]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not Connected" message:@"You must be online in order to post this." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		return;
	}
	
	if (isCommentView) {
		[self postComment];
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
		
	}
	
	return NO;
}

#pragma mark - View Lifecycle 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil isComment:(BOOL)comment {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		
		isCommentView = comment;
		
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%d", kMaxCharCount] style:UIBarButtonItemStyleBordered target:self action:@selector(post)];
		[self.navigationItem setRightBarButtonItem:button];
    }
    return self;
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
