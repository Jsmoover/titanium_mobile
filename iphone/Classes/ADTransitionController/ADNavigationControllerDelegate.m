//
//  ADNavigationControllerDelegate.m
//  ADTransitionController
//
//  Created by Patrick Nollet on 09/10/13.
//  Copyright (c) 2013 Applidium. All rights reserved.
//

#import "ADNavigationControllerDelegate.h"
#import "ADTransitioningDelegate.h"

@implementation ADPercentDrivenInteractiveTransition

- (void)cancelInteractiveTransition {
    [[self transitionDelegate] setCancelled:YES];
    [super cancelInteractiveTransition];
}


@end

@implementation ADNavigationControllerDelegate

- (id <UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                          interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>) animationController {
    if ([animationController isKindOfClass:[ADTransitioningDelegate class]]) {
        self.interactivePopTransition.transitionDelegate = (ADTransitioningDelegate*)animationController;
        self.interactivePopTransition.transitionDelegate.cancelled = NO;
        return self.interactivePopTransition;
    }
    return nil;
}

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC {
    switch (operation) {
        case UINavigationControllerOperationPush:
            if ([toVC.transitioningDelegate respondsToSelector:@selector(animationControllerForPresentedController:presentingController:sourceController:)]) {
                ADTransitioningDelegate * delegate = (ADTransitioningDelegate *)toVC.transitioningDelegate;
                delegate.transition.type = ADTransitionTypePush;
                return delegate;
            } else {
                return nil;
            }
        case UINavigationControllerOperationPop:
            if ([fromVC.transitioningDelegate respondsToSelector:@selector(animationControllerForDismissedController:)]){
                ADTransitioningDelegate * delegate = (ADTransitioningDelegate *)fromVC.transitioningDelegate;
                delegate.transition.type = ADTransitionTypePop;
                return delegate;
            } else {
                return nil;
            }
        default:
            return nil;
    }
}
@end
