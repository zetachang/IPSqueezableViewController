//
//  IPNavBarSqueezableViewController.m
//  iPTT
//
//  Created by zeta on 13/10/19.
//  Copyright (c) 2013年 shotdoor. All rights reserved.
//

#import "IPNavBarSqueezableViewController.h"

/**
 Uncomment to debug
 */
// #define DEBUG_SQUEEZE

#define SCREEN_WIDTH ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) \
|| ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) \
? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

#define NAVBAR_HEIGHT ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) \
|| ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? 44.f : 32.f)

#define TOOLBAR_HEIGHT ((([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) \
|| ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)) ? 49.f : 32.f)


static const CGFloat kSqueezedNavigationBarHeight = 20.f;
static const CGFloat kStatusBarHeight             = 20.f;
static const NSTimeInterval kAnimationDuration    = 0.25;


typedef NS_ENUM(NSInteger, IPNavBarSqueezingStatus) {
    IPNavBarSqueezingStatusNormal,
    IPNavBarSqueezingStatusProgress,
    IPNavBarSqueezingStatusSqueezing,
    IPNavBarSqueezingStatusSqueezed,
    IPNavBarSqueezingStatusUnSqueezing
};


@interface IPNavBarSqueezableViewController () <UIScrollViewDelegate>

@property (nonatomic) IPNavBarSqueezingStatus navBarStatus;
@property (nonatomic, strong) UILabel *titleViewPlaceholder; // compact placeholder for title view
@property (nonatomic, strong) UIView *titleViewOriginal;     // original full size title view
@property (nonatomic, strong) NSArray *leftBarButtonItems;
@property (nonatomic, strong) NSArray *rightBarButtonItems;
@property (nonatomic) BOOL dragStart;
@property (nonatomic) CGFloat previousYOffset;
@property (nonatomic, strong) UITapGestureRecognizer *recognizer;

@end


@implementation IPNavBarSqueezableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Set up scroll to squeeze
    self.navBarStatus = IPNavBarSqueezingStatusNormal;
    self.dragStart = NO;

    // Set up title view
    self.titleViewOriginal = self.navigationItem.titleView;
    self.titleViewPlaceholder = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f,
                                                                          SCREEN_WIDTH * 220.f / 320.f,
                                                                          kStatusBarHeight)];
    self.titleViewPlaceholder.textAlignment = NSTextAlignmentCenter;
    self.titleViewPlaceholder.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleViewPlaceholder.textColor = self.titleColor ? self.titleColor
                                                          : self.navigationController.navigationBar.tintColor;
    // Recognize tap on nav bar
    self.recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(navBarTapped:)];
    self.recognizer.numberOfTapsRequired = 1;

    // Swipe to pop
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(swippedToPop:)];
    recognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:recognizer];

    [self.navigationController setToolbarHidden:NO
                                       animated:NO];
}

