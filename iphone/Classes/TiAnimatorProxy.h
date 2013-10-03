/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#ifdef USE_TI_UIIOSANIMATOR
#import "TiProxy.h"
#import "TiViewProxy.h"

@protocol TiBehaviorProtocol
@required
-(UIDynamicBehavior*)behaviorObject;
-(void)updateItems;
-(void)updatePositioning;
@end

@interface TiAnimatorProxy : TiProxy<UIDynamicAnimatorDelegate> {
    TiViewProxy * _referenceView;
    NSMutableArray* _behaviors;
    UIDynamicAnimator *theAnimator;
}

#pragma mark - Public API
-(NSNumber*)running;
-(TiViewProxy*) referenceView;
-(NSArray*)behaviors;
-(void)setReferenceView:(id)args;
-(void)setBehaviors:(id)args;
-(void)addBehavior:(id)args;
-(void)removeBehavior:(id)args;
-(void)removeAllBehaviors:(id)unused;
-(void)startAnimator:(id)unused;
-(void)stopAnimator:(id)unused;

@end


#endif