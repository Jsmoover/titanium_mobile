/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiWindowProxy.h"
#import "TiUIWindow.h"
#import "TiApp.h"
#import "TiErrorController.h"
#import "TiTransitionAnimation+Friend.h"
#import "TiTransitionAnimationStep.h"

@interface TiWindowProxy(Private)
-(void)openOnUIThread:(id)args;
-(void)closeOnUIThread:(id)args;
-(void)rootViewDidForceFrame:(NSNotification *)notification;
@end

@implementation TiWindowProxy
{
    BOOL readyToBeLayout;
    BOOL _isManaged;
}

@synthesize tab = tab;
@synthesize isManaged = _isManaged;

-(id)init
{
	if ((self = [super init]))
	{
        [self setDefaultReadyToCreateView:YES];
        opening = NO;
        opened = NO;
        readyToBeLayout = NO;
        _isManaged = NO;
	}
	return self;
}

-(void) dealloc {
    FORGET_AND_RELEASE_WITH_DELEGATE(openAnimation);
    FORGET_AND_RELEASE_WITH_DELEGATE(closeAnimation);

#ifdef USE_TI_UIIOSTRANSITIONANIMATION
    FORGET_AND_RELEASE(transitionProxy)
#endif
    [super dealloc];
}

-(void)_destroy {
    [super _destroy];
}

-(void)_configure
{
    [self replaceValue:nil forKey:@"orientationModes" notification:NO];
    [super _configure];
}

-(NSString*)apiName
{
    return @"Ti.Window";
}

-(void)rootViewDidForceFrame:(NSNotification *)notification
{
    if (focussed && opened) {
        if ( (controller == nil) || ([controller navigationController] == nil) ) {
            return;
        }
        UINavigationController* nc = [controller navigationController];
        BOOL isHidden = [nc isNavigationBarHidden];
        [nc setNavigationBarHidden:!isHidden animated:NO];
        [nc setNavigationBarHidden:isHidden animated:NO];
        [[nc view] setNeedsLayout];
    }
}

-(TiUIView*)newView
{
	TiUIWindow * win = (TiUIWindow*)[super newView];
    win.frame =[TiUtils appFrame];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rootViewDidForceFrame:) name:kTiFrameAdjustNotification object:nil];
	return win;
}

-(void)refreshViewIfNeeded
{
	if (!readyToBeLayout) return;
    [super refreshViewIfNeeded];
}

-(BOOL)relayout
{
    if (!readyToBeLayout) {
        //in case where the window was actually added as a child we want to make sure we are good
        readyToBeLayout = YES;
    }
    return [super relayout];
}

-(void)setSandboxBounds:(CGRect)rect
{
    if (!readyToBeLayout) {
        //in case where the window was actually added as a child we want to make sure we are good
        readyToBeLayout = YES;
    }
    [super setSandboxBounds:rect];
}

-(BOOL)isManaged
{
    if (parent) {
        return [[self getParentWindow] isManaged];
    }
    return _isManaged;
}

#pragma mark - Utility Methods
-(void)windowWillOpen
{
    if (!opened){
        opening = YES;
    }
    [super windowWillOpen];
//    [self viewWillAppear:false];
    if (tab == nil && (self.isManaged == NO) && controller == nil) {
        [[[[TiApp app] controller] topContainerController] willOpenWindow:self];
    }
}

-(void)windowDidOpen
{
    opening = NO;
    opened = YES;
//    if (!readyToBeLayout)
//    {
//        [self viewWillAppear:false];
//        [self viewDidAppear:false];
//    }
//    [self viewDidAppear:false];
    [self fireEvent:@"open" propagate:NO];
    if (focussed && [self handleFocusEvents]) {
        [self fireEvent:@"focus" propagate:NO];
    }
    [super windowDidOpen];
    FORGET_AND_RELEASE_WITH_DELEGATE(openAnimation);
    if (tab == nil && (self.isManaged == NO) && controller == nil) {
        [[[[TiApp app] controller] topContainerController] didOpenWindow:self];
    }
}

