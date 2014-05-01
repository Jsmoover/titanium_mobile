/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiUIiOSAdView.h"
#import "TiUtils.h"
#import "APSAnalytics.h"

#ifdef USE_TI_UIIOSADVIEW

extern NSString * const TI_APPLICATION_ANALYTICS;

@implementation TiUIiOSAdView

-(void)dealloc
{
	RELEASE_TO_NIL(adview);
	[super dealloc];
}

-(ADBannerView*)adview
{
	if (adview == nil)
	{
		adview = [[ADBannerView alloc] initWithFrame:CGRectZero];
		adview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		adview.delegate = self;
		[self addSubview:adview];
	}
	return adview;
}

- (id)accessibilityElement
{
	return [self adview];
}

-(CGSize)contentSizeForSize:(CGSize)size
{
	ADBannerView *view = [self adview];
    return [ADBannerView sizeFromBannerContentSizeIdentifier:view.currentContentSizeIdentifier];
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
	if (!CGRectIsEmpty(bounds))
	{
		[TiUtils setView:[self adview] positionRect:bounds];
	}
    [super frameSizeChanged:frame bounds:bounds];
}

-(void)setAdSize:(NSString*)sizeName
{
    [self adview].currentContentSizeIdentifier = sizeName;
}

#pragma mark Public APIs

-(void)cancelAction:(id)args
{
	if (adview!=nil)
	{
		[adview cancelBannerViewAction];
	}
}

#pragma mark Delegates

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self.proxy replaceValue:NUMBOOL(YES) forKey:@"visible" notification:YES];
	if (TI_APPLICATION_ANALYTICS)
	{
		NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:[banner currentContentSizeIdentifier],@"size",nil];
        [APSAnalytics sendCustomEvent:@"ti.iad.load" withType:@"ti.iad.load" data:data];
	}
	[(TiUIiOSAdViewProxy*) self.proxy fireLoad:nil];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	if (TI_APPLICATION_ANALYTICS)
	{
		NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:[banner currentContentSizeIdentifier],@"size",nil];
        [APSAnalytics sendCustomEvent:@"ti.iad.action" withType:@"ti.iad.action" data:data];
	}
	if ([self.proxy _hasListeners:@"action"])
	{
		NSMutableDictionary *event = [NSMutableDictionary dictionary];
		[self.proxy fireEvent:@"action" withObject:event];
	}
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	return YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	TiProxy * selfProxy = [self proxy];
	// per Apple, we must hide the banner view if there's no ad
	[selfProxy replaceValue:NUMBOOL(NO) forKey:@"visible" notification:YES];
	
	if ([selfProxy _hasListeners:@"error"])
	{
		NSString * message = [TiUtils messageFromError:error];
		NSDictionary *event = [NSDictionary dictionaryWithObject:message forKey:@"message"];
		[selfProxy fireEvent:@"error" withObject:event errorCode:[error code] message:message];
	}
}

@end


#endif
