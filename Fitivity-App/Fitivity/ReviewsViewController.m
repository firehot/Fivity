//
//  ReviewsViewController.m
//  Fitivity
//
//  Created by Nathan Doe on 9/30/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ReviewsViewController.h"

@interface ReviewsViewController ()

@end

@implementation ReviewsViewController

@synthesize group;

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
    [query orderByDescending:@"updatedAt"];
	
    return query;
}


// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
	static NSString *cellIdentifier = @"Cell";
	
	PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
	
	cell.textLabel.text = [object objectForKey:@"review"];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 80;
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//	return kHeaderHeight;
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
//    
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, kHeaderHeight)];
//    [label setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_heading_header.png"]]];
//    [label setTextAlignment:UITextAlignmentCenter];
//    [label setTextColor:[UIColor whiteColor]];
//    [label setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16]];
//    [label setText:@"Newsfeed"];
//	
//    [header addSubview:label];
//    return header;
//}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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
        [self.navigationController setTitle:@"Reviews"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