-(void) windowWillClose
{
//    [self viewWillDisappear:false];
    if (tab == nil && (self.isManaged == NO) && controller == nil) {
        [[[[TiApp app] controller] topContainerController] willCloseWindow:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super windowWillClose];
}

-(void) windowDidClose
{
    opened = NO;
    closing = NO;
//    [self viewDidDisappear:false];
    [self fireEvent:@"close" propagate:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self]; //just to be sure
    FORGET_AND_RELEASE_WITH_DELEGATE(closeAnimation);
    if (tab == nil && (self.isManaged == NO) && controller == nil) {
        [[[[TiApp app] controller] topContainerController] didCloseWindow:self];
    }
    tab = nil;
    self.isManaged = NO;
    
    [super windowDidClose];
    [self forgetSelf];
}

-(void)attachViewToTopContainerController
{
    UIViewController<TiControllerContainment>* topContainerController = [[[TiApp app] controller] topContainerController];
    UIView *rootView = [topContainerController view];
    TiUIView* theView = [self view];
    [rootView addSubview:theView];
    [rootView bringSubviewToFront:theView];
    [[TiViewProxy class] reorderViewsInParent:rootView]; //make sure views are ordered along zindex
}

-(BOOL)isRootViewLoaded
{
    return [[[TiApp app] controller] isViewLoaded];
}

-(BOOL)isRootViewAttached
{
    //When a modal window is up, just return yes
    if ([[[TiApp app] controller] presentedViewController] != nil) {
        return YES;
    }
    return ([[[[TiApp app] controller] view] superview]!=nil);
}

#pragma mark - TiWindowProtocol Base Methods
-(void)open:(id)args
{
    //If an error is up, Go away
    if ([[[[TiApp app] controller] topPresentedController] isKindOfClass:[TiErrorController class]]) {
        DebugLog(@"[ERROR] ErrorController is up. ABORTING open");
        return;
    }
    
    //I am already open or will be soon. Go Away
    if (opening || opened) {
        return;
    }
    
    if (([args count] > 0) && [[args objectAtIndex:0] isKindOfClass:[NSDictionary class]]) {
        NSDictionary* props = [args objectAtIndex:0];
        NSMutableSet* transferableProperties = [NSMutableSet setWithArray:[props allKeys]];
        NSMutableSet* supportedProperties = [NSMutableSet setWithArray:@[@"fullscreen", @"modal", @"navBarHidden", @"orientationModes", @"statusBarStyle"]];
        [transferableProperties intersectSet:supportedProperties];
        id<NSFastEnumeration> keySeq = transferableProperties;
		for (NSString * thisKey in keySeq)
		{
            [self replaceValue:[props valueForKey:thisKey] forKey:thisKey notification:NO];
		}
    }
    
    //Lets keep ourselves safe
    [self rememberSelf];

    //Make sure our RootView Controller is attached
    if (![self isRootViewLoaded]) {
        DebugLog(@"[WARN] ROOT VIEW NOT LOADED. WAITING");
        [self performSelector:@selector(open:) withObject:args afterDelay:0.1];
        return;
    }
    if (![self isRootViewAttached]) {
        DebugLog(@"[WARN] ROOT VIEW NOT ATTACHED. WAITING");
        [self performSelector:@selector(open:) withObject:args afterDelay:0.1];
        return;
    }
    
    opening = YES;
    
    isModal = (tab == nil && !self.isManaged) ? [TiUtils boolValue:[self valueForUndefinedKey:@"modal"] def:NO] : NO;
    hidesStatusBar = [TiUtils boolValue:[self valueForUndefinedKey:@"fullscreen"] def:[[[TiApp app] controller] statusBarInitiallyHidden]];
    
    if (!isModal && (tab==nil)) {
        openAnimation = [[TiAnimation animationFromArg:args context:[self pageContext] create:NO] retain];
        if (openAnimation) {
            [self rememberProxy:openAnimation];
        }
    }
    [self updateOrientationModes];
    
    //GO ahead and call open on the UI thread
    TiThreadPerformOnMainThread(^{
        [self openOnUIThread:args];
    }, YES);
    
}

-(void)updateOrientationModes
{
    //TODO Argument Processing
    id object = [self valueForUndefinedKey:@"orientationModes"];
    _supportedOrientations = [TiUtils TiOrientationFlagsFromObject:object];
}

-(void)setStatusBarStyle:(id)style
{
    int theStyle = [TiUtils intValue:style def:[[[TiApp app] controller] defaultStatusBarStyle]];
    switch (theStyle){
        case UIStatusBarStyleDefault:
            statusBarStyle = UIStatusBarStyleDefault;
            break;
        case UIStatusBarStyleBlackOpaque:
        case UIStatusBarStyleBlackTranslucent: //This will also catch UIStatusBarStyleLightContent
            if ([TiUtils isIOS7OrGreater]) {
                statusBarStyle = 1;//UIStatusBarStyleLightContent;
            } else {
                statusBarStyle = theStyle;
            }
            break;
        default:
            statusBarStyle = UIStatusBarStyleDefault;
    }
    [self setValue:NUMINT(statusBarStyle) forUndefinedKey:@"statusBarStyle"];
    if(focussed) {
        TiThreadPerformOnMainThread(^{
            [(TiRootViewController*)[[TiApp app] controller] updateStatusBar];
        }, YES); 
    }
}

-(void)close:(id)args
{
    //I am not open. Go Away
//    if (opening) {
//        DebugLog(@"Window is opening. Ignoring this close call");
//        return;
//    }
    
    if (!opened) {
        DebugLog(@"Window is not open. Ignoring this close call");
        return;
    }
    
    if (closing) {
        DebugLog(@"Window is already closing. Ignoring this close call.");
        return;
    }
    
    if (tab != nil) {
        if ([args count] > 0) {
            args = [NSArray arrayWithObjects:self, [args objectAtIndex:0], nil];
        } else {
            args = [NSArray arrayWithObject:self];
        }
        [tab closeWindow:args];
        return;
    }
    
    closing = YES;
    
    //TODO Argument Processing
    closeAnimation = [[TiAnimation animationFromArg:args context:[self pageContext] create:NO] retain];
    if (closeAnimation) {
        [self rememberProxy:closeAnimation];
    }

    //GO ahead and call close on UI thread
    TiThreadPerformOnMainThread(^{
        [self closeOnUIThread:args];
    }, YES);
    
}

-(BOOL)_handleOpen:(id)args
{
    TiRootViewController* theController = [[TiApp app] controller];
    if (isModal || (tab != nil) || self.isManaged) {
        FORGET_AND_RELEASE_WITH_DELEGATE(openAnimation);
    }
    
    if ( (!self.isManaged) && (!isModal) && (openAnimation != nil) && ([theController topPresentedController] != [theController topContainerController]) ){
        DeveloperLog(@"[WARN] The top View controller is not a container controller. This window will open behind the presented controller without animations.")
        FORGET_AND_RELEASE_WITH_DELEGATE(openAnimation);
    }
    
    return YES;
}

-(BOOL)_handleClose:(id)args
{
    TiRootViewController* theController = [[TiApp app] controller];
    if (isModal || (tab != nil) || self.isManaged) {
        if (closeAnimation) {
            FORGET_AND_RELEASE_WITH_DELEGATE(closeAnimation);
        }
    }
    if ( (!self.isManaged) && (!isModal) && (closeAnimation != nil) && ([theController topPresentedController] != [theController topContainerController]) ){
        DeveloperLog(@"[WARN] The top View controller is not a container controller. This window will close behind the presented controller without animations.")
        FORGET_AND_RELEASE_WITH_DELEGATE(closeAnimation);
    }
    return YES;
}

-(BOOL)opening
{
    return opening;
}

-(BOOL)closing
{
    return closing;
}

-(void)setModal:(id)val
{
    [self replaceValue:val forKey:@"modal" notification:NO];
}

-(id)modal
{
    return [self valueForUndefinedKey:@"modal"];
}

-(BOOL)isModal
{
    TiParentingProxy* topParent = [self topParent];
    if ([topParent isKindOfClass:[TiWindowProxy class]])
    {
        return [(TiWindowProxy*)topParent isModal];
    }
    return isModal;
}

-(TiParentingProxy*)topParent
{
    TiParentingProxy* result = parent;
    while ([result parent]) {
        result = [result parent];
    }
    return result;
}


-(BOOL)hidesStatusBar
{
    return hidesStatusBar;
}

-(UIStatusBarStyle)preferredStatusBarStyle;
{
    return statusBarStyle;
}

-(BOOL)handleFocusEvents
{
	return YES;
}

-(void)gainFocus
{
    if (focussed == NO) {
        focussed = YES;
        if ([self handleFocusEvents] && opened) {
            [self fireEvent:@"focus" propagate:NO];
        }
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
        [[self view] setAccessibilityElementsHidden:NO];
    }
    if ([TiUtils isIOS7OrGreater]) {
        TiThreadPerformOnMainThread(^{
            [self forceNavBarFrame];
        }, NO);
    }
}

-(void)resignFocus
{
    if (focussed == YES) {
        focussed = NO;
        if ([self handleFocusEvents]) {
            [self fireEvent:@"blur" propagate:NO];
        }
        [[self view] setAccessibilityElementsHidden:YES];
    }
}

-(void)blur:(id)args
{
	ENSURE_UI_THREAD_1_ARG(args)
	[self resignFocus];
    [super blur:nil];
}

-(void)focus:(id)args
{
	ENSURE_UI_THREAD_1_ARG(args)
	[self gainFocus];
    [super focus:nil];
}

-(TiProxy *)topWindow
{
    return self;
}

-(TiProxy *)parentForBubbling
{
    if (parent) return parent;
    else return tab;
}

#pragma mark - Private Methods
-(TiProxy*)tabGroup
{
    return [tab tabGroup];
}

-(NSNumber*)orientation
{
	return NUMINT([UIApplication sharedApplication].statusBarOrientation);
}

-(void)forceNavBarFrame
{
    if (!focussed) {
        return;
    }
    if ( (controller == nil) || ([controller navigationController] == nil) ) {
        return;
    }
    
    if (![[[TiApp app] controller] statusBarVisibilityChanged]) {
        return;
    }
    
    UINavigationController* nc = [controller navigationController];
    BOOL isHidden = [nc isNavigationBarHidden];
    [nc setNavigationBarHidden:!isHidden animated:NO];
    [nc setNavigationBarHidden:isHidden animated:NO];
    [[nc view] setNeedsLayout];
}


-(void)openOnUIThread:(NSArray*)args
{
    if ([self _handleOpen:args]) {
        [self parentWillShow];
        if (tab != nil) {
            if ([args count] > 0) {
                args = [NSArray arrayWithObjects:self, [args objectAtIndex:0], nil];
            } else {
                args = [NSArray arrayWithObject:self];
            }
            [tab openWindow:args];
        } else if (isModal) {
            UIViewController* theController = [self hostingController];
            if (![TiUtils boolValue:[self valueForUndefinedKey:@"navBarHidden"] def:YES]) {
                //put it in a navigation controller to get the navbar if it was explicitely asked for
                theController = [[UINavigationController alloc] initWithRootViewController:theController];
            }
            [self windowWillOpen];
            NSDictionary *dict = [args count] > 0 ? [args objectAtIndex:0] : nil;
            int style = [TiUtils intValue:@"modalTransitionStyle" properties:dict def:-1];
            if (style != -1) {
                [theController setModalTransitionStyle:style];
            }
            style = [TiUtils intValue:@"modalStyle" properties:dict def:-1];
            if (style != -1) {
				// modal transition style page curl must be done only in fullscreen
				// so only allow if not page curl
				if ([theController modalTransitionStyle]!=UIModalTransitionStylePartialCurl)
				{
					[theController setModalPresentationStyle:style];
				}
            }
            BOOL animated = [TiUtils boolValue:@"animated" properties:dict def:YES];
            [[TiApp app] showModalController:theController animated:animated];
        } else {
            [self windowWillOpen];
            [self view];
            if ((self.isManaged == NO) && ((openAnimation == nil) || (![openAnimation isTransitionAnimation]))){
                [self attachViewToTopContainerController];
            }
            if (openAnimation != nil) {
                [self animate:openAnimation];
            } else {
                [self windowDidOpen];
            }
        }
    } else {
        DebugLog(@"[WARN] OPEN ABORTED. _handleOpen returned NO");
        opening = NO;
        opened = NO;
        FORGET_AND_RELEASE_WITH_DELEGATE(openAnimation);
    }
}

-(void)closeOnUIThread:(NSArray *)args
{
    if ([self _handleClose:args]) {
        [self windowWillClose];
        if (isModal) {
            NSDictionary *dict = [args count] > 0 ? [args objectAtIndex:0] : nil;
            BOOL animated = [TiUtils boolValue:@"animated" properties:dict def:YES];
            [[TiApp app] hideModalController:controller animated:animated];
        } else {
            if (closeAnimation != nil) {
                [closeAnimation setDelegate:self];
                [self animate:closeAnimation];
            } else {
                [self windowDidClose];
            }
        }
        
    } else {
        DebugLog(@"[WARN] CLOSE ABORTED. _handleClose returned NO");
        closing = NO;
        FORGET_AND_RELEASE_WITH_DELEGATE(closeAnimation);
    }
}

#pragma mark - TiOrientationController
-(void)childOrientationControllerChangedFlags:(id<TiOrientationController>) orientationController;
{
    [parentController childOrientationControllerChangedFlags:self];
}

-(void)setParentOrientationController:(id <TiOrientationController>)newParent
{
    parentController = newParent;
}

-(id)parentOrientationController
{
	return parentController;
}

-(TiOrientationFlags) orientationFlags
{
    if ([self isModal]) {
        return (_supportedOrientations==TiOrientationNone) ? [[[TiApp app] controller] getDefaultOrientations] : _supportedOrientations;
    }
    return _supportedOrientations;
}

#pragma mark - Appearance and Rotation Callbacks. For subclasses to override.
//Containing controller will call these callbacks(appearance/rotation) on contained windows when it receives them.
-(void)viewWillAppear:(BOOL)animated
{
    readyToBeLayout = YES;
    [super viewWillAppear:animated];
}
-(void)viewWillDisappear:(BOOL)animated
{
    if (controller != nil) {
        [self resignFocus];
    }
    [super viewWillDisappear:animated];
}
-(void)viewDidAppear:(BOOL)animated
{
    if (isModal && opening) {
        [self windowDidOpen];
    }
    if (controller != nil && !self.isManaged) {
        [self gainFocus];
    }
}
-(void)viewDidDisappear:(BOOL)animated
{
    if (isModal && closing) {
        [self windowDidClose];
    }
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self refreshViewIfNeeded];
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setFakeAnimationOfDuration:duration andCurve:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self removeFakeAnimation];
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

