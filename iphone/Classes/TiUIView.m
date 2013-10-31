/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiBase.h"
#import "TiUIView.h"
#import "TiColor.h"
#import "TiRect.h"
#import "TiUtils.h"
#import "ImageLoader.h"
#ifdef USE_TI_UI2DMATRIX	
	#import "Ti2DMatrix.h"
#endif
#if defined(USE_TI_UIIOS3DMATRIX) || defined(USE_TI_UI3DMATRIX)
	#import "Ti3DMatrix.h"
#endif
#import "TiViewProxy.h"
#import "TiApp.h"
#import "UIImage+Resize.h"
#import "TiUIHelper.h"
#import "TiSVGImage.h"
#import "TiImageHelper.h"
#import "TiTransition.h"


void InsetScrollViewForKeyboard(UIScrollView * scrollView,CGFloat keyboardTop,CGFloat minimumContentHeight)
{
	VerboseLog(@"ScrollView:%@, keyboardTop:%f minimumContentHeight:%f",scrollView,keyboardTop,minimumContentHeight);

	CGRect scrollVisibleRect = [scrollView convertRect:[scrollView bounds] toView:[[TiApp app] topMostView]];
	//First, find out how much we have to compensate.

	CGFloat obscuredHeight = scrollVisibleRect.origin.y + scrollVisibleRect.size.height - keyboardTop;	
	//ObscuredHeight is how many vertical pixels the keyboard obscures of the scroll view. Some of this may be acceptable.

	CGFloat unimportantArea = MAX(scrollVisibleRect.size.height - minimumContentHeight,0);
	//It's possible that some of the covered area doesn't matter. If it all matters, unimportant is 0.

	//As such, obscuredHeight is now how much actually matters of scrollVisibleRect.

	CGFloat bottomInset = MAX(0,obscuredHeight-unimportantArea);
	[scrollView setContentInset:UIEdgeInsetsMake(0, 0, bottomInset, 0)];

	CGPoint offset = [scrollView contentOffset];

	if(offset.y + bottomInset < 0 )
	{
		offset.y = -bottomInset;
		[scrollView setContentOffset:offset animated:YES];
	}

	VerboseLog(@"ScrollVisibleRect(%f,%f),%fx%f; obscuredHeight:%f; unimportantArea:%f",
			scrollVisibleRect.origin.x,scrollVisibleRect.origin.y,scrollVisibleRect.size.width,scrollVisibleRect.size.height,
			obscuredHeight,unimportantArea);
}

void OffsetScrollViewForRect(UIScrollView * scrollView,CGFloat keyboardTop,CGFloat minimumContentHeight,CGRect responderRect)
{
	VerboseLog(@"ScrollView:%@, keyboardTop:%f minimumContentHeight:%f responderRect:(%f,%f),%fx%f;",
			scrollView,keyboardTop,minimumContentHeight,
			responderRect.origin.x,responderRect.origin.y,responderRect.size.width,responderRect.size.height);

	CGRect scrollVisibleRect = [scrollView convertRect:[scrollView bounds] toView:[[TiApp app] topMostView]];
	//First, find out how much we have to compensate.

	CGFloat obscuredHeight = scrollVisibleRect.origin.y + scrollVisibleRect.size.height - keyboardTop;	
	//ObscuredHeight is how many vertical pixels the keyboard obscures of the scroll view. Some of this may be acceptable.

	//It's possible that some of the covered area doesn't matter. If it all matters, unimportant is 0.

	//As such, obscuredHeight is now how much actually matters of scrollVisibleRect.

	VerboseLog(@"ScrollVisibleRect(%f,%f),%fx%f; obscuredHeight:%f;",
			scrollVisibleRect.origin.x,scrollVisibleRect.origin.y,scrollVisibleRect.size.width,scrollVisibleRect.size.height,
			obscuredHeight);

	scrollVisibleRect.size.height -= MAX(0,obscuredHeight);

	//Okay, the scrollVisibleRect.size now represents the actually visible area.

	CGPoint offsetPoint = [scrollView contentOffset];

	CGPoint offsetForBottomRight;
	offsetForBottomRight.x = responderRect.origin.x + responderRect.size.width - scrollVisibleRect.size.width;
	offsetForBottomRight.y = responderRect.origin.y + responderRect.size.height - scrollVisibleRect.size.height;

	offsetPoint.x = MIN(responderRect.origin.x,MAX(offsetPoint.x,offsetForBottomRight.x));
	offsetPoint.y = MIN(responderRect.origin.y,MAX(offsetPoint.y,offsetForBottomRight.y));
	VerboseLog(@"OffsetForBottomright:(%f,%f) OffsetPoint:(%f,%f)",
			offsetForBottomRight.x, offsetForBottomRight.y, offsetPoint.x, offsetPoint.y);

	CGFloat maxOffset = [scrollView contentInset].bottom + [scrollView contentSize].height - scrollVisibleRect.size.height;
	
	if(maxOffset < offsetPoint.y)
	{
		offsetPoint.y = MAX(0,maxOffset);
	}

	[scrollView setContentOffset:offsetPoint animated:YES];
}

void ModifyScrollViewForKeyboardHeightAndContentHeightWithResponderRect(UIScrollView * scrollView,CGFloat keyboardTop,CGFloat minimumContentHeight,CGRect responderRect)
{
	VerboseLog(@"ScrollView:%@, keyboardTop:%f minimumContentHeight:%f responderRect:(%f,%f),%fx%f;",
			scrollView,keyboardTop,minimumContentHeight,
			responderRect.origin.x,responderRect.origin.y,responderRect.size.width,responderRect.size.height);

	CGRect scrollVisibleRect = [scrollView convertRect:[scrollView bounds] toView:[[TiApp app] topMostView]];
	//First, find out how much we have to compensate.

	CGFloat obscuredHeight = scrollVisibleRect.origin.y + scrollVisibleRect.size.height - keyboardTop;	
	//ObscuredHeight is how many vertical pixels the keyboard obscures of the scroll view. Some of this may be acceptable.

	CGFloat unimportantArea = MAX(scrollVisibleRect.size.height - minimumContentHeight,0);
	//It's possible that some of the covered area doesn't matter. If it all matters, unimportant is 0.

	//As such, obscuredHeight is now how much actually matters of scrollVisibleRect.

	[scrollView setContentInset:UIEdgeInsetsMake(0, 0, MAX(0,obscuredHeight-unimportantArea), 0)];

	VerboseLog(@"ScrollVisibleRect(%f,%f),%fx%f; obscuredHeight:%f; unimportantArea:%f",
			scrollVisibleRect.origin.x,scrollVisibleRect.origin.y,scrollVisibleRect.size.width,scrollVisibleRect.size.height,
			obscuredHeight,unimportantArea);

	scrollVisibleRect.size.height -= MAX(0,obscuredHeight);

	//Okay, the scrollVisibleRect.size now represents the actually visible area.

	CGPoint offsetPoint = [scrollView contentOffset];

	if(!CGRectIsEmpty(responderRect))
	{
		CGPoint offsetForBottomRight;
		offsetForBottomRight.x = responderRect.origin.x + responderRect.size.width - scrollVisibleRect.size.width;
		offsetForBottomRight.y = responderRect.origin.y + responderRect.size.height - scrollVisibleRect.size.height;
	
		offsetPoint.x = MIN(responderRect.origin.x,MAX(offsetPoint.x,offsetForBottomRight.x));
		offsetPoint.y = MIN(responderRect.origin.y,MAX(offsetPoint.y,offsetForBottomRight.y));
		VerboseLog(@"OffsetForBottomright:(%f,%f) OffsetPoint:(%f,%f)",
				offsetForBottomRight.x, offsetForBottomRight.y, offsetPoint.x, offsetPoint.y);
	}
	else
	{
		offsetPoint.x = MAX(0,offsetPoint.x);
		offsetPoint.y = MAX(0,offsetPoint.y);
		VerboseLog(@"OffsetPoint:(%f,%f)",offsetPoint.x, offsetPoint.y);
	}

	[scrollView setContentOffset:offsetPoint animated:YES];
}

