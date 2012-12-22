//
//  ChooseChallengeAcitivityViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 12/21/12.
//  Copyright (c) 2012 Nathaniel Doe. All rights reserved.
//

#import "ChooseChallengeAcitivityViewController.h"
#import "ChooseActivityCell.h"

#define kRowHeight		45

@interface ChooseChallengeAcitivityViewController ()

@end

@implementation ChooseChallengeAcitivityViewController

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	
	// Dequeue or create a cell of the appropriate type.
	ChooseActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ChooseActivityCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
	
	cell.titleLabel.text = @"Activity";
	
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return kRowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_main_location.png"]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
	[self setActivityTable:nil];
	[super viewDidUnload];
}

@end
