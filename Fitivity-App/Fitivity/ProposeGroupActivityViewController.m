//
//  ProposeGroupActivityViewController.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/22/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ProposeGroupActivityViewController.h"

@interface ProposeGroupActivityViewController ()

@end

@implementation ProposeGroupActivityViewController

@synthesize commentField;

#pragma mark - IBAction's 

- (IBAction)updateCharCount:(id)sender {
	charCount = [[self.commentField text] length];
	charLeft -= charCount;
	
	NSLog(@"Count = %i, Char's Left = %i", charCount, charLeft);
}

- (void)postToGroup {
	//Implement posting logic here
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextField Delegate 

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	
	if ([textField isEqual:self.commentField]) {
		
	}
	
	return NO;
}

#pragma mark - View Lifecycle 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BluePillNavBarIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(postToGroup)];
		[self.navigationItem setRightBarButtonItem:button];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Used for updating count labels
	charCount = 0;
	charLeft = kMaxCharCount;
	
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