NSArray* listenerArray = nil;

@interface TiUIView () {
    TiSelectableBackgroundLayer* _bgLayer;
    BOOL _shouldHandleSelection;
    BOOL _customUserInteractionEnabled;
    BOOL _touchEnabled;
}
-(void)setBackgroundDisabledImage_:(id)value;
-(void)setBackgroundSelectedImage_:(id)value;
-(void)sanitycheckListeners;
@end

@interface TiUIView(Private)
-(void)renderRepeatedBackground:(id)image;
@end

@implementation TiUIView

DEFINE_EXCEPTIONS

#define kTOUCH_MAX_DIST 70

@synthesize proxy,touchDelegate,oldSize, backgroundLayer = _bgLayer, shouldHandleSelection = _shouldHandleSelection, animateBgdTransition;

#pragma mark Internal Methods

#if VIEW_DEBUG
-(id)retain
{
	[super retain];
	NSLog(@"[VIEW %@] RETAIN: %d", self, [self retainCount]);
}

-(oneway void)release
{
	NSLog(@"[VIEW %@] RELEASE: %d", self, [self retainCount]-1);
	[super release];
}
#endif

-(void)dealloc
{
    [childViews release];
    [transferLock release];
	[transformMatrix release];
	[animation release];
	[_bgLayer release];
	[singleTapRecognizer release];
	[doubleTapRecognizer release];
	[twoFingerTapRecognizer release];
	[pinchRecognizer release];
	[leftSwipeRecognizer release];
	[rightSwipeRecognizer release];
	[upSwipeRecognizer release];
	[downSwipeRecognizer release];
	[longPressRecognizer release];
	proxy = nil;
	touchDelegate = nil;
	childViews = nil;
	[super dealloc];
}

-(void)detach
{
    if (proxy != nil && [(TiViewProxy*)proxy view] == self)
    {
        [(TiViewProxy*)proxy detachView];
    }
    else {
        NSArray* subviews = [self subviews];
        for (UIView* subview in subviews) {
            if([subview isKindOfClass:[TiUIView class]])
            {
                [(TiUIView*)subview detach];
                
            }
            else {
                [subview removeFromSuperview];
            }
        }
        [self cancelAllAnimations];
        [self removeFromSuperview];
        self.proxy = nil;
        self.touchDelegate = nil;
    }
}

-(void)removeFromSuperview
{
	if ([NSThread isMainThread])
	{
		[super removeFromSuperview];
	}
	else 
	{
		TiThreadPerformOnMainThread(^{[super removeFromSuperview];}, YES);
	}
}

- (void) initialize
{
    childViews  =[[NSMutableArray alloc] init];
    transferLock = [[NSRecursiveLock alloc] init];
    touchPassThrough = NO;
    _shouldHandleSelection = YES;
    self.clipsToBounds = clipChildren = YES;
    self.userInteractionEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    backgroundOpacity = 1.0f;
    _customUserInteractionEnabled = YES;
    _touchEnabled = YES;
    animateBgdTransition = NO;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
        [self initialize];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self != nil)
	{
        [self initialize];
	}
	return self;
}

-(BOOL)viewSupportsBaseTouchEvents
{
	// give the ability for the subclass to turn off our event handling
	// if it wants too
	return YES;
}

-(void)ensureGestureListeners
{
    if ([(TiViewProxy*)proxy _hasListeners:@"swipe"]) {
        [[self gestureRecognizerForEvent:@"uswipe"] setEnabled:YES];
        [[self gestureRecognizerForEvent:@"dswipe"] setEnabled:YES];
        [[self gestureRecognizerForEvent:@"rswipe"] setEnabled:YES];
        [[self gestureRecognizerForEvent:@"lswipe"] setEnabled:YES];
    }
    if ([(TiViewProxy*)proxy _hasListeners:@"pinch"]) {
         [[self gestureRecognizerForEvent:@"pinch"] setEnabled:YES];
    }
    if ([(TiViewProxy*)proxy _hasListeners:@"longpress"]) {
        [[self gestureRecognizerForEvent:@"longpress"] setEnabled:YES];
    }
}

-(BOOL)proxyHasTapListener
{
	return [proxy _hasAnyListeners:[NSArray arrayWithObjects:@"singletap", @"doubletap", @"twofingertap", nil]];
}

-(BOOL)proxyHasTouchListener
{
	return [proxy _hasAnyListeners:[NSArray arrayWithObjects:@"touchstart", @"touchcancel", @"touchend", @"touchmove", @"click", @"dblclick", nil]];
}

-(BOOL) proxyHasGestureListeners
{
	return [proxy _hasAnyListeners:[NSArray arrayWithObjects:@"swipe", @"pinch", @"longpress", nil]];
}

-(void)updateTouchHandling
{
    BOOL touchEventsSupported = [self viewSupportsBaseTouchEvents];
    handlesTouches = touchEventsSupported && (
                [self proxyHasTouchListener]
                || [self proxyHasTapListener]
                || [self proxyHasGestureListeners]);
    [self ensureGestureListeners];
    // If a user has not explicitly set whether or not the view interacts, base it on whether or
    // not it handles events, and if not, set it to the interaction default.
    if (!changedInteraction) {
        _customUserInteractionEnabled = handlesTouches || [self interactionDefault];
    }
}

-(void)initializeState
{
	
	[self updateTouchHandling];
	 
	self.backgroundColor = [UIColor clearColor]; 
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

-(void)configurationStart
{
    configurationSet = needsToSetBackgroundImage = needsToSetBackgroundDisabledImage = needsToSetBackgroundSelectedImage = NO;
}

-(void)configurationSet
{
	// can be used to trigger things after all properties are set
    configurationSet = YES;
    if (needsToSetBackgroundImage)
        [self setBackgroundImage_:[[self proxy] valueForKey:@"backgroundImage"]];
    if (needsToSetBackgroundDisabledImage)
        [self setBackgroundDisabledImage_:[[self proxy] valueForKey:@"backgroundDisabledImage"]];
    if (needsToSetBackgroundSelectedImage)
        [self setBackgroundSelectedImage_:[[self proxy] valueForKey:@"backgroundSelectedImage"]];
    if (_bgLayer) {
        _bgLayer.readyToCreateDrawables = YES;
    }
}

-(void)setProxy:(TiProxy *)p
{
	proxy = p;
	[proxy setModelDelegate:self];
	[self sanitycheckListeners];
}

-(id)transformMatrix
{
	return transformMatrix;
}

- (id)accessibilityElement
{
	return self;
}

#pragma mark - Accessibility API

- (void)setAccessibilityLabel_:(id)accessibilityLabel
{
	id accessibilityElement = self.accessibilityElement;
	if (accessibilityElement != nil) {
		[accessibilityElement setIsAccessibilityElement:YES];
		[accessibilityElement setAccessibilityLabel:[TiUtils stringValue:accessibilityLabel]];
	}
}

- (void)setAccessibilityValue_:(id)accessibilityValue
{
	id accessibilityElement = self.accessibilityElement;
	if (accessibilityElement != nil) {
		[accessibilityElement setIsAccessibilityElement:YES];
		[accessibilityElement setAccessibilityValue:[TiUtils stringValue:accessibilityValue]];
	}
}

- (void)setAccessibilityHint_:(id)accessibilityHint
{
	id accessibilityElement = self.accessibilityElement;
	if (accessibilityElement != nil) {
		[accessibilityElement setIsAccessibilityElement:YES];
		[accessibilityElement setAccessibilityHint:[TiUtils stringValue:accessibilityHint]];
	}
}

- (void)setAccessibilityHidden_:(id)accessibilityHidden
{
	if ([TiUtils isIOS5OrGreater]) {
		self.accessibilityElementsHidden = [TiUtils boolValue:accessibilityHidden def:NO];
	}
}

#pragma mark Layout 

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    
    if (_bgLayer) {
        _bgLayer.frame = bounds;
    }
    if (self.layer.mask != nil) {
        [self.layer.mask setFrame:bounds];
    }
    [self updateTransform];
    [self updateViewShadowPath];
}


