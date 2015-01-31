//
//  IPNavBarSqueezableViewController.h
//  iPTT
//
//  Created by zeta on 13/10/19.
//  Copyright (c) 2013年 shotdoor. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface IPNavBarSqueezableViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIScrollView *triggeringScrollView;

@property (nonatomic, strong) UIFont *titleFont;

@property (nonatomic, copy) void (^squeezeCompletion)(void); // nil by default
@property (nonatomic, copy) void (^expandCompletion)(void); // nil by default

// inheritance
- (void)processBars NS_REQUIRES_SUPER;
- (void)squeezeBars NS_REQUIRES_SUPER;
- (void)expandBars NS_REQUIRES_SUPER;

- (NSString *)squeezedTitle:(NSString *)title; // @"[ %@ ]" by default

@end
