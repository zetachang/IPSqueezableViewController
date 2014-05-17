//
//  IPNavBarSqueezableViewController.m
//  iPTT
//
//  Created by zeta on 13/10/19.
//  Copyright (c) 2013年 shotdoor. All rights reserved.
//

#import "IPNavBarSqueezableViewController.h"

#define DEBUG_SQUEEZE NO

@interface IPNavBarSqueezableViewController () <UIScrollViewDelegate>

typedef NS_ENUM(NSInteger, IPNavBarSqueezingStatus) {
    IPNavBarSqueezingStatusNormal,
    IPNavBarSqueezingStatusSqueezing,
    IPNavBarSqueezingStatusSqueezed,
    IPNavBarSqueezingStatusUnSqueezing
};

@property (nonatomic) IPNavBarSqueezingStatus navBarStatus;
@property (nonatomic, strong) UILabel* titleView;
@property (nonatomic) BOOL dragStart;
@property (nonatomic) CGFloat previousYOffset;
@property (nonatomic, strong) UITapGestureRecognizer* recognizer;

@end

@implementation IPNavBarSqueezableViewController {
    NSString* _cachedTitle;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Set up scroll to squeeze
    self.navBarStatus = IPNavBarSqueezingStatusNormal;
    self.dragStart = NO;
    
    // Set up title view
    self.titleView =[[UILabel alloc] initWithFrame:CGRectMake(50, 0, 220, 44)];
    self.titleView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    self.titleView.textAlignment = NSTextAlignmentCenter;
    self.titleView.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleView.font = [UIFont boldSystemFontOfSize:17.f];
    self.titleView.frame = CGRectOffset(self.titleView.frame, 200, 0);
    self.titleView.textColor = [[[UINavigationBar appearance] titleTextAttributes] objectForKey:NSForegroundColorAttributeName];
    
    // Recognize tap on nav bar
    self.recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navBarTapped:)];
    self.recognizer.numberOfTapsRequired = 1;
    
    // Set up back button
    NSInteger previousIndex = self.navigationController.viewControllers.count - 2;
    UIViewController* previousVC = [self.navigationController.viewControllers objectAtIndex:previousIndex];
    
    UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTapped:)];
    previousVC.navigationItem.backBarButtonItem = backButton;
    
    // Swipe to pop
    UISwipeGestureRecognizer* recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swippedToPop:)];
    recognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:recognizer];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.titleView.text = _cachedTitle;
    
    [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([context presentationStyle] == UIModalPresentationNone){
            self.titleView.frame = CGRectOffset(self.titleView.frame, -200, 0);
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];

    
    [self.navigationController.navigationBar addSubview:self.titleView];
    
    //NSLayoutConstraint *myConstraint =[NSLayoutConstraint
     //                                  constraintWithItem:self.shimmeringView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.shimmeringView.superview attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    
    //[self.navigationController.navigationBar/ addConstraint:myConstraint];
    [self.navigationItem setHidesBackButton:NO animated:NO];
    [self.navigationController setToolbarHidden:NO animated:NO];
    self.triggeringScrollView.contentInset = UIEdgeInsetsMake(64, 0, 49, 0);
    self.triggeringScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 49, 0);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Unsqueeze manually
    self.navigationController.navigationBar.frame = CGRectMake(0, 20, 320, 44);
    self.navigationController.navigationBar.backIndicatorImage = nil;
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = nil;
    self.titleView.font = [UIFont boldSystemFontOfSize:17.f];
    [self.navigationController.navigationBar removeGestureRecognizer:self.recognizer];
    //[self.navigationController.navigationBar setUserInteractionEnabled:NO];
    self.navBarStatus = IPNavBarSqueezingStatusNormal;
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    
    [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([context presentationStyle] == UIModalPresentationNone){
            self.titleView.alpha = 0.0;
            self.titleView.frame = CGRectOffset(self.titleView.frame, 200, 0);
            [self.navigationController setToolbarHidden:YES animated:YES];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
    
    [self.transitionCoordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if ([context isCancelled]) {
            [self.navigationItem setHidesBackButton:NO animated:YES];
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (self.navigationController.toolbarHidden) {
                    [self.navigationController setToolbarHidden:NO animated:NO];
                }
            });
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.titleView removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTriggeringScrollView:(UIScrollView *)triggeringScrollView {
    if (_triggeringScrollView != triggeringScrollView) {
        _triggeringScrollView = triggeringScrollView;
        _triggeringScrollView.delegate = self;
        // Recognize tap on content
        UITapGestureRecognizer* tapContentRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navBarTapped:)];
        tapContentRecognizer.numberOfTapsRequired = 1;
        [self.triggeringScrollView addGestureRecognizer:tapContentRecognizer];
    }
}

- (void)setTitle:(NSString *)title {
    _cachedTitle = title;
}