- (void)swippedToPop:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Set up font
    if (!self.titleFont) {
        UIFont *navigationBarTitleFont =
        (UIFont *)self.navigationController.navigationBar.titleTextAttributes[NSFontAttributeName];
        self.titleFont = navigationBarTitleFont ? [UIFont systemFontOfSize:navigationBarTitleFont.pointSize]
                                                : [UIFont systemFontOfSize:17.f];
    }
    [self.transitionCoordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         if ([context presentationStyle] == UIModalPresentationNone){
             self.titleViewPlaceholder.frame = CGRectOffset(self.titleViewPlaceholder.frame, -200.f, 0.f);
         }
     } completion:nil];

    self.navigationItem.hidesBackButton = NO;
    self.navigationController.toolbarHidden = NO;

    self.triggeringScrollView.contentInset = UIEdgeInsetsMake(NAVBAR_HEIGHT + kStatusBarHeight,
                                                              0.f,
                                                              TOOLBAR_HEIGHT,
                                                              0.f);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Unsqueeze manually
    self.navigationController.navigationBar.frame = CGRectMake(0.f,
                                                               kStatusBarHeight,
                                                               SCREEN_WIDTH,
                                                               NAVBAR_HEIGHT);
    [self.navigationController.navigationBar removeGestureRecognizer:self.recognizer];
    self.navBarStatus = IPNavBarSqueezingStatusNormal;

    [self.transitionCoordinator animateAlongsideTransition:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         if ([context presentationStyle] != UIModalPresentationNone) {
             return;
         }
         self.titleViewPlaceholder.alpha = 0.f;
         self.titleViewPlaceholder.frame = CGRectOffset(self.titleViewPlaceholder.frame, 200.f, 0.f);
         [self.navigationController setToolbarHidden:YES
                                             animated:YES];
     } completion:nil];

    [self.transitionCoordinator notifyWhenInteractionEndsUsingBlock:
     ^(id<UIViewControllerTransitionCoordinatorContext> context) {
         if (![context isCancelled]) {
             return;
         }
         double delayInSeconds = 0.5;
         dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,
                                                 (int64_t)(delayInSeconds * NSEC_PER_SEC));
         dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
             if (self.navigationController.toolbarHidden) {
                 self.navigationController.toolbarHidden = NO;
             }
         });
     }];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.titleViewPlaceholder removeFromSuperview];
}

- (void)setTriggeringScrollView:(UIScrollView *)triggeringScrollView
{
    if (self.triggeringScrollView == triggeringScrollView) {
        return;
    }
    self->_triggeringScrollView = triggeringScrollView;
    self->_triggeringScrollView.delegate = self;
    
    // Recognize tap on content
    // TODO: move to property and remove gestures on dealloc
    UITapGestureRecognizer *tapContentRecognizer = [[UITapGestureRecognizer
                                                     alloc] initWithTarget:self
                                                                    action:@selector(navBarTapped:)];
    tapContentRecognizer.numberOfTapsRequired = 1;
    [self.triggeringScrollView addGestureRecognizer:tapContentRecognizer];
}


#pragma mark - Setter methods

- (void)setTitleFont:(UIFont *)titleFont
{
    if ([self.titleFont.familyName isEqualToString:titleFont.familyName]) {
        return;
    }
    self->_titleFont = titleFont;
    self.titleViewPlaceholder.font = self.titleFont;
}

- (void)setTitleColor:(UIColor *)titleColor
{
    if (CGColorEqualToColor(self.titleColor.CGColor, titleColor.CGColor)) {
        return;
    }
    self->_titleColor = titleColor;
    self.titleViewPlaceholder.textColor = self.titleColor;
}


#pragma mark - Scroll View Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
#ifdef DEBUG_SQUEEZE
        NSLog(@"Begin Dragging");
#endif
    if (self.navBarStatus == IPNavBarSqueezingStatusNormal) {
        self.dragStart = YES;
    }
    self.previousYOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.dragStart == NO) {
        return;
    }
    CGFloat delta = scrollView.contentOffset.y - self.previousYOffset;

#ifdef DEBUG_SQUEEZE
        NSLog(@"scroll to offset: %f", scrollView.contentOffset.y);
        NSLog(@"offset delta: %f", delta);
#endif
    switch (self.navBarStatus) {
        case IPNavBarSqueezingStatusNormal: {
            // Squeeze when scroll up higher than a threshold
            CGFloat threshold = 30.f;
            
            if (delta < threshold) {
                return;
            }
                if (delta > 200.f) {
                    [self squeezeBars];
                } else {
                    [self processBars];
                    [self squeezeNavBarWithProgress:delta / 200.f];
                }
        }
            break;
        case IPNavBarSqueezingStatusProgress: {
            [self squeezeNavBarWithProgress:delta / 200.f];
        }
            break;
        default: break;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
#ifdef DEBUG_SQUEEZE
        NSLog(@"End Dragging: (%f,%f) %f", velocity.x, velocity.y, targetContentOffset->y);
#endif
    self.dragStart = NO;
    CGFloat offsetDelta = targetContentOffset->y - self.previousYOffset;

    // Finish squeezing when squeezing is not finished
    if (self.navBarStatus == IPNavBarSqueezingStatusProgress) {
        [self squeezeBars];
    }
    /**
     Un-squeeze only when
       o  scroll up
       o  fast enough
       o  is squeezed
     Or
       o  is squeezed
       o  the target is top edge
     */
    if (self.navBarStatus == IPNavBarSqueezingStatusSqueezed) {
        if (offsetDelta < 0 ||
            fabs((targetContentOffset->y) + 40) < FLT_EPSILON) {
            [self expandBars];
        }
    }
    
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if (self.navBarStatus != IPNavBarSqueezingStatusSqueezed) {
        return YES;
    }
    [self expandBars];
    return NO;
}