-(void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
	// this happens when a view is added to another view but not
	// through the framework (such as a tableview header) and it
	// means we need to force the layout of our children
	if (childrenInitialized==NO && 
		CGRectIsEmpty(frame)==NO &&
		[self.proxy isKindOfClass:[TiViewProxy class]])
	{
		childrenInitialized=YES;
		[(TiViewProxy*)self.proxy layoutChildren:NO];
	}
}


-(void)updateBounds:(CGRect)newBounds
{
    //TIMOB-11197, TC-1264
    [CATransaction begin];
    if (!animating) {
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    }
    else {
        [CATransaction setAnimationDuration:[animation animationDuration]];
        [CATransaction setAnimationTimingFunction:[animation timingFunction] ];
    }
    
    [self frameSizeChanged:[TiUtils viewPositionRect:self] bounds:newBounds];
    [CATransaction commit];
}


-(void)checkBounds
{
    CGRect newBounds = [self bounds];
    if(!CGSizeEqualToSize(oldSize, newBounds.size)) {
        [self updateBounds:newBounds];
        oldSize = newBounds.size;
    }
}



-(void)setBounds:(CGRect)bounds
{
	[super setBounds:bounds];
	[self checkBounds];
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	[self checkBounds];
}


- (void)didMoveToSuperview
{
	[self updateTransform];
	[super didMoveToSuperview];
}

-(void)updateTransform
{
#ifdef USE_TI_UI2DMATRIX	
	if ([transformMatrix isKindOfClass:[Ti2DMatrix class]] && self.superview != nil)
	{
        CGSize size = self.bounds.size;
        CGSize parentSize = self.superview.bounds.size;
		self.transform = [(Ti2DMatrix*)transformMatrix matrixInViewSize:size andParentSize:parentSize];
		return;
	}
#endif
#if defined(USE_TI_UIIOS3DMATRIX) || defined(USE_TI_UI3DMATRIX)
	if ([transformMatrix isKindOfClass:[Ti3DMatrix class]])
	{
		self.layer.transform = [(Ti3DMatrix*)transformMatrix matrix];
		return;
	}
#endif
	self.transform = CGAffineTransformIdentity;
}

-(void)fillBoundsToRect:(TiRect*)rect
{
	CGRect r = [self bounds];
	[rect setRect:r];
}

-(void)fillFrameToRect:(TiRect*)rect
{
	CGRect r = [self frame];
	[rect setRect:r];
}

#pragma mark Public APIs

-(void)setTintColor_:(id)color
{
    if ([TiUtils isIOS7OrGreater]) {
        TiColor *ticolor = [TiUtils colorValue:color];
        [self performSelector:@selector(setTintColor:) withObject:[ticolor _color]];
    }
}

-(TiSelectableBackgroundLayer*)getOrCreateCustomBackgroundLayer
{
    if (_bgLayer != nil) {
        return _bgLayer;
    }

    _bgLayer = [[TiSelectableBackgroundLayer alloc] init];
    [[[self backgroundWrapperView] layer] insertSublayer:_bgLayer atIndex:0];
    _bgLayer.frame = [[self backgroundWrapperView] layer].bounds;
    
    _bgLayer.opacity = backgroundOpacity;
    _bgLayer.cornerRadius = self.layer.cornerRadius;
    _bgLayer.readyToCreateDrawables = configurationSet;
    _bgLayer.animateTransition = animateBgdTransition;
    return _bgLayer;
}

-(CALayer*)backgroundLayer
{
    return _bgLayer;
}

-(void) setBackgroundGradient_:(id)newGradientDict
{
    TiGradient * newGradient = [TiGradient gradientFromObject:newGradientDict proxy:self.proxy];
    [[self getOrCreateCustomBackgroundLayer] setGradient:newGradient forState:UIControlStateNormal];
}

-(void) setBackgroundSelectedGradient_:(id)newGradientDict
{
    TiGradient * newGradient = [TiGradient gradientFromObject:newGradientDict proxy:self.proxy];
    [[self getOrCreateCustomBackgroundLayer] setGradient:newGradient forState:UIControlStateSelected];
    [[self getOrCreateCustomBackgroundLayer] setGradient:newGradient forState:UIControlStateHighlighted];
}

-(void) setBackgroundHighlightedGradient_:(id)newGradientDict
{
    TiGradient * newGradient = [TiGradient gradientFromObject:newGradientDict proxy:self.proxy];
    [[self getOrCreateCustomBackgroundLayer] setGradient:newGradient forState:UIControlStateHighlighted];
}

-(void) setBackgroundDisabledGradient_:(id)newGradientDict
{
    TiGradient * newGradient = [TiGradient gradientFromObject:newGradientDict proxy:self.proxy];
    [[self getOrCreateCustomBackgroundLayer] setGradient:newGradient forState:UIControlStateDisabled];
}

-(void) setBackgroundColor_:(id)color
{
    UIColor* uicolor;
	if ([color isKindOfClass:[UIColor class]])
	{
        uicolor = (UIColor*)color;
	}
	else
	{
		uicolor = [[TiUtils colorValue:color] _color];
	}
    if (backgroundOpacity < 1.0f) {
        const CGFloat* components = CGColorGetComponents(uicolor.CGColor);
        float alpha = CGColorGetAlpha(uicolor.CGColor) * backgroundOpacity;
        uicolor = [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:alpha];
    }
    super.backgroundColor = uicolor;
}

-(void) setBackgroundSelectedColor_:(id)color
{
    UIColor* uiColor = [TiUtils colorValue:color].color;
    [[self getOrCreateCustomBackgroundLayer] setColor:uiColor forState:UIControlStateSelected];
    [[self getOrCreateCustomBackgroundLayer] setColor:uiColor forState:UIControlStateHighlighted];
}

-(void) setBackgroundHighlightedColor_:(id)color
{
    UIColor* uiColor = [TiUtils colorValue:color].color;
    [[self getOrCreateCustomBackgroundLayer] setColor:uiColor forState:UIControlStateHighlighted];
}

-(void) setBackgroundDisabledColor_:(id)color
{
    UIColor* uiColor = [TiUtils colorValue:color].color;
    [[self getOrCreateCustomBackgroundLayer] setColor:uiColor forState:UIControlStateDisabled];
}

-(UIImage*)convertToUIImage:(id)arg
{
	if (arg==nil) return nil;
    UIImage *image = nil;
	
    if ([arg isKindOfClass:[TiBlob class]]) {
        TiBlob *blob = (TiBlob*)arg;
        image = [blob image];
    }
    else if ([arg isKindOfClass:[TiFile class]]) {
        NSURL *url = [TiUtils toURL:arg proxy:proxy];
        image = [[ImageLoader sharedLoader] loadImmediateImage:url];
    }
    else if ([arg isKindOfClass:[UIImage class]]) {
		// called within this class
        image = (UIImage*)arg;
    }
    return image;
}