#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (DEBUG_SQUEEZE)
        NSLog(@"Begin Dragging");
    
    if (self.navBarStatus == IPNavBarSqueezingStatusNormal) {
        self.dragStart = YES;
    }
    self.previousYOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.dragStart == NO) return;
    
    CGFloat delta = scrollView.contentOffset.y - self.previousYOffset;
    
    if (DEBUG_SQUEEZE) {
        NSLog(@"scroll to offset: %f", scrollView.contentOffset.y);
        NSLog(@"offset delta: %f", delta);
    }
    
    // Squeeze when scroll up higher than a threshold
    CGFloat threshold = 30.f;
    if (delta > threshold && (self.navBarStatus == IPNavBarSqueezingStatusNormal || self.navBarStatus == IPNavBarSqueezingStatusSqueezing)) {
        if (delta > 200) {
            [self squeezeNavBar];
        } else {
            [self squeezeNavBarWithProgress:delta / 200];
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)
velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (DEBUG_SQUEEZE) {
        NSLog(@"End Dragging: (%f,%f) %f", velocity.x, velocity.y, targetContentOffset->y);
    }
    
    self.dragStart = NO;
    CGFloat offsetDelta = (targetContentOffset->y - self.previousYOffset);
    
    // Finish squeezing when squeezing is not finished
    if (self.navBarStatus == IPNavBarSqueezingStatusSqueezing) {
        [self squeezeNavBar];
    }
    
    // Un-squeeze only when
    //  1) scroll up
    //  2) fast enough
    //  3) is squeezed
    // Or
    //  1) is squeezed
    //  2) the target is top edge
    if (self.navBarStatus == IPNavBarSqueezingStatusSqueezed) {
        if (offsetDelta < 0 ||
            fabs((targetContentOffset->y) + 40) < FLT_EPSILON) {
            [self unSqueezeNavBarWithCompletion:nil];
        }
    }
    
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    if (self.navBarStatus == IPNavBarSqueezingStatusSqueezed) {
        [self unSqueezeNavBarWithCompletion:nil];
        return NO;
    } else {
        return YES;
    }
}


#pragma mark - Navbar squeezing

- (void) squeezeNavBarWithProgress: (float) progress {
    if (DEBUG_SQUEEZE)
        NSLog(@"Progress: %f", progress);
    
    if (progress > 1.0) progress = 1.0;
    
    // Use a stub back button
    self.navigationController.navigationBar.backIndicatorImage = [UIImage imageNamed:@"invisibleBackButton.png"];
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = [UIImage imageNamed:@"invisibleBackButton.png"];
    
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    self.navBarStatus = IPNavBarSqueezingStatusSqueezing;
    
    // Adjust the frame of navigation bar according to the progress
    CGRect frame = CGRectMake(0, 20, 320, 44 - 24 * progress);
    self.navigationController.navigationBar.frame = frame;
    if (progress > 0.5) {
        self.titleView.font = [UIFont systemFontOfSize:17.f - 5.f * progress];
    } else {
        self.titleView.font = [UIFont boldSystemFontOfSize:17.f - 5.f * progress];
    }
    
    // Squeezing is done
    if (progress == 1.0) {
        self.navBarStatus = IPNavBarSqueezingStatusSqueezed;
        self.titleView.userInteractionEnabled = YES;
        self.triggeringScrollView.contentInset = UIEdgeInsetsMake(40, 0, 0, 0);
        self.triggeringScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(40, 0, 0, 0);
    }
}

- (void) squeezeNavBar {
    self.navBarStatus = IPNavBarSqueezingStatusSqueezing;
    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = CGRectMake(0, 20, 320, 44 - 24);
        self.navigationController.navigationBar.frame = frame;
        self.titleView.font = [UIFont systemFontOfSize:17.f - 5.f];
    } completion:^(BOOL finished) {
        self.navBarStatus = IPNavBarSqueezingStatusSqueezed;
        [self.navigationController.navigationBar addGestureRecognizer:self.recognizer];
        [self.navigationController.navigationBar setUserInteractionEnabled:YES];
        self.titleView.userInteractionEnabled = YES;
        self.triggeringScrollView.contentInset = UIEdgeInsetsMake(40, 0, 0, 0);
        self.triggeringScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(40, 0, 0, 0);
    }];
}

- (void) unSqueezeNavBarWithCompletion: (void (^)(void))completion {
    [self.navigationController.navigationBar removeGestureRecognizer:self.recognizer];
    self.navBarStatus = IPNavBarSqueezingStatusUnSqueezing;
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.navigationController.navigationBar.frame = CGRectMake(0, 20, 320, 44);
    } completion:^(BOOL finished) {
        self.navigationController.navigationBar.backIndicatorImage = [UIImage imageNamed:@"backButton.png"];
        self.navigationController.navigationBar.backIndicatorTransitionMaskImage = [UIImage imageNamed:@"backButton.png"];
        [self.navigationController setToolbarHidden:NO animated:YES];
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.titleView.font = [UIFont boldSystemFontOfSize:17.f];
        } completion:^(BOOL finished) {
            self.navBarStatus = IPNavBarSqueezingStatusNormal;
            self.triggeringScrollView.contentInset = UIEdgeInsetsMake(64, 0, 49, 0);
            self.triggeringScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(64, 0, 0, 0);
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void) navBarTapped: (id) sender {
    if (self.navBarStatus == IPNavBarSqueezingStatusSqueezed) {
        [self unSqueezeNavBarWithCompletion:nil];
    }
}

- (void) backButtonTapped:(id) sender {
    [self.navigationController popViewControllerAnimated:YES];
    self.titleView.text = @"";
}

- (void) swippedToPop: (id) sender {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