#pragma mark - Bars squeezing

- (void)processBars
{
    // for inheritance
}

- (void)squeezeNavBarWithProgress:(CGFloat)delta
{
#ifdef DEBUG_SQUEEZE
    NSLog(@"Progress: %f", delta);
#endif
    CGFloat progress = MIN(delta, 1.f);

    self.navBarStatus = IPNavBarSqueezingStatusProgress;
    
    [self hideBarItemsAnimated:YES];

    self.navigationController.navigationBar.frame = CGRectMake(0.f,
                                                               kStatusBarHeight,
                                                               SCREEN_WIDTH,
                                                               NAVBAR_HEIGHT
                                                               - (NAVBAR_HEIGHT - kSqueezedNavigationBarHeight)
                                                               * progress);
    if (progress < delta) {
        [self squeezeBars];
    }
}

- (void)hideBarItemsAnimated:(BOOL)animated
{
    if (self.navigationItem.leftBarButtonItems.count != 0) {
        self.leftBarButtonItems = [self.navigationItem.leftBarButtonItems copy];
        [self.navigationItem setLeftBarButtonItems:nil
                                          animated:animated];
    }
    if (self.navigationItem.rightBarButtonItems.count != 0) {
        self.rightBarButtonItems = [self.navigationItem.rightBarButtonItems copy];
        [self.navigationItem setRightBarButtonItems:nil
                                           animated:animated];
    }
    if (!self.navigationItem.hidesBackButton) {
        [self.navigationItem setHidesBackButton:YES
                                       animated:animated];
    }
    if (!self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:YES
                                           animated:animated];
    }
}

- (void)showBarItemsAnimated:(BOOL)animated
{
    [self.navigationItem setLeftBarButtonItems:self.leftBarButtonItems
                                      animated:animated];
    [self.navigationItem setRightBarButtonItems:self.rightBarButtonItems
                                       animated:animated];
    [self.navigationItem setHidesBackButton:NO
                                   animated:animated];
    [self.navigationController setToolbarHidden:NO
                                       animated:animated];
}