-(id)loadImageOrSVG:(id)arg
{
    if (arg==nil) return nil;
	if (TiDimensionIsUndefined(leftCap) && TiDimensionIsUndefined(topCap) &&
        TiDimensionIsUndefined(rightCap) && TiDimensionIsUndefined(bottomCap)) {
        return [TiUtils loadBackgroundImage:arg forProxy:proxy];
    }
    else {
        return [TiUtils loadBackgroundImage:arg forProxy:proxy withLeftCap:leftCap topCap:topCap rightCap:rightCap bottomCap:bottomCap];
    }
	return nil;
}
-(UIImage*)loadImage:(id)arg
{
    if (arg==nil) return nil;
    id result = nil;
	if (TiDimensionIsUndefined(leftCap) && TiDimensionIsUndefined(topCap) &&
        TiDimensionIsUndefined(rightCap) && TiDimensionIsUndefined(bottomCap)) {
        result =  [TiUtils loadBackgroundImage:arg forProxy:proxy];
    }
    else {
        result =  [TiUtils loadBackgroundImage:arg forProxy:proxy withLeftCap:leftCap topCap:topCap rightCap:rightCap bottomCap:bottomCap];
    }
    if ([result isKindOfClass:[UIImage class]]) return result;
    else if ([result isKindOfClass:[TiSVGImage class]]) return [((TiSVGImage*)result) fullImage];
	return nil;
}

-(void) setBackgroundImage_:(id)image
{
    if (!configurationSet) {
        needsToSetBackgroundImage = YES;
        return;
    }
    [[self getOrCreateCustomBackgroundLayer] setImage:[self loadImageOrSVG:image] forState:UIControlStateNormal];
}

-(void) setBackgroundSelectedImage_:(id)arg
{
    if (!configurationSet) {
        needsToSetBackgroundSelectedImage = YES;
        return;
    }
    id image = [self loadImageOrSVG:arg];
    [[self getOrCreateCustomBackgroundLayer] setImage:image forState:UIControlStateHighlighted];
    [[self getOrCreateCustomBackgroundLayer] setImage:image forState:UIControlStateSelected];
}

-(void) setBackgroundHighlightedImage_:(id)image
{
    if (!configurationSet) {
        needsToSetBackgroundSelectedImage = YES;
        return;
    }
    [[self getOrCreateCustomBackgroundLayer] setImage:[self loadImageOrSVG:image] forState:UIControlStateHighlighted];
}

-(void) setBackgroundDisabledImage_:(id)image
{
    if (!configurationSet) {
        needsToSetBackgroundDisabledImage = YES;
        return;
    }
    [[self getOrCreateCustomBackgroundLayer] setImage:[self loadImageOrSVG:image] forState:UIControlStateSelected];
}

-(void)setOpacity_:(id)opacity
{
 	ENSURE_UI_THREAD_1_ARG(opacity);
	self.alpha = [TiUtils floatValue:opacity];
}

-(void)setBackgroundRepeat_:(id)repeat
{
    [self getOrCreateCustomBackgroundLayer].imageRepeat = [TiUtils boolValue:repeat def:NO];
}

-(void)setBackgroundOpacity_:(id)opacity
{
    backgroundOpacity = [TiUtils floatValue:opacity def:1.0f];
    
    id value = [proxy valueForKey:@"backgroundColor"];
    if (value!=nil) {
        [self setBackgroundColor_:value];
    }

    if (_bgLayer) {
        _bgLayer.opacity = backgroundOpacity;
    }
}

-(void)setImageCap_:(id)arg
{
    ENSURE_SINGLE_ARG(arg,NSDictionary);
    NSDictionary* dict = (NSDictionary*)arg;
    if ([dict objectForKey:@"left"]) {
        leftCap = TiDimensionFromObject([dict objectForKey:@"left"]);
    }
    if ([dict objectForKey:@"right"]) {
        rightCap = TiDimensionFromObject([dict objectForKey:@"right"]);
    }
    if ([dict objectForKey:@"top"]) {
        topCap = TiDimensionFromObject([dict objectForKey:@"top"]);
    }
    if ([dict objectForKey:@"bottom"]) {
        bottomCap = TiDimensionFromObject([dict objectForKey:@"bottom"]);
    }
}


-(void)setBorderRadius_:(id)radius
{
	self.layer.cornerRadius = [TiUtils floatValue:radius];
    if (_bgLayer) {
        _bgLayer.cornerRadius = self.layer.cornerRadius;
    }
    [self updateViewShadowPath];
}


-(void)setBorderColor_:(id)color
{
	TiColor *ticolor = [TiUtils colorValue:color];
	self.layer.borderWidth = MAX(self.layer.borderWidth,1);
	self.layer.borderColor = [ticolor _color].CGColor;
}

-(void)setBorderWidth_:(id)w
{
	self.layer.borderWidth = TiDimensionCalculateValueFromString([TiUtils stringValue:w]);
}

-(void)setAnchorPoint_:(id)point
{
	self.layer.anchorPoint = [TiUtils pointValue:point];
}

-(void)setTransform_:(id)transform_
{
	RELEASE_TO_NIL(transformMatrix);
	transformMatrix = [transform_ retain];
	[self updateTransform];
}

-(void)setCenter_:(id)point
{
	self.center = [TiUtils pointValue:point];
}

-(void)setVisible_:(id)visible
{
  	ENSURE_UI_THREAD_1_ARG(visible);
    BOOL oldVal = self.hidden;
    BOOL newVal = ![TiUtils boolValue:visible];
    
    
    if (newVal == oldVal) return;
    
    self.hidden = newVal;
	//TODO: If we have an animated show, hide, or setVisible, here's the spot for it.
    TiViewProxy* viewProxy = (TiViewProxy*)[self proxy];
	
	if(viewProxy.parentVisible)
	{
		if (newVal)
		{
			[viewProxy willHide];
            [viewProxy refreshView:nil];
		}
		else
		{
            [viewProxy refreshView:nil];
			[viewProxy willShow];
            //Redraw ourselves if changing from invisible to visible, to handle any changes made
		}
	}
    
//    //Redraw ourselves if changing from invisible to visible, to handle any changes made
//	if (!self.hidden && oldVal) {
//        [viewProxy willEnqueue];
//    }
}

-(void)setBgState:(UIControlState)state
{
    if (_bgLayer != nil) {
        [_bgLayer setState:state];
    }
}

-(UIControlState)getBgState
{
    if (_bgLayer != nil) {
        return [_bgLayer getState];
    }
    return UIControlStateNormal;
}

-(void)setTouchEnabled_:(id)arg
{
	_touchEnabled = [TiUtils boolValue:arg def:YES];
}

-(void)setEnabled_:(id)arg
{
	_customUserInteractionEnabled = [TiUtils boolValue:arg def:[self interactionDefault]];
    [self setBgState:[self realStateForState:UIControlStateNormal]];
    changedInteraction = YES;
}

-(BOOL) touchEnabled {
	return _touchEnabled;
}

-(void)setTouchPassThrough_:(id)arg
{
	touchPassThrough = [TiUtils boolValue:arg];
}

-(BOOL)touchPassThrough {
    return touchPassThrough;
}

-(UIView *)backgroundWrapperView
{
	return self;
}


-(void)setClipChildren_:(id)arg
{
    clipChildren = [TiUtils boolValue:arg];
    self.clipsToBounds = [self clipChildren];
}

-(BOOL)clipChildren
{
    return (clipChildren && ([[self shadowLayer] shadowOpacity] == 0));

}


-(CALayer *)shadowLayer
{
	return [self layer];
}


-(void)setViewShadow_:(id)arg
{
    ENSURE_SINGLE_ARG(arg,NSDictionary);
    [TiUIHelper applyShadow:arg toLayer:[self shadowLayer]];
    [self updateViewShadowPath];
}

-(void)updateViewShadowPath
{
    if ([[self shadowLayer] shadowOpacity] > 0.0f)
    {
        //to speedup things
        [self shadowLayer].shadowPath =[UIBezierPath bezierPathWithRoundedRect:[self bounds] cornerRadius:self.layer.cornerRadius].CGPath;
    }
}

-(NSArray*) childViews
{
    return [NSArray arrayWithArray:childViews];
}

-(void)didAddSubview:(UIView*)view
{
    if ([view isKindOfClass:[TiUIView class]])
    {
        [childViews addObject:view];
    }
	// So, it turns out that adding a subview places it beneath the gradient layer.
	// Every time we add a new subview, we have to make sure the gradient stays where it belongs..
//    if (_bgLayer != nil) {
//		[[[self backgroundWrapperView] layer] insertSublayer:_bgLayer atIndex:0];
//	}
}

