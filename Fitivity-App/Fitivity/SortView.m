//
//  SortView.m
//  Fitivity
//
//  Created by Nathan Doe on 9/26/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "SortView.h"

@implementation SortView

@synthesize delegate;

#pragma mark - UIPickerView Delegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return [items objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	pickedActivity = [[pickerView delegate] pickerView:pickerView titleForRow:row forComponent:component];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return [items count];
}

#pragma mark - Helpers

- (void)show {
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

- (void)callDelegate {
	if ([delegate respondsToSelector:@selector(sortView:didFinishPickingSortCriteria:)]) {
		if (pickedActivity == nil) {
			pickedActivity = [[FConfig instance] getSortedFeedKey];
		}
		[[FConfig instance] setSortedFeedKey:pickedActivity];
		[delegate sortView:self didFinishPickingSortCriteria:pickedActivity];
	}
}

- (void)dismiss {
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.4];
    
    [self setTransform:CGAffineTransformMakeScale(0.75, 0.1)];
    [self setAlpha:0.0];
	
    [UIView commitAnimations];
    
    [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.0];
}

- (id)initWithFrame:(CGRect)frame items:(NSArray *)i selectedKey:(NSString *)key {
    self = [super initWithFrame:frame];
    if (self) {
		items = i;
		
		UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
        
        self.frame = mainWindow.frame;
        self.backgroundColor = [UIColor colorWithRed:.9 green:.9 blue:.9 alpha:.4];
		
		navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0, 22.0, 320.0, 40.0)];
		[navBar setBackgroundImage:[UIImage imageNamed:@"fitivity_logo.png"] forBarMetrics:UIBarMetricsDefault];
		
		UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setImage:[UIImage imageNamed:@"b_done.png"] forState:UIControlStateNormal];
		[button setImage:[UIImage imageNamed:@"b_done_down.png"] forState:UIControlStateHighlighted];
		[button addTarget:self action:@selector(callDelegate) forControlEvents:UIControlEventTouchUpInside];
		button.frame = CGRectMake(0.0, 0.0, 65.0, 40.0);
		
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithCustomView:button];
		UINavigationItem *item = [[UINavigationItem alloc] init];
		item.rightBarButtonItem = doneButton;
		item.hidesBackButton = YES;
		[navBar pushNavigationItem:item animated:NO];
		
		UIButton *hideButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[hideButton setFrame:self.frame];
		[hideButton addTarget:self action:@selector(callDelegate) forControlEvents:UIControlEventTouchUpInside];
		
		sortPicker = [[UIPickerView alloc] init];
		sortPicker.frame = CGRectMake(0.0, 265.0, 320.0, 216.0);
		[sortPicker setShowsSelectionIndicator:YES];
		[sortPicker setDelegate:self];
		
		if (key == nil) {
			key = @"All Activities";
		}
		
		int row = [items indexOfObject:key];
		[sortPicker selectRow:row inComponent:0 animated:NO];
		
		[self addSubview:navBar];
		[self addSubview:hideButton];
		[self addSubview:sortPicker];
		[self sendSubviewToBack:hideButton];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
