//
//  ChallengeOverviewViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/3/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ChallengeOverviewViewController.h"
#import "ExerciseViewController.h"
#import "SecondChallengeCell.h"

#import "AppDelegate.h"
#import "FTabBarViewController.h"

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
		[query addAscendingOrder:@"ordering"];
		
		objects = [query findObjects];
		[self.exerciseTable reloadData];
	}
}

- (void)shareApp {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Share Challenge" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook", @"Twitter", @"SMS", @"Email", nil];
	
//	AppDelegate *d = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    [sheet showFromTabBar:[[d tabBarView] backTabBar]];
	[sheet showFromTabBar:self.tabBarController.tabBar];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *type = self.navigationItem.title;
	
    if ([title isEqualToString:@"Facebook"]) {
		
		NSString *message = [NSString stringWithFormat:@"Do the %@ training challenge using fitivity and accomplish your %@ goals.", type, type];
		
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [[FConfig instance] getFacebookAppID], @"app_id",
									   [[FConfig instance] getItunesAppLink], @"link",
									   @"http://www.fitivitymovement.com/FitivityAppIcon.png", @"picture",
									   @"Fitivity", @"name",
	                                   message, @"caption",
									   @"Download the free fitivity app in the Apple App Store or in Google Play", @"description",
									   @"Go download this app!",  @"message",
									   nil];
		
        [[SocialSharer sharer] shareWithFacebookUsers:params facebook:[PFFacebookUtils facebook]];
    } else if ([title isEqualToString:@"Twitter"]) {
		NSString *message = [NSString stringWithFormat:@"Do the %@ training challenge using fitivity and accomplish your %@ goals. Download the free fitivity app using this link.", type, type];
		[[SocialSharer sharer] shareMessageWithTwitter:message image:nil link:nil];
    } else if ([title isEqualToString:@"SMS"]) {
        [[SocialSharer sharer] shareTextMessage:[NSString stringWithFormat:@"Do the %@ training challenge using fitivity and accomplish your %@ goals. Download the free fitivity app in the Apple App Store or in Google Play. %@", type, type, [[FConfig instance] getItunesAppLink]]];
    } else if ([title isEqualToString:@"Email"]) {
		NSString *bodyHTML = [NSString stringWithFormat:@"Do the %@ training challenge using fitivity and accomplish your %@ goals. You can download it for free in the Apple App Store or in Google Play! Download it now in the Apple App Store: <a href=\"%@\">%@</a>", type, type, [[FConfig instance] getItunesAppLink], [[FConfig instance] getItunesAppLink]];
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Icon@2x" ofType:@"png"];
		NSData *picture = [NSData dataWithContentsOfFile:path];
		NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys: picture, @"data", @"image/png", @"mimeType", @"FitivityIcon", @"fileName", nil];
		
        [[SocialSharer sharer] shareEmailMessage:bodyHTML title:@"Fitivity App" attachment:data isHTML:YES];
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
	
	SecondChallengeCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
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
	
//	[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_chall_info.png"]
	UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg_chall_info.png"]];
	[imgView setFrame:overview.frame];
	[self.view addSubview:imgView];
	[self.view sendSubviewToBack:imgView];
	[overview setBackgroundColor:[UIColor clearColor]];
	[overview setText:[day objectForKey:@"overview"]];
	
	UIImage *shareApp = [UIImage imageNamed:@"b_share.png"];
	UIImage *shareAppDown = [UIImage imageNamed:@"b_share_down.png"];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	[button setImage:shareApp forState:UIControlStateNormal];
	[button setImage:shareAppDown forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(shareApp) forControlEvents:UIControlEventTouchUpInside];
	button.frame = CGRectMake(0.0, 0.0, 65.0, 40.0);
	
	UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithCustomView:button];
	self.navigationItem.rightBarButtonItem = share;
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