- (void)willRemoveSubview:(UIView *)subview
{
    
    if ([subview isKindOfClass:[TiUIView class]] && childViews)
    {
        [childViews removeObject:subview];
    }
}

-(void)cancelAllAnimations
{
    if (animation != nil) {
        [animation cancel:nil];
        RELEASE_TO_NIL(animation);
    }
    [CATransaction begin];
	[[self layer] removeAllAnimations];
    [[self backgroundLayer] removeAllAnimations];
	[CATransaction commit];
}

-(void)animate:(TiAnimation *)newAnimation
{
	RELEASE_TO_NIL(animation);
	
	if ([self.proxy isKindOfClass:[TiViewProxy class]] && [(TiViewProxy*)self.proxy viewReady]==NO)
	{
		DebugLog(@"[DEBUG] Ti.View.animate() called before view %@ was ready: Will re-attempt", self);
		if (animationDelayGuard++ > 5)
		{
			DebugLog(@"[DEBUG] Animation guard triggered, exceeded timeout to perform animation.");
            animationDelayGuard = 0;
			return;
		}
		[self performSelector:@selector(animate:) withObject:newAnimation afterDelay:0.01];
		return;
	}
	
	animationDelayGuard = 0;
    BOOL resetState = NO;
    if ([self.proxy isKindOfClass:[TiViewProxy class]] && [(TiViewProxy*)self.proxy willBeRelaying]) {
        DeveloperLog(@"RESETTING STATE");
        resetState = YES;
    }
    
    animationDelayGuardForLayout = 0;    

    if (newAnimation != nil) {
        RELEASE_TO_NIL(animation);
        animation = [newAnimation retain];
        animation.resetState = resetState;
        [animation animate:self];
    }
    else {
        DebugLog(@"[WARN] Ti.View.animate() (view %@) could not make animation from: %@", self, newAnimation);
    }
}
-(void)animationStarted
{
    animating = YES;
}
-(void)animationCompleted
{
	animating = NO;
}

-(BOOL)animating
{
	return animating;
}

#pragma mark Property Change Support

-(SEL)selectorForProperty:(NSString*)key
{
	NSString *method = [NSString stringWithFormat:@"set%@%@_:", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]];
	return NSSelectorFromString(method);
}

-(SEL)selectorForlayoutProperty:(NSString*)key
{
	NSString *method = [NSString stringWithFormat:@"set%@%@:", [[key substringToIndex:1] uppercaseString], [key substringFromIndex:1]];
	return NSSelectorFromString(method);
}

-(void)readProxyValuesWithKeys:(id<NSFastEnumeration>)keys
{
	DoProxyDelegateReadValuesWithKeysFromProxy(self, keys, proxy);
}

-(void)propertyChanged:(NSString*)key oldValue:(id)oldValue newValue:(id)newValue proxy:(TiProxy*)proxy_
{
	DoProxyDelegateChangedValuesWithProxy(self, key, oldValue, newValue, proxy_);
}


//Todo: Generalize.
-(void)setKrollValue:(id)value forKey:(NSString *)key withObject:(id)props
{
	if(value == [NSNull null])
	{
		value = nil;
	}

	NSString *method = SetterStringForKrollProperty(key);
    
	SEL methodSel = NSSelectorFromString([method stringByAppendingString:@"withObject:"]);
	if([self respondsToSelector:methodSel])
	{
		[self performSelector:methodSel withObject:value withObject:props];
		return;
	}		

	methodSel = NSSelectorFromString(method);
	if([self respondsToSelector:methodSel])
	{
		[self performSelector:methodSel withObject:value];
	}
}

- (void)detachViewProxy {
    if(!proxy) return;
    self.proxy = nil;
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[TiUIView class]])
            [(TiUIView*)subview detachViewProxy];
    }
}

-(void)transferProxy:(TiViewProxy*)newProxy
{
    [self transferProxy:newProxy deep:NO];
}

-(void)transferProxy:(TiViewProxy*)newProxy deep:(BOOL)deep
{
    [self transferProxy:newProxy withBlockBefore:nil withBlockAfter:nil deep:deep];
}

-(void)transferProxy:(TiViewProxy*)newProxy withBlockBefore:(void (^)(TiViewProxy* proxy))blockBefore
                withBlockAfter:(void (^)(TiViewProxy* proxy))blockAfter deep:(BOOL)deep
{
	TiViewProxy * oldProxy = (TiViewProxy *)[self proxy];
	
	// We can safely skip everything if we're transferring to ourself.
	if (oldProxy != newProxy) {
        
        if(blockBefore)
        {
            blockBefore(newProxy);
        }
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [transferLock lock];
        
        if (deep) {
			NSArray *subProxies = [newProxy children];
			[[oldProxy children] enumerateObjectsUsingBlock:^(TiViewProxy *oldSubProxy, NSUInteger idx, BOOL *stop) {
				TiViewProxy *newSubProxy = idx < [subProxies count] ? [subProxies objectAtIndex:idx] : nil;
				[[oldSubProxy view] transferProxy:newSubProxy withBlockBefore:blockBefore withBlockAfter:blockAfter deep:deep];
			}];
		}
        
        NSSet* transferableProperties = [[oldProxy class] transferableProperties];
        NSMutableSet* oldProperties = [NSMutableSet setWithArray:(NSArray *)[oldProxy allKeys]];
        NSMutableSet* newProperties = [NSMutableSet setWithArray:(NSArray *)[newProxy allKeys]];
        NSMutableSet* keySequence = [NSMutableSet setWithArray:[newProxy keySequence]];
        NSMutableSet* layoutProps = [NSMutableSet setWithArray:[TiViewProxy layoutProperties]];
        [oldProperties minusSet:newProperties];
        [oldProperties minusSet:layoutProps];
        [newProperties minusSet:keySequence];
        [layoutProps intersectSet:newProperties];
        [newProperties intersectSet:transferableProperties];
        [oldProperties intersectSet:transferableProperties];
        
        id<NSFastEnumeration> keySeq = keySequence;
        id<NSFastEnumeration> oldProps = oldProperties;
        id<NSFastEnumeration> newProps = newProperties;
        id<NSFastEnumeration> fastLayoutProps = layoutProps;
        
		[oldProxy retain];
		
        [self configurationStart];
		[newProxy setReproxying:YES];
        
		[oldProxy setView:nil];
		[newProxy setView:self];
        
		[self setProxy:newProxy];

        //The important sequence first:
		for (NSString * thisKey in keySeq)
		{
			id newValue = [newProxy valueForKey:thisKey];
			id oldValue = [oldProxy valueForKey:thisKey];
			if ((oldValue != newValue) && ![oldValue isEqual:newValue]) {
				[self setKrollValue:newValue forKey:thisKey withObject:nil];
			}
		}
        
		for (NSString * thisKey in fastLayoutProps)
		{
			id newValue = [newProxy valueForKey:thisKey];
			id oldValue = [oldProxy valueForKey:thisKey];
			if ((oldValue != newValue) && ![oldValue isEqual:newValue]) {
                SEL selector = [self selectorForlayoutProperty:thisKey];
				if([[self proxy] respondsToSelector:selector])
                {
                    [[self proxy] performSelector:selector withObject:newValue];
                }
			}
		}

		for (NSString * thisKey in oldProps)
		{
			[self setKrollValue:nil forKey:thisKey withObject:nil];
		}

		for (NSString * thisKey in newProps)
		{
			id newValue = [newProxy valueForKey:thisKey];
			id oldValue = [oldProxy valueForKey:thisKey];
			if ((oldValue != newValue) && ![oldValue isEqual:newValue]) {
				[self setKrollValue:newValue forKey:thisKey withObject:nil];
			}
		}
        
        [pool release];
        pool = nil;

        [self configurationSet];
        
		[oldProxy release];
		
		[newProxy setReproxying:NO];

 
        if(blockAfter)
        {
          blockAfter(newProxy);  
        }

        [transferLock unlock];
        
	}
    
}