#pragma mark - TiAnimation Delegate Methods

-(HLSAnimation*)animationForAnimation:(TiAnimation*)animation
{
    if (animation.isTransitionAnimation && (animation == openAnimation || animation == closeAnimation)) {
        
        TiTransitionAnimation * hlsAnimation = [TiTransitionAnimation animation];
        UIView* hostingView = nil;
        if (animation == openAnimation) {
            hostingView = [[[[TiApp app] controller] topContainerController] view];
            hlsAnimation.openTransition = YES;
        } else {
            hostingView = [[self getOrCreateView] superview];
            hlsAnimation.closeTransition = YES;
        }
        hlsAnimation.animatedProxy = self;
        hlsAnimation.animationProxy = animation;
        hlsAnimation.transition = animation.transition;
        hlsAnimation.transitionViewProxy = self;
        TiTransitionAnimationStep* step = [TiTransitionAnimationStep animationStep];
        step.duration = [animation getAnimationDuration];
        [step addTransitionAnimation:hlsAnimation insideHolder:hostingView];
        return [HLSAnimation animationWithAnimationStep:step];
    }
    else {
        return [super animationForAnimation:animation];
    }
}

-(void)animationDidComplete:(TiAnimation *)sender
{
    [super animationDidComplete:sender];
    if (sender == openAnimation) {
        if (animatedOver != nil) {
            if ([animatedOver isKindOfClass:[TiUIView class]]) {
                TiViewProxy* theProxy = (TiViewProxy*)[(TiUIView*)animatedOver proxy];
                if ([theProxy viewAttached]) {
                    [[[self view] superview] insertSubview:animatedOver belowSubview:[self view]];
                    LayoutConstraint* layoutProps = [theProxy layoutProperties];
                    ApplyConstraintToViewWithBounds(layoutProps, &layoutProperties, (TiUIView*)animatedOver, [[animatedOver superview] bounds]);
                    [theProxy layoutChildren:NO];
                    RELEASE_TO_NIL(animatedOver);
                }
            } else {
                [[[self view] superview] insertSubview:animatedOver belowSubview:[self view]];
            }
        }
        [self windowDidOpen];
    } else if (sender == closeAnimation) {
        [self windowDidClose];
    }
}
#ifdef USE_TI_UIIOSTRANSITIONANIMATION
-(TiUIiOSTransitionAnimationProxy*)transitionAnimation
{
    return transitionProxy;
}

-(void)setTransitionAnimation:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, TiUIiOSTransitionAnimationProxy)
    if(transitionProxy != nil) {
        FORGET_AND_RELEASE(transitionProxy)
    }
    transitionProxy = [args retain];
    [self rememberProxy:transitionProxy];
}
#endif

@end
