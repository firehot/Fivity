//
//  ActivityEvent.m
//  Fitivity
//
//  Created by Nathan Doe on 8/5/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ActivityEvent.h"

@implementation ActivityEvent

@synthesize group, creator, proposedActivity, comment, commentGroup, commentPA;
@synthesize status, type, objectID;
@synthesize number;


// Loads whatever is needed for that activity event
- (void)loadAll {
	
	if ([self.type isEqualToString:@"NORMAL"]) {
		[self.creator fetch];
		[self.group fetch];
	} else if ([self.type isEqualToString:@"GROUP"]) {
		if ([self.status isEqualToString:@"COMMENT"]) {
			commentPA = [comment objectForKey:@"parent"];
			commentGroup = [commentPA objectForKey:@"group"];
			
			[commentGroup fetch];
			[commentPA fetch];
		} else {
			[self.proposedActivity fetch];
			[self.group fetch];
		}
	}
}

- (id)initWithCreator:(PFUser *)c group:(PFObject *)g number:(NSNumber *)n proposedActivity:(PFObject *)p status:(NSString *)s type:(NSString *)t objectID:(NSString *)o comment:(PFObject *)m {
	self = [super init];
	
	if (self) {
		self.creator = c;
		self.group = g;
		self.number = n;
		self.proposedActivity = p;
		self.status = s;
		self.type = t;
		self.objectID = o;
		self.comment = m;
		
		[self loadAll];
	}
	
	return self;
}

@end
