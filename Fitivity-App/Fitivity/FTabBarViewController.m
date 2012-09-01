//
//  FTabBarViewController.m
//  Fitivity
//
//  Created by Richard Ng 04/29/2012.
//  Copyright (c) 2012 Fitivity Inc. All rights reserved.
//

#import "FTabBarViewController.h"
#import "DiscoverFeedViewController.h"

@interface FTabBarViewController ()

@property(nonatomic, strong) UINavigationController *leftNavigationController;
@property(nonatomic, strong) UINavigationController *centerNavigationController;
@property(nonatomic, strong) UINavigationController *rightNavigationController;

@property(nonatomic, strong) UIViewController *leftRootViewController;
@property(nonatomic, strong) UIViewController *centerRootViewController;
@property(nonatomic, strong) UIViewController *rightRootViewController;

@property(nonatomic, strong) UINavigationController *displayedViewController;

// Presentation Management
-(void)informDelegateWillChange;
-(void)informDelegateDidChange;
-(void)updateDisplayedViewControllerTo:(UINavigationController *)displayedVC;
-(void)removeDisplayedViewControllerFromView;
-(void)insertDisplayedViewControllerIntoView;

@end

@implementation FTabBarViewController

@synthesize hostingView = _hostingView;
@synthesize tabBarBackplateView = _tabBarBackplateView;
@synthesize leftTabButton = _leftTabButton;
@synthesize centerTabButton = _centerTabButton;
@synthesize rightTabButton = _rightTabButton;

@synthesize delegate = _delegate;

@synthesize leftNavigationController = _leftNavigationController;
@synthesize centerNavigationController = _centerNavigationController;
@synthesize rightNavigationController = _rightNavigationController;

@synthesize leftRootViewController = _leftRootViewController;
@synthesize centerRootViewController = _centerRootViewController;
@synthesize rightRootViewController = _rightRootViewController;

@synthesize displayedViewController = _displayedViewController;
@synthesize backTabBar = _backTabBar;
@synthesize loginView;

#pragma mark - OpeningLogoViewController Delegate

//	Once the logo is annimated into the place the login controller will be
//	we fade in the login view controller.
-(void)viewHasFinishedAnnimating:(OpeningLogoViewController *)view {	
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Helper methods

-(BOOL)isShowingLeftTab {
	return (self.displayedViewController == self.leftNavigationController);
}

-(BOOL)isShowingCenterTab {
	return (self.displayedViewController == self.centerNavigationController);
}

-(BOOL)isShowingRightTab {
	return (self.displayedViewController == self.rightNavigationController);
}

-(void)showLeftTab {
	[self updateDisplayedViewControllerTo:self.leftNavigationController];
}

-(void)showRightTab {
	[self updateDisplayedViewControllerTo:self.rightNavigationController];
}

-(void)showCenterTab {
	[self updateDisplayedViewControllerTo:self.centerNavigationController];
}

- (void)login {
	if ([[FConfig instance] shouldLogIn]) {
		if (!loginView) {
			loginView = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
			
			if ([self.leftRootViewController respondsToSelector:@selector(shareApp)]) {
				[loginView setDelegate:(DiscoverFeedViewController *)self.leftRootViewController];
			}
		}
		[self presentModalViewController:loginView animated:YES];
	}
}

- (void)dismissChildView {
	[self dismissModalViewControllerAnimated:NO];
}

- (void) presentLoginViewController {
	LoginViewController *login = [[LoginViewController alloc] initWithNibName:@"LoginViewController" bundle:nil];
	[self presentModalViewController:login animated:YES];
	[self performSelector:@selector(leftTabButtonPushed:) withObject:nil afterDelay:1.5]; //delay to prevent changing while animation is happening
}

- (void)unselectAllTabs {
	[_leftTabButton setImage:[UIImage imageNamed:@"b_feed_inactive.png"] forState:UIControlStateNormal];
	[_centerTabButton setImage:[UIImage imageNamed:@"b_start_activity_inactive.png"] forState:UIControlStateNormal];
	[_rightTabButton setImage:[UIImage imageNamed:@"b_profile_inactive.png"] forState:UIControlStateNormal];
}

#pragma mark - IBAction's

-(IBAction)leftTabButtonPushed:(id)sender {
	if (!self.isShowingLeftTab) {
		[self unselectAllTabs];
		[_leftTabButton setImage:[UIImage imageNamed:@"b_feed_active.png"] forState:UIControlStateNormal];
		[self showLeftTab];
		[self.centerNavigationController popToRootViewControllerAnimated:NO];
		[self.rightNavigationController popToRootViewControllerAnimated:NO];
	}
	else {
		[[FConfig instance] showLogoNavBar:YES];
		[self.leftNavigationController popToRootViewControllerAnimated:YES];
	}
}

-(IBAction)centerTabButtonPushed:(id)sender {
	if (!self.isShowingCenterTab) {
		[self unselectAllTabs];
		[_centerTabButton setImage:[UIImage imageNamed:@"b_start_activity_active.png"] forState:UIControlStateNormal];
		[self showCenterTab];
		[self.leftNavigationController popToRootViewControllerAnimated:NO];
		[self.rightNavigationController popToRootViewControllerAnimated:NO];
	}
	else {
		[[FConfig instance] showLogoNavBar:YES];
		[self.centerNavigationController popToRootViewControllerAnimated:YES];
	}
}

-(IBAction)rightTabButtonPushed:(id)sender {
	if (!self.isShowingRightTab) {
		[self unselectAllTabs];
		[_rightTabButton setImage:[UIImage imageNamed:@"b_profile_active.png"] forState:UIControlStateNormal];
		[self showRightTab];
		[self.leftNavigationController popToRootViewControllerAnimated:NO];
		[self.centerNavigationController popToRootViewControllerAnimated:NO];
	}
	else {
		[[FConfig instance] showLogoNavBar:YES];
		[self.rightNavigationController popToRootViewControllerAnimated:YES];
	}
}

#pragma mark - View Lifecycle

-(id)initWithLeftRootViewController:(UIViewController *)leftRootVC centerRootViewController:(UIViewController *)centerRootViewController rightRootViewController:(UIViewController *)rightViewController {
  
	if ((self = [super initWithNibName:@"FTabBarViewController" bundle:nil])) {
		self.leftRootViewController = leftRootVC;
		self.centerRootViewController = centerRootViewController;
		self.rightRootViewController = rightViewController;
		
		self.leftNavigationController = [[UINavigationController  alloc] initWithRootViewController:self.leftRootViewController];
		self.centerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.centerRootViewController];
		self.rightNavigationController = [[UINavigationController alloc] initWithRootViewController:self.rightRootViewController];
			
		[[UIBarButtonItem appearance] setTintColor:[[FConfig instance] getFitivityBlue]];
		[[FConfig instance] showLogoNavBar:YES];
	}
	return self;
}

