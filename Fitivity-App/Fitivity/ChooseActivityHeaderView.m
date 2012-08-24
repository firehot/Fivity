//
//  ChooseActivityHeaderView.m
//  Fitivity
//
//  Created by Nathaniel Doe on 7/15/12.
//  Copyright (c) 2012 Fitivity. All rights reserved.
//

#import "ChooseActivityHeaderView.h"

#define kLabelIndent		10
#define kImageBackIndent	30
#define kImageYIndent		30

@implementation ChooseActivityHeaderView

@synthesize titleLable, section;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame title:(NSString *)title section:(NSInteger)section {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_choose_collapsed.png"]];
		self.userInteractionEnabled = YES;
		self.section = section;
		
		//Add the tap gesture to the header
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleOpen:)];
		[self addGestureRecognizer:tapGesture];
		
		//Set up the possition of the label
		CGRect titleFrame = self.bounds;
		titleFrame.origin.x += kLabelIndent;
		titleFrame.size.width -= kLabelIndent;
		CGRectInset(titleFrame, 0.0, 5.0);
		titleLable = [[UILabel alloc] initWithFrame:titleFrame];
		titleLable.text = title;
		titleLable.font = [UIFont boldSystemFontOfSize:22];
		titleLable.textColor = [UIColor whiteColor];
		titleLable.backgroundColor = [UIColor clearColor];
		[self addSubview:titleLable];
		
		sectionOpen = NO; 
    }
    return self;
}

- (IBAction)toggleOpen:(id)sender {
    [self toggleOpenWithUserAction:YES];
}

- (void)setSectionOpen:(BOOL)open {
	sectionOpen = open;
}

-(void)toggleOpenWithUserAction:(BOOL)userAction {
	
	if (userAction) {
		if (!sectionOpen) {
			if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionOpened:)]) {
                [self.delegate sectionHeaderView:self sectionOpened:self.section];
            }
			 self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_choose_expanded.png"]];
		}
		else {
			if ([self.delegate respondsToSelector:@selector(sectionHeaderView:sectionClosed:)]) {
                [self.delegate sectionHeaderView:self sectionClosed:self.section];
            }
			self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_choose_collapsed.png"]];
		}
		
	}
}

- (void)viewDidLoad {
   self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_choose_collapsed.png"]];

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
