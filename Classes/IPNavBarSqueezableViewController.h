//
//  IPNavBarSqueezableViewController.h
//  iPTT
//
//  Created by zeta on 13/10/19.
//  Copyright (c) 2013年 shotdoor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IPNavBarSqueezableViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIScrollView* triggeringScrollView;
@property (nonatomic, strong) UIBarButtonItem* ip_rightNavBarItem;

@end
