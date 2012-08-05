//
//  ActivityEvent.h
//  Fitivity
//
//  Created by Nathan Doe on 8/5/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface ActivityEvent : NSObject

- (id)initWithCreator:(PFUser *)c group:(PFObject *)g number:(NSNumber *)n proposedActivity:(PFObject *)p status:(NSString *)s type:(NSString *)t objectID:(NSString *)o comment:(PFObject *)m;

@property (nonatomic, retain) PFUser *creator;
@property (nonatomic, retain) PFObject *group;
@property (nonatomic, retain) PFObject *proposedActivity;
@property (nonatomic, retain) PFObject *comment;

@property (nonatomic, retain) NSNumber *number;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *objectID;

//Specific to Comments
@property (nonatomic, retain) PFObject *commentPA;
@property (nonatomic, retain) PFObject *commentGroup;

@end