-(BOOL)validateTransferToProxy:(TiViewProxy*)newProxy deep:(BOOL)deep
{
	TiViewProxy * oldProxy = (TiViewProxy *)[self proxy];
	
	if (oldProxy == newProxy) {
		return YES;
	}    
	if (![newProxy isMemberOfClass:[oldProxy class]]) {
        DebugLog(@"[ERROR] Cannot reproxy not same proxy class");
		return NO;
	}
    
    UIView * ourView = [[oldProxy parent] parentViewForChild:oldProxy];
    UIView *parentView = [self superview];
    if (parentView!=ourView)
    {
        DebugLog(@"[ERROR] Cannot reproxy not same parent view");
        return NO;
    }
	
	__block BOOL result = YES;
	if (deep) {
		NSArray *subProxies = [newProxy children];
		NSArray *oldSubProxies = [oldProxy children];
		if ([subProxies count] != [oldSubProxies count]) {
            DebugLog(@"[ERROR] Cannot reproxy not same number of subproxies");
			return NO;
		}
		[oldSubProxies enumerateObjectsUsingBlock:^(TiViewProxy *oldSubProxy, NSUInteger idx, BOOL *stop) {
			TiViewProxy *newSubProxy = [subProxies objectAtIndex:idx];
            TiUIView* view = [oldSubProxy view];
            if (!view){
                DebugLog(@"[ERROR] Cannot reproxy no subproxy view");
                result = NO;
                *stop = YES;
            }
            else
                result = [view validateTransferToProxy:newSubProxy deep:YES]; //we assume that the view is already created
			if (!result) {
				*stop = YES;
			}
		}];
	}
	return result;
}

-(id)proxyValueForKey:(NSString *)key
{
	return [proxy valueForKey:key];
}

#pragma mark First Responder delegation

-(void)makeRootViewFirstResponder
{
	[[[TiApp controller] view] becomeFirstResponder];
}

#pragma mark Recognizers

-(UITapGestureRecognizer*)singleTapRecognizer;
{
	if (singleTapRecognizer == nil) {
		singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedSingleTap:)];
		[self configureGestureRecognizer:singleTapRecognizer];
		[self addGestureRecognizer:singleTapRecognizer];

		if (doubleTapRecognizer != nil) {
			[singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
		}
	}
	return singleTapRecognizer;
}

-(UITapGestureRecognizer*)doubleTapRecognizer;
{
	if (doubleTapRecognizer == nil) {
		doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedDoubleTap:)];
		[doubleTapRecognizer setNumberOfTapsRequired:2];
		[self configureGestureRecognizer:doubleTapRecognizer];
		[self addGestureRecognizer:doubleTapRecognizer];
		
		if (singleTapRecognizer != nil) {
			[singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
		}		
	}
	return doubleTapRecognizer;
}

-(UITapGestureRecognizer*)twoFingerTapRecognizer;
{
	if (twoFingerTapRecognizer == nil) {
		twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedSingleTap:)];
		[twoFingerTapRecognizer setNumberOfTouchesRequired:2];
		[self configureGestureRecognizer:twoFingerTapRecognizer];
		[self addGestureRecognizer:twoFingerTapRecognizer];
	}
	return twoFingerTapRecognizer;
}

-(UIPinchGestureRecognizer*)pinchRecognizer;
{
	if (pinchRecognizer == nil) {
		pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedPinch:)];
		[self configureGestureRecognizer:pinchRecognizer];
		[self addGestureRecognizer:pinchRecognizer];
	}
	return pinchRecognizer;
}

-(UISwipeGestureRecognizer*)leftSwipeRecognizer;
{
	if (leftSwipeRecognizer == nil) {
		leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedSwipe:)];
		[leftSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
		[self configureGestureRecognizer:leftSwipeRecognizer];
		[self addGestureRecognizer:leftSwipeRecognizer];
	}
	return leftSwipeRecognizer;
}

-(UISwipeGestureRecognizer*)rightSwipeRecognizer;
{
	if (rightSwipeRecognizer == nil) {
		rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedSwipe:)];
		[rightSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
		[self configureGestureRecognizer:rightSwipeRecognizer];
		[self addGestureRecognizer:rightSwipeRecognizer];
	}
	return rightSwipeRecognizer;
}
-(UISwipeGestureRecognizer*)upSwipeRecognizer;
{
	if (upSwipeRecognizer == nil) {
		upSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedSwipe:)];
		[upSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
		[self configureGestureRecognizer:upSwipeRecognizer];
		[self addGestureRecognizer:upSwipeRecognizer];
	}
	return upSwipeRecognizer;
}
-(UISwipeGestureRecognizer*)downSwipeRecognizer;
{
	if (downSwipeRecognizer == nil) {
		downSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedSwipe:)];
		[downSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionDown];
		[self configureGestureRecognizer:downSwipeRecognizer];
		[self addGestureRecognizer:downSwipeRecognizer];
	}
	return downSwipeRecognizer;
}

-(UILongPressGestureRecognizer*)longPressRecognizer;
{
	if (longPressRecognizer == nil) {
		longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(recognizedLongPress:)];
		[self configureGestureRecognizer:longPressRecognizer];
		[self addGestureRecognizer:longPressRecognizer];
	}
	return longPressRecognizer;
}

-(void)recognizedSingleTap:(UITapGestureRecognizer*)recognizer
{
	NSDictionary *event = [TiUtils dictionaryFromGesture:recognizer inView:self];
    if ([recognizer numberOfTouchesRequired] == 2) {
		[proxy fireEvent:@"twofingertap" withObject:event];
	}
    else
        [proxy fireEvent:@"singletap" withObject:event];
}

-(void)recognizedDoubleTap:(UITapGestureRecognizer*)recognizer
{
	NSDictionary *event = [TiUtils dictionaryFromGesture:recognizer inView:self];
    //Because double-tap suppresses touchStart and double-click, we must do this:
    if ([proxy _hasListeners:@"touchstart"])
    {
        [proxy fireEvent:@"touchstart" withObject:event propagate:YES];
    }
    if ([proxy _hasListeners:@"dblclick"]) {
        [proxy fireEvent:@"dblclick" withObject:event propagate:YES];
    }
    [proxy fireEvent:@"doubletap" withObject:event];
}

-(void)recognizedPinch:(UIPinchGestureRecognizer*)recognizer 
{ 
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                           NUMDOUBLE(recognizer.scale), @"scale", 
                           NUMDOUBLE(recognizer.velocity), @"velocity", 
                           nil]; 
    [self.proxy fireEvent:@"pinch" withObject:event]; 
}

-(void)recognizedLongPress:(UILongPressGestureRecognizer*)recognizer 
{ 
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint p = [recognizer locationInView:self];
        NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                               NUMFLOAT(p.x), @"x",
                               NUMFLOAT(p.y), @"y",
                               nil];
        [self.proxy fireEvent:@"longpress" withObject:event]; 
    }
}

-(NSString*) swipeStringFromGesture:(UISwipeGestureRecognizer *)recognizer
{
    NSString* swipeString;
	switch ([recognizer direction]) {
		case UISwipeGestureRecognizerDirectionUp:
			swipeString = @"up";
			break;
		case UISwipeGestureRecognizerDirectionDown:
			swipeString = @"down";
			break;
		case UISwipeGestureRecognizerDirectionLeft:
			swipeString = @"left";
			break;
		case UISwipeGestureRecognizerDirectionRight:
			swipeString = @"right";
			break;
		default:
			swipeString = @"unknown";
			break;
	}
    return swipeString;
}

-(void)recognizedSwipe:(UISwipeGestureRecognizer *)recognizer
{
	NSMutableDictionary *event = [[TiUtils dictionaryFromGesture:recognizer inView:self] mutableCopy];
	[event setValue:[self swipeStringFromGesture:recognizer] forKey:@"direction"];
	[proxy fireEvent:@"swipe" withObject:event];
	[event release];

}

