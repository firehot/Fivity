//
//  SocialSharer.m
//  Fitivity
//
//  Created by Nathan Doe on 8/27/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "SocialSharer.h"

@implementation SocialSharer

static SocialSharer *instance;

+ (SocialSharer *)sharer {
    @synchronized([SocialSharer class]) {
		if (instance == nil) {
			instance = [[SocialSharer alloc] init];
		}
	}
	return instance;
}

@end
