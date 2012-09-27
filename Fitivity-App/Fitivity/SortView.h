//
//  SortView.h
//  Fitivity
//
//  Created by Nathan Doe on 9/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SortViewDelegate;

@interface SortView : UIView <UIPickerViewDataSource, UIPickerViewDelegate> {
	UIPickerView *sortPicker;
	UINavigationBar *navBar;
}

- (void)show;
- (void)dismiss;

@property (nonatomic, assign) id <SortViewDelegate> delegate;

@end

@protocol SortViewDelegate <NSObject>

- (void)sortView:(SortView *)view didFinishPickingSortCriteria:(NSString *)criteria;

@end