#pragma mark Touch Events


- (BOOL)interactionDefault
{
	return YES;
}

- (BOOL)interactionEnabled
{
	return self.userInteractionEnabled && _customUserInteractionEnabled;
}

- (BOOL)hasTouchableListener
{
	return handlesTouches;
}

-(UIView*)viewForHitTest
{
    return self;
}

- (UIView *)hitTest:(CGPoint) point withEvent:(UIEvent *)event
{
	BOOL hasTouchListeners = [self hasTouchableListener];
	UIView *hitView = [super hitTest:point withEvent:event];
	// if we don't have any touch listeners, see if interaction should
	// be handled at all.. NOTE: we don't turn off the views interactionEnabled
	// property since we need special handling ourselves and if we turn it off
	// on the view, we'd never get this event
	if ((touchPassThrough || (hasTouchListeners == NO && _touchEnabled==NO)) && hitView == [self viewForHitTest])
	{
		return nil;
	}
	
    // OK, this is problematic because of the situation where:
    // touchDelegate --> view --> button
    // The touch never reaches the button, because the touchDelegate is as deep as the touch goes.
    
    /*
     // delegate to our touch delegate if we're hit but it's not for us
     if (hasTouchListeners==NO && touchDelegate!=nil)
     {
     return touchDelegate;
     }
     */
    
	return hitView;
}

// TODO: Revisit this design decision in post-1.3.0
-(void)handleControlEvents:(UIControlEvents)events
{
	// For subclasses (esp. buttons) to override when they have event handlers.
	TiViewProxy* parentProxy = [(TiViewProxy*)proxy parent];
	if ([parentProxy viewAttached] && [parentProxy canHaveControllerParent]) {
		[[parentProxy view] handleControlEvents:events];
	}
}

// For subclasses
-(BOOL)touchedContentViewWithEvent:(UIEvent *)event
{
    return NO;
}

-(BOOL) enabledForBgState
{
    return [self interactionEnabled];
}

