//
//  NDArtworkPopout.h
//  WorkoutTracker
//
//  Created by Nathan Doe on 11/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kArtworkPopoutMaxWidth 240
#define kArtworkPopoutMaxHeight 240

@protocol NDArtworkPopout;

@interface NDArtworkPopout : UIView {
    UIButton *dismissButton;
    UIImageView *artworkView;
}

- (void) show;
- (void) dismissView;
- (id) initWithImage:(UIImage *)artworkImage;

@property (nonatomic, retain) UIImageView *artworkView;
@property (nonatomic, retain) UIButton *dismissButton;
@property (nonatomic, assign) id <NDArtworkPopout> delegate;

@end

@protocol NDArtworkPopout <NSObject>

@optional
- (void) popoutWillDisappear;

@end