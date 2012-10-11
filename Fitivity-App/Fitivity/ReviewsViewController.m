//
//  ReviewsViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/30/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ReviewsViewController.h"
#import "UserProfileViewController.h"

#define kMoreTextLimit		75

@interface ReviewsViewController ()

@end

@implementation ReviewsViewController

@synthesize group;

#pragma mark - Helper Methods

- (NSString *)getFormattedStringForDate:(NSDate *)date {
	NSDateFormatter *formatter = [[NSDateFormatter  alloc] init];
	[formatter setDateFormat:@"MM/dd"];
	return [formatter stringFromDate:date];
}

#pragma mark - CommentCell Delegate

- (void)userWantsProfileAtRow:(NSInteger)row {
	PFObject *comment = [self.objects objectAtIndex:row];
	PFUser *user = [comment objectForKey:@"user"];
	
	UserProfileViewController *profile = [[UserProfileViewController alloc] initWithNibName:@"UserProfileViewController" bundle:nil initWithUser:user];
	[self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - PFTableViewController Delegate 

// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.className];
	
	// If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
	
	[query whereKey:@"group" equalTo:group];
	[query whereKey:@"review" notEqualTo:@""];
	[query whereKey:@"review" notEqualTo:@" "];
	[query whereKey:@"review" notEqualTo:[NSNull null]];
    [query orderByDescending:@"updatedAt"];
	
    return query;
}


// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
	static NSString *cellIdentifier = @"Cell";
	
	CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"CommentCell" owner:self options:nil];
		cell = [nib objectAtIndex:0];
    }
		
	NSLog(@"%@", [object description]);
	[object fetch];
	
	[cell.userPicture setImage:[UIImage imageNamed:@"b_avatar_settings.png"]];
	
	//Style picture
	[cell.userPicture.layer setCornerRadius:10.0f];
	[cell.userPicture.layer setMasksToBounds:YES];
	[cell.userPicture.layer setBorderColor:[[[FConfig instance] getFitivityBlue] CGColor]];
	[cell.userPicture.layer setBorderWidth:2];
	
	cell.commentMessage.text = [object objectForKey:@"review"];
	cell.commentMessage.adjustsFontSizeToFitWidth = YES;
	
	if (cell.commentMessage.text.length >= kMoreTextLimit) {
		[cell.moreIcon setHidden:NO];
	} else {
		[cell.moreIcon setHidden:YES];
	}
	
	cell.userName.text = @"User";
	cell.time.text = [self getFormattedStringForDate:[object updatedAt]];
	
	[cell setTag:indexPath.row];
	[cell setDelegate:self];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 70;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	PFObject *object = [self objectAtIndexPath:indexPath];
	[object fetchIfNeeded];
	
	NSString *message = [object objectForKey:@"review"];
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Review" message:message delegate:self cancelButtonTitle:@"Done" otherButtonTitles: nil];
	[alert show];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View Lifecycle

- (id)initWithStyle:(UITableViewStyle)style group:(PFObject *)g {
    self = [super initWithStyle:style];
    if (self) {
		
		self.group = g;
		[group fetchIfNeeded];
		
        // The className to query on
        self.className = @"GroupReviews";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = NO;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 10;
    }
	
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self.navigationItem setTitle:@"Reviews"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_buttons_space.png"]];
    self.tableView.separatorColor = [UIColor colorWithRed:178.0/255.0f green:216.0/255.0f blue:254.0/255.0f alpha:1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