-(void)viewDidLoad {
	[super viewDidLoad];
	
	[SocialSharer sharerWithDelegate:self];
	
	if (!self.displayedViewController) {
		[self updateDisplayedViewControllerTo:self.leftNavigationController];
		[_leftTabButton setImage:[UIImage imageNamed:@"b_feed_active.png"] forState:UIControlStateNormal];
	} else {
		[self insertDisplayedViewControllerIntoView];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	if ([PFUser currentUser] == nil) {
        [self login];
    } 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissChildView) name:@"signedIn" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentLoginViewController) name:@"userLoggedOut" object:nil];
}

-(void)viewWillUnload {
	[super viewWillUnload];
	[self removeDisplayedViewControllerFromView];
}

-(void)viewDidUnload {
	[super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.hostingView = nil;
	self.leftTabButton = nil;
	self.centerTabButton = nil;
	self.rightTabButton = nil;
	self.tabBarBackplateView = nil;
}

#pragma mark - Presentation Management

-(void)informDelegateWillChange {
	id<FTabBarViewControllerDelegate> delegate = [self delegate];
	if (delegate) {
		[delegate applicationTabBarViewControllerWillChangeTab:self];
	}
}

-(void)informDelegateDidChange {
	id<FTabBarViewControllerDelegate> delegate = [self delegate];
	if (delegate) {
		[delegate applicationTabBarViewControllerDidChangeTab:self];
	}
}

-(void)updateDisplayedViewControllerTo:(UINavigationController *)displayedVC {
	if (displayedVC != self.displayedViewController) {
		[self informDelegateWillChange];
		[self removeDisplayedViewControllerFromView];
		self.displayedViewController = displayedVC;
		[self insertDisplayedViewControllerIntoView];
		[self informDelegateDidChange];
	}
}

-(void)removeDisplayedViewControllerFromView {
	if (self.displayedViewController) {
		[self.displayedViewController willMoveToParentViewController:nil];
		[[self.displayedViewController view] removeFromSuperview];
		[self.displayedViewController removeFromParentViewController];
		self.displayedViewController = nil;
	}
}

-(void)insertDisplayedViewControllerIntoView {
	if (self.displayedViewController && self.hostingView) {
		[self addChildViewController:self.displayedViewController];
		[[self.displayedViewController view] setFrame:[self.hostingView bounds]];
		[self.hostingView addSubview:[self.displayedViewController view]];
		[self.displayedViewController didMoveToParentViewController:self];
	}
}

@end
