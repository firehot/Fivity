//
//  NDArtworkPopout.m
//  WorkoutTracker
//
//  Created by Nathan Doe on 11/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NDArtworkPopout.h"

@implementation NDArtworkPopout

@synthesize dismissButton, artworkView;
@synthesize delegate;

#pragma mark - presenting/removing methods

- (void) show {
    
    UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
    
    [self setTransform:CGAffineTransformMakeScale(0.75, 0.1)];
    [self setAlpha:0.0];
    
    [mainWindow addSubview:self];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.4];
    
    [self setTransform:CGAffineTransformIdentity];
    [self setAlpha:1.0];
        
    [UIView commitAnimations];
}

- (void) dismissView {
	
	if ([delegate respondsToSelector:@selector(popoutWillDisappear)]) {
		[delegate popoutWillDisappear];
	}
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.4];
    
    [self setTransform:CGAffineTransformMakeScale(0.75, 0.1)];
    [self setAlpha:0.0];

    [UIView commitAnimations];
    
    [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
}

#pragma mark - init methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id) initWithImage:(UIImage *)artworkImage {
    self = [super init];
    if (self) {
        UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
        
        self.frame = mainWindow.frame;
        self.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:.6];
        
        self.artworkView = [[UIImageView alloc] initWithImage:artworkImage];
        self.artworkView.frame = CGRectMake(40, 115, kArtworkPopoutMaxWidth, kArtworkPopoutMaxHeight);
        
		[self.artworkView.layer setCornerRadius:20.0f];
		[self.artworkView.layer setMasksToBounds:YES];
		[self.artworkView.layer setBorderColor:[[UIColor whiteColor] CGColor]];
		[self.artworkView.layer setBorderWidth:8];
		
        self.dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.dismissButton.frame = self.frame;
        [dismissButton addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:artworkView];
        [self addSubview:dismissButton];
    }
    return self;
}

@end