- (void)squeezeBars
{
#ifdef DEBUG_SQUEEZE
    NSLog(@"Start squeezing");
#endif
    self.navBarStatus = IPNavBarSqueezingStatusSqueezing;
    self.titleViewPlaceholder.text = self.title;
    
    UIView* titleViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f,
                                                                             SCREEN_WIDTH,
                                                                             kStatusBarHeight)];
    self.titleViewPlaceholder.translatesAutoresizingMaskIntoConstraints = NO;
    [titleViewContainer addSubview:self.titleViewPlaceholder];
    
    NSLayoutConstraint *centerXConstraint = [NSLayoutConstraint constraintWithItem:self.titleViewPlaceholder
                                                                         attribute:NSLayoutAttributeCenterX
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:titleViewContainer
                                                                         attribute:NSLayoutAttributeCenterX
                                                                        multiplier:1.0
                                                                          constant:0.0];
    NSLayoutConstraint* topMarginConstraint = [NSLayoutConstraint constraintWithItem:self.titleViewPlaceholder
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:titleViewContainer
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1
                                                                            constant:4];
    NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:self.titleViewPlaceholder attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kStatusBarHeight];
    
    self.navigationItem.titleView = titleViewContainer;
    [titleViewContainer addConstraint:centerXConstraint];
    [titleViewContainer addConstraint:topMarginConstraint];
    [self.titleViewPlaceholder addConstraint:heightConstraint];
    
    [self hideBarItemsAnimated:YES];

    [UIView animateWithDuration:kAnimationDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         CGRect frame = CGRectMake(0.f,
                                                   kStatusBarHeight,
                                                   SCREEN_WIDTH,
                                                   kSqueezedNavigationBarHeight);
                         self.titleViewPlaceholder.transform =
                         CGAffineTransformScale(self.titleViewPlaceholder.transform, 0.75f, 0.75f);

                         self.navigationController.navigationBar.frame = frame;
                     }
                     completion:^(BOOL finished) {
                         [self.navigationController.navigationBar addGestureRecognizer:self.recognizer];
                         self.navigationController.navigationBar.userInteractionEnabled = YES;
                         self.titleViewPlaceholder.userInteractionEnabled = YES;
                         self.triggeringScrollView.contentInset = UIEdgeInsetsMake(kStatusBarHeight
                                                                                   + kSqueezedNavigationBarHeight,
                                                                                   0.f, 0.f, 0.f);
                         self.triggeringScrollView.scrollIndicatorInsets =
                         UIEdgeInsetsMake(kStatusBarHeight
                                          + kSqueezedNavigationBarHeight,
                                          0.f, 0.f, 0.f);
                         self.titleViewPlaceholder.text = [self squeezedTitle:
                                                           self.titleViewPlaceholder.text];
                         if (self.squeezeCompletion) {
                             self.squeezeCompletion();
                         }
#ifdef DEBUG_SQUEEZE
                         NSLog(@"End squeezing");
#endif
                         self.navBarStatus = IPNavBarSqueezingStatusSqueezed;
                     }];
}

- (NSString *)squeezedTitle:(NSString *)title
{
    return [NSString stringWithFormat:@"[ %@ ]", title];
}

- (void)expandBars
{
#ifdef DEBUG_SQUEEZE
    NSLog(@"Start expanding");
#endif
    self.navBarStatus = IPNavBarSqueezingStatusUnSqueezing;
    [self.navigationController.navigationBar removeGestureRecognizer:self.recognizer];
    self.titleViewPlaceholder.text = self.title;

    [UIView animateWithDuration:kAnimationDuration
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.navigationController.navigationBar.frame = CGRectMake(0.f,
                                                                                    kStatusBarHeight,
                                                                                    SCREEN_WIDTH,
                                                                                    NAVBAR_HEIGHT);
                         // title
                         self.titleViewPlaceholder.transform = CGAffineTransformIdentity;

                         self.triggeringScrollView.contentInset =
                         UIEdgeInsetsMake(NAVBAR_HEIGHT
                                          + kStatusBarHeight,
                                          0.f,
                                          TOOLBAR_HEIGHT,
                                          0.f);
                         self.triggeringScrollView.scrollIndicatorInsets =
                         UIEdgeInsetsMake(NAVBAR_HEIGHT
                                          + kStatusBarHeight,
                                          0.f, 0.f, 0.f);
                         self.navigationController.toolbarHidden = NO;
                     }
                     completion:^(BOOL finished) {
                         self.navigationItem.titleView = self.titleViewOriginal;

                         [self showBarItemsAnimated:YES];

                         if (self.expandCompletion) {
                             self.expandCompletion();
                         }
#ifdef DEBUG_SQUEEZE
                         NSLog(@"End expanding");
#endif
                         self.navBarStatus = IPNavBarSqueezingStatusNormal;
                     }];
}

- (void)navBarTapped:(id)sender
{
    if (self.navBarStatus == IPNavBarSqueezingStatusSqueezed) {
        [self expandBars];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration
{
    [self expandBars];
}

@end