-(UIControlState)realStateForState:(UIControlState)state
{
    if ([self enabledForBgState]) return state;
    return UIControlStateDisabled;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([[event touchesForView:self] count] > 0 || [self touchedContentViewWithEvent:event]) {
        [self processTouchesBegan:touches withEvent:event];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)processTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [touches anyObject];
    if (_shouldHandleSelection) {
        [self setBgState:[self realStateForState:UIControlStateSelected]];
    }
	
	if ([self interactionEnabled])
	{
		if ([proxy _hasListeners:@"touchstart"])
		{
            NSDictionary *evt = [TiUtils dictionaryFromTouch:touch inView:self];
			[proxy fireEvent:@"touchstart" withObject:evt propagate:YES];
			[self handleControlEvents:UIControlEventTouchDown];
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    

    if ([[event touchesForView:self] count] > 0 || [self touchedContentViewWithEvent:event]) {
        [self processTouchesMoved:touches withEvent:event];
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)processTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
    CGPoint localPoint = [touch locationInView:self];
    BOOL outside = (localPoint.x < -kTOUCH_MAX_DIST || (localPoint.x - self.frame.size.width)  > kTOUCH_MAX_DIST ||
                    localPoint.y < -kTOUCH_MAX_DIST || (localPoint.y - self.frame.size.height)  > kTOUCH_MAX_DIST);
    if (_shouldHandleSelection) {
        [self setBgState:[self realStateForState:!outside?UIControlStateSelected:UIControlStateNormal]];
    }
	if ([self interactionEnabled])
	{
		if ([proxy _hasListeners:@"touchmove"])
		{
            NSDictionary *evt = [TiUtils dictionaryFromTouch:touch inView:self];
			[proxy fireEvent:@"touchmove" withObject:evt propagate:YES];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
    if ([[event touchesForView:self] count] > 0 || [self touchedContentViewWithEvent:event]) {
        [self processTouchesEnded:touches withEvent:event];
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)processTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_shouldHandleSelection) {
        [self setBgState:[self realStateForState:UIControlStateNormal]];
    }
	if ([self interactionEnabled])
	{
		UITouch *touch = [touches anyObject];
        BOOL hasTouchEnd = [proxy _hasListeners:@"touchend"];
        BOOL hasDblclick = [proxy _hasListeners:@"dblclick"];
        BOOL hasClick = [proxy _hasListeners:@"click"];
		if (hasTouchEnd || hasDblclick || hasClick)
		{
            NSDictionary *evt = [TiUtils dictionaryFromTouch:touch inView:self];
            if (hasTouchEnd) {
                [proxy fireEvent:@"touchend" withObject:evt propagate:YES];
                [self handleControlEvents:UIControlEventTouchCancel];
            }
            
            // Click handling is special; don't propagate if we have a delegate,
            // but DO invoke the touch delegate.
            // clicks should also be handled by any control the view is embedded in.
            if (hasDblclick && [touch tapCount] == 2) {
                [proxy fireEvent:@"dblclick" withObject:evt propagate:YES];
                return;
            }
            if (hasClick)
            {
                CGPoint localPoint = [touch locationInView:self];
                BOOL outside = (localPoint.x < -kTOUCH_MAX_DIST || (localPoint.x - self.frame.size.width)  > kTOUCH_MAX_DIST ||
                                localPoint.y < -kTOUCH_MAX_DIST || (localPoint.y - self.frame.size.height)  > kTOUCH_MAX_DIST);
                if (!outside && touchDelegate == nil) {
                    [proxy fireEvent:@"click" withObject:evt propagate:YES];
                    return;
                } 
            }
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
    [self setBgState:[self realStateForState:UIControlStateNormal]];
    if ([[event touchesForView:self] count] > 0 || [self touchedContentViewWithEvent:event]) {
        [self processTouchesCancelled:touches withEvent:event];
    }
    [super touchesCancelled:touches withEvent:event];
}

- (void)processTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if ([self interactionEnabled])
	{
		UITouch *touch = [touches anyObject];
		NSDictionary *evt = [TiUtils dictionaryFromTouch:touch inView:self];
		if ([proxy _hasListeners:@"touchcancel"])
		{
			[proxy fireEvent:@"touchcancel" withObject:evt propagate:YES];
		}
	}
}

#pragma mark Listener management

-(void)removeGestureRecognizerOfClass:(Class)c
{
    for (UIGestureRecognizer* r in [self gestureRecognizers]) {
        if ([r isKindOfClass:c]) {
            [self removeGestureRecognizer:r];
            break;
        }
    }
}

-(void)configureGestureRecognizer:(UIGestureRecognizer*)gestureRecognizer
{
    [gestureRecognizer setDelaysTouchesBegan:NO];
    [gestureRecognizer setDelaysTouchesEnded:NO];
    [gestureRecognizer setCancelsTouchesInView:NO];
}

- (UIGestureRecognizer *)gestureRecognizerForEvent:(NSString *)event
{
    if ([event isEqualToString:@"singletap"]) {
        return [self singleTapRecognizer];
    }
    if ([event isEqualToString:@"doubletap"]) {
        return [self doubleTapRecognizer];
    }
    if ([event isEqualToString:@"twofingertap"]) {
        return [self twoFingerTapRecognizer];
    }
    if ([event isEqualToString:@"lswipe"]) {
        return [self leftSwipeRecognizer];
    }
    if ([event isEqualToString:@"rswipe"]) {
        return [self rightSwipeRecognizer];
    }
    if ([event isEqualToString:@"uswipe"]) {
        return [self upSwipeRecognizer];
    }
    if ([event isEqualToString:@"dswipe"]) {
        return [self downSwipeRecognizer];
    }
    if ([event isEqualToString:@"pinch"]) {
        return [self pinchRecognizer];
    }
    if ([event isEqualToString:@"longpress"]) {
        return [self longPressRecognizer];
    }
    return nil;
}

-(void)handleListenerAddedWithEvent:(NSString *)event
{
	ENSURE_UI_THREAD_1_ARG(event);
    if ([event isEqualToString:@"swipe"]) {
        [[self gestureRecognizerForEvent:@"uswipe"] setEnabled:YES];
        [[self gestureRecognizerForEvent:@"dswipe"] setEnabled:YES];
        [[self gestureRecognizerForEvent:@"rswipe"] setEnabled:YES];
        [[self gestureRecognizerForEvent:@"lswipe"] setEnabled:YES];
    }
    else {
        [[self gestureRecognizerForEvent:event] setEnabled:YES];
    }
}

-(void)handleListenerRemovedWithEvent:(NSString *)event
{
	ENSURE_UI_THREAD_1_ARG(event);
	// unfortunately on a remove, we have to check all of them
	// since we might be removing one but we still have others

	[self updateTouchHandling];
    if ([event isEqualToString:@"swipe"]) {
        [[self gestureRecognizerForEvent:@"uswipe"] setEnabled:NO];
        [[self gestureRecognizerForEvent:@"dswipe"] setEnabled:NO];
        [[self gestureRecognizerForEvent:@"rswipe"] setEnabled:NO];
        [[self gestureRecognizerForEvent:@"lswipe"] setEnabled:NO];
    }
    else {
        [[self gestureRecognizerForEvent:event] setEnabled:NO];
    }
}

-(void)listenerAdded:(NSString*)event count:(int)count
{
	if (count == 1 && [self viewSupportsBaseTouchEvents])
	{
		[self handleListenerAddedWithEvent:event];
        [self updateTouchHandling];
	}
}

-(void)listenerRemoved:(NSString*)event count:(int)count
{
	if (count == 0)
	{
		[self handleListenerRemovedWithEvent:event];
        [self updateTouchHandling];
	}
}

-(void)sanitycheckListeners	//TODO: This can be optimized and unwound later.
{
	if(listenerArray == nil){
		listenerArray = [[NSArray alloc] initWithObjects: @"singletap",
						 @"doubletap",@"twofingertap",@"swipe",@"pinch",@"longpress",nil];
	}
	for (NSString * eventName in listenerArray) {
		if ([proxy _hasListeners:eventName]) {
			[self handleListenerAddedWithEvent:eventName];
		}
	}
}

-(void)setViewMask_:(id)arg
{
    UIImage* image = [self loadImage:arg];
    if (image == nil) {
        self.layer.mask = nil;
    }
    else {
        if (self.layer.mask == nil) {
            self.layer.mask = [CALayer layer];
            self.layer.mask.frame = self.layer.bounds;
        }
        self.layer.opaque = NO;
        self.layer.mask.contentsScale = [image scale];
        self.layer.mask.contentsCenter = TiDimensionLayerContentCenter(topCap, leftCap, topCap, leftCap, [image size]);
        if (!CGPointEqualToPoint(self.layer.mask.contentsCenter.origin,CGPointZero)) {
            self.layer.mask.magnificationFilter = @"nearest";
        } else {
            self.layer.mask.magnificationFilter = @"linear";
        }
        self.layer.mask.contents = (id)image.CGImage;
    }
    
    [self.layer setNeedsDisplay];
}

-(void)setHighlighted:(BOOL)isHiglighted
{
    [self setBgState:[self realStateForState:isHiglighted?UIControlStateHighlighted:UIControlStateNormal]];
	for (TiUIView * thisView in [self childViews])
	{
        if ([thisView.subviews count] > 0) {
            id firstChild = [thisView.subviews objectAtIndex:0];
            if ([firstChild isKindOfClass:[UIControl class]])
            {
                [(UIControl*)firstChild setHighlighted:isHiglighted];//swizzle will call setHighlighted on the view
            }
            else {
                [(id)thisView setHighlighted:isHiglighted];
            }
        }
        else {
			[(id)thisView setHighlighted:isHiglighted];
		}
	}
}

-(void)setSelected:(BOOL)isSelected
{
    [self setBgState:[self realStateForState:isSelected?UIControlStateSelected:UIControlStateNormal]];
	for (TiUIView * thisView in [self childViews])
	{
        if ([thisView.subviews count] > 0) {
            id firstChild = [thisView.subviews objectAtIndex:0];
            if ([firstChild isKindOfClass:[UIControl class]])
            {
                [(UIControl*)firstChild setSelected:isSelected]; //swizzle will call setSelected on the view
            }
            else {
                [(id)thisView setSelected:isSelected];
            }
        }
        else {
			[(id)thisView setSelected:isSelected];
		}
	}
}

- (void)transitionfromView:(TiUIView *)viewOut toView:(TiUIView *)viewIn withTransition:(TiTransition *)transition completionBlock:(void (^)(void))block{
    [viewOut animationStarted];
    [viewIn animationStarted];
    
    [self addSubview:viewIn];
    ADTransition* adTransition = transition.adTransition;
    [transition prepareViewHolder:self];
    [adTransition prepareTransitionFromView:viewOut toView:viewIn inside:self];
    
    [CATransaction setCompletionBlock:^{
        [adTransition finishedTransitionFromView:viewOut toView:viewIn inside:self];        [viewOut removeFromSuperview];
        [viewOut animationCompleted];
        [viewIn animationCompleted];
        if (block != nil) {
            block();
        }
    }];
    
    [adTransition startTransitionFromView:viewOut toView:viewIn inside:self];
}

- (void)blurBackground:(id)args
{
    //get the visible rect
    CGRect visibleRect = [self.superview convertRect:self.frame toView:self];
    visibleRect.origin.y += self.frame.origin.y;
    visibleRect.origin.x += self.frame.origin.x;
    
    //hide all the blurred views from the superview before taking a screenshot
    CGFloat alpha = self.alpha;
    CGFloat superviewAlpha = self.superview.alpha;
    self.alpha = 0.0f;
    if (superviewAlpha == 0) {
        self.superview.alpha = 1.0f;
    }
    //Render the layer in the image context
    //Render the layer in the image context
    UIGraphicsBeginImageContextWithOptions(visibleRect.size, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -visibleRect.origin.x, -visibleRect.origin.y);
    CALayer *layer = self.superview.layer;
    [layer renderInContext:context];
    
    //show all the blurred views from the superview before taking a screenshot
    self.alpha = alpha;
    self.superview.alpha = superviewAlpha;
   
    __block UIImage *image = [UIGraphicsGetImageFromCurrentImageContext() retain];
    UIGraphicsEndImageContext();
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSArray* properties;
        id firstArg = [args objectAtIndex:0];
        if ([firstArg isKindOfClass:[NSArray class]]) {
            properties = firstArg;
        }
        else {
            properties = [NSArray arrayWithObject:[TiUtils stringValue:firstArg]];
        }
        NSDictionary* options;
        ENSURE_ARG_AT_INDEX(options, args, 1, NSDictionary)
        [options setValue:[NSArray arrayWithObject:[NSNumber numberWithInt:TiImageHelperFilterBoxBlur]] forKey:@"filters"];
        UIImage* result = [[TiImageHelper imageFiltered:[image autorelease] withOptions:options] retain];
        if ([options objectForKey:@"callback"]) {
            id callback = [options objectForKey:@"callback"];
            ENSURE_TYPE(callback, KrollCallback)
            if (callback != nil) {
                TiThreadPerformOnMainThread(^{
                    TiBlob* blob = [[TiBlob alloc] initWithImage:result];
                    NSDictionary *event = [NSDictionary dictionaryWithObject:blob forKey:@"image"];
                    [self.proxy _fireEventToListener:@"blurBackground" withObject:event listener:callback thisObject:nil];

                    [blob release];
                }, NO);
            }
        }
            for (NSString* property in properties) {
                [self.proxy setValue:result forKey:property];
            }
        [result release];
    });
}

@end
