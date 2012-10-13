//
//  ReviewsViewController.h
//  Fitivity
//
//  Created by Nathan Doe on 9/30/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>

#import "CommentCell.h"

@interface ReviewsViewController : UITableViewController <CommentCellDelegate>

- (id)initWithStyle:(UITableViewStyle)style group:(PFObject *)g;

@property (nonatomic, retain) PFObject *group;
@property (nonatomic, retain) NSMutableArray *results;

@end
