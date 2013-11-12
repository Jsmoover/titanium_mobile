/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#ifdef USE_TI_UIIMAGEVIEW

#import "TiBase.h"
#import "TiUIImageView.h"
#import "TiUtils.h"
#import "ImageLoader.h"
#import "OperationQueue.h"
#import "TiViewProxy.h"
#import "TiProxy.h"
#import "TiBlob.h"
#import "TiFile.h"
#import "UIImage+Resize.h"
#import "TiUIImageViewProxy.h"
#import "TiSVGImage.h"
#import "TiTransitionHelper.h"
#import "TiTransition.h"

#define IMAGEVIEW_DEBUG 0

#define IMAGEVIEW_MIN_INTERVAL 30

@interface TiUIImageView()
{
    TiAnimatedImage* _animatedImage;
    NSMutableArray *_images;
    UIImage* _currentImage;
    id _currentImageSource;
    
	NSTimer *timer;
	NSTimeInterval interval;
	NSInteger repeatCount;
	NSInteger index;
	NSInteger iterations;
	UIView *previous;
	UIView *container;
	BOOL ready;
	BOOL stopped;
	BOOL reverse;
	BOOL placeholderLoading;
	TiDimension width;
	TiDimension height;
	CGFloat autoHeight;
	CGFloat autoWidth;
	CGFloat autoScale;
	NSInteger loadCount;
	NSInteger readyCount;
	NSInteger loadTotal;
	UIImageView * imageView;
    UIViewContentMode scaleType;
	BOOL localLoadSync;
    
    CGFloat animationDuration;
    TiSVGImage* _svg;
    BOOL animationPaused;
    BOOL autoreverse;
    BOOL usingNewMethod;
}
@property(nonatomic,retain) NSDictionary *transition;
-(void)startTimerWithEvent:(NSString *)eventName;
-(void)stopTimerWithEvent:(NSString *)eventName;
@end

@implementation TiUIImageView

#pragma mark Internal

DEFINE_EXCEPTIONS

-(id)init
{
    if (self = [super init]) {
        localLoadSync = NO;
        scaleType = UIViewContentModeScaleAspectFit;
        animationDuration = 0.5;
        self.transition = nil;
        animationPaused=  YES;
        autoreverse = NO;
        usingNewMethod = NO;
        stopped = YES;
        autoScale = 1;
    }
    return self;
}

-(void)dealloc
{
	if (timer!=nil)
	{
		[timer invalidate];
	}
	RELEASE_TO_NIL(timer);
	RELEASE_TO_NIL(_images);
	RELEASE_TO_NIL(container);
	RELEASE_TO_NIL(previous);
	RELEASE_TO_NIL(imageView);
	RELEASE_TO_NIL(_svg);
	RELEASE_TO_NIL(_transition);
	RELEASE_TO_NIL(_animatedImage);
	RELEASE_TO_NIL(_currentImage);
	[super dealloc];
}

-(CGSize)contentSizeForSize:(CGSize)size
{
    CGSize result = size;
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        result = CGSizeMake(autoWidth, autoHeight);
    }
    else if(size.width == 0 && autoHeight>0) {
        result.width = (size.height*autoWidth/autoHeight);
    }
    else if(size.height == 0 && autoWidth > 0) {
        result.height = (size.width*autoHeight/autoWidth);
    }
    else if(autoHeight == 0 || autoWidth == 0) {
        result = container.bounds.size;
    }
    else {
        BOOL autoSizeWidth = [(TiViewProxy*)self.proxy widthIsAutoSize];
        BOOL autoSizeHeight = [(TiViewProxy*)self.proxy heightIsAutoSize];
        if (!autoSizeWidth && ! autoSizeHeight) {
            result = size;
        }
        else if(autoSizeWidth && autoSizeHeight) {
            float ratio = autoWidth/autoHeight;
            float viewratio = size.width/size.height;
            if(viewratio > ratio) {
                result.height = MIN(size.height, autoHeight);
                result.width = (result.height*autoWidth/autoHeight);
            }
            else {
                result.width = MIN(size.width, autoWidth);
                result.height = (result.width*autoHeight/autoWidth);
            }        }
        else if(autoSizeHeight) {
            result.width = size.width;
            result.height = result.width*autoHeight/autoWidth;
        }
        else {
            result.height = size.height;
            result.width = (result.height*autoWidth/autoHeight);
        }
    }
    return result;
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    if (imageView.layer.mask != nil) {
        [imageView.layer.mask setFrame:bounds];
    }
    
    if (_svg != nil) {
        imageView.image = [_svg imageForSize:bounds.size];
    }

	for (UIView *child in [self subviews])
	{
		[TiUtils setView:child positionRect:bounds];
	}
	if (container!=nil)
	{
		for (UIView *child in [container subviews])
		{
			[TiUtils setView:child positionRect:bounds];
		}
	}
    [super frameSizeChanged:frame bounds:bounds];
}

-(void)timerFired:(id)arg
{
	if (stopped) {
		return;
	}
	
	// don't let the placeholder stomp on our new _images
	placeholderLoading = NO;
	
	NSInteger position = index % loadTotal;
	NSInteger nextIndex = (reverse) ? --index : ++index;
	
	if (position<0)
	{
		position=loadTotal-1;
		index=position-1;
	}
	UIView *view = [[container subviews] objectAtIndex:position];
    
	// see if we have an activity indicator... if we do, that means the image hasn't yet loaded
	// and we want to start the spinner to let the user know that we're still loading. we 
	// don't initially start the spinner when added since we don't want to prematurely show
	// the spinner (usually for the first image) and then immediately remove it with a flash
	UIView *spinner = [[view subviews] count] > 0 ? [[view subviews] objectAtIndex:0] : nil;
	if (spinner!=nil && [spinner isKindOfClass:[UIActivityIndicatorView class]])
	{
		[(UIActivityIndicatorView*)spinner startAnimating];
		[view bringSubviewToFront:spinner];
	}
	
	// the container sits on top of the image in case the first frame (via setUrl) is first
	[self bringSubviewToFront:container];
	
	view.hidden = NO;
    
	if (previous!=nil)
	{
		previous.hidden = YES;
		RELEASE_TO_NIL(previous);
	}
	
	previous = [view retain];
    
	if ([self.proxy _hasListeners:@"change"])
	{
		NSDictionary *evt = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:position] forKey:@"index"];
		[self.proxy fireEvent:@"change" withObject:evt];
	}
	
	if (repeatCount > 0 && ((reverse==NO && nextIndex == loadTotal) || (reverse && nextIndex==0)))
	{
		iterations++;
		if (iterations == repeatCount) {
            stopped = YES;
            [self stopTimerWithEvent:@"stop"];
		}
	}
}

-(void)queueImage:(id)img index:(int)index_
{
	UIView *view = [[UIView alloc] initWithFrame:self.bounds];
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	
	spinner.center = view.center;
	spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;			
	
	[view addSubview:spinner];
	[container addSubview:view];
	[view release];
	[spinner release];
	
	[_images addObject:img];
	[[OperationQueue sharedQueue] queue:@selector(loadImageInBackground:) target:self arg:[NSNumber numberWithInt:index_] after:nil on:nil ui:NO];
}

-(void)startTimerWithEvent:(NSString *)eventName
{
	RELEASE_TO_NIL(timer);
	if (stopped)
	{
		return;
	}
	timer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES] retain]; 
	if ([self.proxy _hasListeners:eventName])
	{
		[self.proxy fireEvent:eventName withObject:nil];
	}
}

-(void)stopTimerWithEvent:(NSString *)eventName
{
    if (!stopped) {
        return;
    }
	if (timer != nil) {
		[timer invalidate];
		RELEASE_TO_NIL(timer);
		if ([self.proxy _hasListeners:eventName]) {
			[self.proxy fireEvent:eventName withObject:nil];
		}
	}
}

-(void)updateTimer{
    if([timer isValid] && !stopped ){
        
        [timer invalidate];
        RELEASE_TO_NIL(timer)
        
        timer = [[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(timerFired:) userInfo:nil repeats:YES] retain]; 
    }
}

-(UIImage*)rotatedImage:(UIImage*)originalImage
{
    //If autorotate is set to false and the image orientation is not UIImageOrientationUp create new image
    if (![TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"autorotate"] def:YES] && (originalImage.imageOrientation != UIImageOrientationUp)) {
        UIImage* theImage = [UIImage imageWithCGImage:[originalImage CGImage] scale:[originalImage scale] orientation:UIImageOrientationUp];
        return theImage;
    }
    else {
        return originalImage;
    }
}

-(void)fireLoadEventWithState:(NSString *)stateString
{
    TiUIImageViewProxy* ourProxy = (TiUIImageViewProxy*)self.proxy;
    [ourProxy propagateLoadEvent:stateString];
}

-(void)animationCompleted:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	for (UIView *view in [self subviews])
	{
		// look for our alpha view which is the placeholder layer
		if (view.alpha == 0)
		{
			[view removeFromSuperview];
			break;
		}
	}
}

-(UIViewContentMode)contentModeForImageView
{
    LayoutConstraint* constraints = [(TiViewProxy*)[self proxy] layoutProperties];
    if (((TiDimensionIsAuto(width) || TiDimensionIsAutoSize(width) || TiDimensionIsUndefined(width)) &&
         (TiDimensionIsUndefined(constraints->left) || TiDimensionIsUndefined(constraints->right))) ||
        ((TiDimensionIsAuto(height) || TiDimensionIsAutoSize(height) || TiDimensionIsUndefined(height)) &&
         (TiDimensionIsUndefined(constraints->top) || TiDimensionIsUndefined(constraints->bottom)))) {
        return UIViewContentModeScaleAspectFit;
    }
    else {
        return scaleType;
    }
}

-(void)updateContentMode
{
    UIViewContentMode curMode = [self contentModeForImageView];
    if (imageView != nil) {
        imageView.contentMode = curMode;
    }
    if (container != nil) {
        for (UIView *view in [container subviews]) {
            UIView *child = [[view subviews] count] > 0 ? [[view subviews] objectAtIndex:0] : nil;
            if (child!=nil && [child isKindOfClass:[UIImageView class]])
            {
                child.contentMode = curMode;
            }
        }
    }
}

-(UIImageView *)imageView
{
	if (imageView==nil)
	{
		imageView = [[UIImageView alloc] initWithFrame:[self bounds]];
		[imageView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        imageView.backgroundColor = [UIColor clearColor];
		[imageView setContentMode:[self contentModeForImageView]];
		[self addSubview:imageView];
	}
	return imageView;
}

- (id)accessibilityElement
{
	return [self imageView];
}

- (id) cloneView:(id)source {
    NSData *archivedViewData = [NSKeyedArchiver archivedDataWithRootObject: source];
    id clone = [NSKeyedUnarchiver unarchiveObjectWithData:archivedViewData];
    return clone;
}

-(void) transitionToImage:(UIImage*)image
{
    ENSURE_UI_THREAD(transitionToImage,image);
    [self updateAutoSizeFromImage:image];
	if (self.proxy==nil)
	{
		// this can happen after receiving an async callback for loading the image
		// but after we've detached our view.  In which case, we need to just ignore this
		return;
	}
    TiTransition* transition = [TiTransitionHelper transitionFromArg:self.transition containerView:self];
    [(TiViewProxy*)[self proxy] contentsWillChange];
    if (transition != nil) {
        UIImageView *iv = [self imageView];
        UIImageView *newView = [self cloneView:iv];
        newView.image = [self convertToUIImage:image];
        [TiTransitionHelper transitionfromView:iv toView:newView insideView:self withTransition:transition completionBlock:^{
            placeholderLoading = NO;
            [self fireLoadEventWithState:@"image"];
        }];
        imageView = [newView retain];
	}
    else {
        [[self imageView] setImage:image];
        [self fireLoadEventWithState:@"image"];
    }
}

-(void)updateAutoSizeFromImage:(id)image
{
    UIImage* imageToUse = nil;
    if ([image isKindOfClass:[UIImage class]]) {
        imageToUse = [self rotatedImage:image];
    }
    else if([image isKindOfClass:[TiSVGImage class]]) {
        autoHeight = _svg.size.height;
        autoWidth = _svg.size.width;
        return;
    }
    else {
        autoHeight = autoWidth = 0;
        return;
    }
    float factor = 1.0f;
    float screenScale = [UIScreen mainScreen].scale;
    if ([TiUtils boolValue:[[self proxy] valueForKey:@"hires"] def:[TiUtils isRetinaDisplay]])
    {
        factor /= screenScale;
    }
    int realWidth = imageToUse.size.width * factor;
    int realHeight = imageToUse.size.height * factor;
    autoWidth = realWidth;
    autoHeight = realHeight;
}

-(void)loadImageInBackground:(NSNumber*)pos
{
	int position = [TiUtils intValue:pos];
	NSURL *theurl = [TiUtils toURL:[_images objectAtIndex:position] proxy:self.proxy];
	UIImage *theimage = [[ImageLoader sharedLoader] loadImmediateImage:theurl];
	if (theimage==nil)
	{
		theimage = [[ImageLoader sharedLoader] loadRemote:theurl];
	}
	if (theimage==nil)
	{
		NSLog(@"[ERROR] couldn't load imageview image: %@ at position: %d",theurl,position);
		return;
	}

    UIImage *imageToUse = [self rotatedImage:theimage];
    
    [self updateAutoSizeFromImage:imageToUse];
    
	TiThreadPerformOnMainThread(^{
		UIView *view = [[container subviews] objectAtIndex:position];
		UIImageView *newImageView = [[UIImageView alloc] initWithFrame:[view bounds]];
		newImageView.image = imageToUse;
		newImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		newImageView.contentMode = [self contentModeForImageView];
		
		// remove the spinner now that we've loaded our image
		UIView *spinner = [[view subviews] count] > 0 ? [[view subviews] objectAtIndex:0] : nil;
		if (spinner!=nil && [spinner isKindOfClass:[UIActivityIndicatorView class]])
		{
			[spinner removeFromSuperview];
		}
		[view addSubview:newImageView];
        [self sendSubviewToBack:newImageView];
		view.clipsToBounds = YES;
		[newImageView release];
		view.hidden = YES;
		
#if IMAGEVIEW_DEBUG	== 1
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 50, 20)];
		label.text = [NSString stringWithFormat:@"%d",position];
		label.font = [UIFont boldSystemFontOfSize:28];
		label.textColor = [UIColor redColor];
		label.backgroundColor = [UIColor clearColor];
		[view addSubview:label];
		[view bringSubviewToFront:label];
		[label release];
#endif	
		
		loadCount++;
		if (loadCount==loadTotal)
		{
			[self fireLoadEventWithState:@"_images"];
		}
		
		if (ready)
		{
			//NOTE: for now i'm just making sure you have at least one frame loaded before starting the timer
			//but in the future we may want to be more sophisticated
			int min = 1;  
			readyCount++;
			if (readyCount >= min)
			{
				readyCount = 0;
				ready = NO;
				
				[self startTimerWithEvent:@"start"];
			}
		}
	}, NO);		
}

-(void)removeAllImagesFromContainer
{
	// remove any existing _images
	if (container!=nil)
	{
		for (UIView *view in [container subviews])
		{
			[view removeFromSuperview];
		}
	}
//	if (imageView!=nil)
//	{
//		imageView.image = nil;
//	}
}

-(void)cancelPendingImageLoads
{
	// cancel a pending request if we have one pending
//	[(TiUIImageViewProxy *)[self proxy] cancelPendingImageLoads];
	placeholderLoading = NO;
}

-(void)loadDefaultImage:(CGSize)_imagesize
{
    // use a placeholder image - which the dev can specify with the
    // defaultImage property or we'll provide the MCTS stock one
    // if not specified
    NSURL *defURL = [TiUtils toURL:[self.proxy valueForKey:@"defaultImage"] proxy:self.proxy];
    
    if ((defURL == nil) && ![TiUtils boolValue:[self.proxy valueForKey:@"preventDefaultImage"] def:NO])
    {	//This is a special case, because it IS built into the bundle despite being in the simulator.
        NSString * filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"modules/ui/_images/photoDefault.png"];
        defURL = [NSURL fileURLWithPath:filePath];
    }
    
    if (defURL!=nil)
    {
        UIImage *poster = [[ImageLoader sharedLoader] loadImmediateImage:defURL withSize:_imagesize];
        
        UIImage *imageToUse = [self rotatedImage:poster];
        
        [self updateAutoSizeFromImage:imageToUse];
        // TODO: Use the full image size here?  Auto width/height is going to be changed once the image is loaded.
        [self imageView].image = imageToUse;
    }
}

-(void)loadUrl:(id)img
{
	[self cancelPendingImageLoads];
	
	if (img!=nil)
	{
		[self removeAllImagesFromContainer];
		
		NSURL *url_ = [TiUtils toURL:[img absoluteString] proxy:self.proxy];
        
        // NOTE: Loading from URL means we can't pre-determine any % value.
		CGSize _imagesize = CGSizeMake(TiDimensionCalculateValue(width, 0.0), 
									  TiDimensionCalculateValue(height,0.0));
        
		if ([TiUtils boolValue:[[self proxy] valueForKey:@"hires"]])
		{
			_imagesize.width *= 2;
			_imagesize.height *= 2;
		}
        UIImage *image = nil;
        if (localLoadSync)
        {
            image = [[ImageLoader sharedLoader] loadImmediateImage:url_];
            if (image == nil && [url_ isFileURL]) {
                image = [UIImage imageWithContentsOfFile:[url_ path]];
                if (image != nil) {
                    [[ImageLoader sharedLoader] cache:image forURL:url_];
                }
            }
        
            if (image != nil) {
                UIImage *imageToUse = [self rotatedImage:image];
                [self transitionToImage:imageToUse];
            }
            else {
                [self loadDefaultImage:_imagesize];
            }
            return;
        }
        
		if (image==nil)
		{
//            [self loadDefaultImage:_imagesize];
			placeholderLoading = YES;
			[(TiUIImageViewProxy *)[self proxy] startImageLoad:url_];
			return;
		}
        
		if (image!=nil)
		{
			UIImage *imageToUse = [self rotatedImage:image];
			[(TiUIImageViewProxy*)[self proxy] setImageURL:url_];
            [self transitionToImage:imageToUse];
		}
	}
}


-(UIView*)container
{
	if (container==nil)
	{
		// we use a separate container view so we can both have an image
		// and a set of _images
		container = [[UIView alloc] initWithFrame:self.bounds];
		container.userInteractionEnabled = NO;
		[self addSubview:container];
	}
	return container;
}

-(id)convertToUIImage:(id)arg
{
    id image = nil;
    UIImage* imageToUse = nil;
	
    if ([arg isKindOfClass:[TiBlob class]]) {
        TiBlob *blob = (TiBlob*)arg;
        image = [blob image];
    }
    else if ([arg isKindOfClass:[TiFile class]]) {
        TiFile *file = (TiFile*)arg;
        NSURL * fileUrl = [NSURL fileURLWithPath:[file path]];
        image = [[ImageLoader sharedLoader] loadImmediateImage:fileUrl];
    }
    else if ([arg isKindOfClass:[UIImage class]]) {
		// called within this class
        image = (UIImage*)arg; 
    }
    else if ([arg isKindOfClass:[TiSVGImage class]]) {
        _svg = [arg retain];
		// called within this class
        image = (TiSVGImage*)arg;
    }
    
	if ([image isKindOfClass:[UIImage class]]) {
        imageToUse = [self rotatedImage:image];
    }
    else if([image isKindOfClass:[TiSVGImage class]]) {
        // NOTE: Loading from URL means we can't pre-determine any % value.
		CGSize _imagesize = CGSizeMake(TiDimensionCalculateValue(width, 0.0),
									  TiDimensionCalculateValue(height,0.0));
        imageToUse = [_svg imageForSize:_imagesize] ;
    }
    
    [self updateAutoSizeFromImage:imageToUse];

    return imageToUse;
}
#pragma mark Public APIs

-(void)animatedImage:(TiAnimatedImage*)animatedImage changedToImage:(UIImage*)image
{
    if (animatedImage.stopped){
        [self transitionToImage:_currentImage];
    }
    else {
        BOOL wasShowingCurrentImage = [self imageView].image == _currentImage;
        if (!animatedImage.paused && !wasShowingCurrentImage) {
            [[self imageView] setImage:image];
        }
        else {
            [self transitionToImage:image];
        }
    }
}

-(void)stop
{
	stopped = YES;
    [self stopTimerWithEvent:@"stop"];
	ready = NO;
	index = -1;
    if (_animatedImage) {
        [_animatedImage stop];
    }
	[self.proxy replaceValue:NUMBOOL(NO) forKey:@"animating" notification:NO];
    [self.proxy replaceValue:NUMBOOL(NO) forKey:@"paused" notification:NO];
}

-(void)start
{
	stopped = NO;
    [self.proxy replaceValue:NUMBOOL(NO) forKey:@"paused" notification:NO];
    if (_animatedImage) {
		[self.proxy replaceValue:NUMBOOL(YES) forKey:@"animating" notification:NO];
        [_animatedImage start];
        return;
    }
	if (iterations<0)
	{
		iterations = 0;
	}
	
	if (index<0)
	{
		if (reverse)
		{
			index = loadTotal-1;
		}
		else
		{
			index = 0;
		}
	}
	
	
	// refuse to start animation if you don't have any _images
	if (loadTotal > 0)
	{
		ready = YES;
		[self.proxy replaceValue:NUMBOOL(YES) forKey:@"animating" notification:NO];
		
		if (timer==nil)
		{
			readyCount = 0;
			ready = NO;
			[self startTimerWithEvent:@"start"];
		}
	}
}

-(void)playpause {
    if (_animatedImage) {
        BOOL paused = [_animatedImage paused];
        [self.proxy replaceValue:NUMBOOL(!paused) forKey:@"paused" notification:NO];
        [self.proxy replaceValue:NUMBOOL(paused) forKey:@"animating" notification:NO];
        if (_animatedImage.paused) {
            [_animatedImage resume];
        }
        else {
            [_animatedImage pause];
        }
    }
}

-(void)pause
{
	stopped = YES;
	[self.proxy replaceValue:NUMBOOL(YES) forKey:@"paused" notification:NO];
	[self.proxy replaceValue:NUMBOOL(NO) forKey:@"animating" notification:NO];
    if (_animatedImage) {
        [_animatedImage pause];
        return;
    }
    [self stopTimerWithEvent:@"pause"];
}

-(void)resume
{
	stopped = NO;
	[self.proxy replaceValue:NUMBOOL(NO) forKey:@"paused" notification:NO];
	[self.proxy replaceValue:NUMBOOL(YES) forKey:@"animating" notification:NO];
    if (_animatedImage) {
        [_animatedImage resume];
        return;
    }
    [self startTimerWithEvent:@"resume"];
}

-(void)setAnimatedImageAtIndex:(int)i
{
    if (_animatedImage) {
        [self.proxy replaceValue:NUMBOOL(NO) forKey:@"animating" notification:NO];
        [self.proxy replaceValue:NUMBOOL(NO) forKey:@"paused" notification:NO];
        [_animatedImage setAnimatedImageAtIndex:i];
        return;
    }
}


-(void)setWidth_:(id)width_
{
    width = TiDimensionFromObject(width_);
    [self updateContentMode];
}

-(void)setHeight_:(id)height_
{
    height = TiDimensionFromObject(height_);
    [self updateContentMode];
}

-(void)setScaleType_:(id)arg
{
	scaleType = [TiUtils intValue:arg];
    [self updateContentMode];
}

-(void)setLocalLoadSync_:(id)arg
{
	localLoadSync = [TiUtils boolValue:arg];
}

-(id)getImage {
    return [[self imageView] image];
}

-(void)setImage_:(id)arg
{

    if (_currentImageSource == arg) return;
    _currentImageSource = arg;
    
	[self removeAllImagesFromContainer];
	[self cancelPendingImageLoads];
    if (_animatedImage) {
        [_animatedImage stop];
    }
	[self.proxy replaceValue:NUMBOOL(NO) forKey:@"animating" notification:NO];
    [self.proxy replaceValue:NUMBOOL(NO) forKey:@"paused" notification:NO];
    
	if (arg==nil || [arg isEqual:@""] || [arg isKindOfClass:[NSNull class]])
	{
		return;
	}
	
	BOOL replaceProperty = YES;
	id image = nil;
    NSURL* imageURL = nil;
    RELEASE_TO_NIL(_svg);
    
    if (localLoadSync || ![arg isKindOfClass:[NSString class]])
        image = [self convertToUIImage:arg];
	
	if (image == nil) 
	{
        NSURL* imageURL = [[self proxy] sanitizeURL:arg];
        if (![imageURL isKindOfClass:[NSURL class]]) {
            [self throwException:@"invalid image type" 
                       subreason:[NSString stringWithFormat:@"expected TiBlob, String, TiFile, was: %@",[arg class]] 
                        location:CODELOCATION];
        }
        
        [self loadUrl:imageURL];
		return;
	}
	[self transitionToImage:image];

	if (_currentImage!=image)
	{
        RELEASE_TO_NIL(_currentImage);
        _currentImage = [image retain];
		[self fireLoadEventWithState:@"image"];
	}
}

-(void)setImages_:(id)args
{
	BOOL running = (timer!=nil);
    usingNewMethod = NO;
	
	[self stop];
	
	if (imageView!=nil)
	{
		[imageView setImage:nil];
	}
	
	// remove any existing _images
	[self removeAllImagesFromContainer];
	
	RELEASE_TO_NIL(_images);
	ENSURE_TYPE_OR_NIL(args,NSArray);
    
	if (args!=nil)
	{
		[self container];
		_images = [[NSMutableArray alloc] initWithCapacity:[args count]];
		loadTotal = [args count];
		for (size_t c = 0; c < [args count]; c++)
		{
			[self queueImage:[args objectAtIndex:c] index:c];
		}
	}
	else
	{
		RELEASE_TO_NIL(container);
	}
	
	// if we were running, re-start it
	if (running)
	{
		[self start];
	}
}

-(void)setDuration_:(id)duration
{
    float dur = [TiUtils floatValue:duration];
    dur =  MAX(IMAGEVIEW_MIN_INTERVAL,dur); 
    
    interval = dur/1000;
    [self.proxy replaceValue:NUMINT(dur) forKey:@"duration" notification:NO];
    
    [self updateTimer];
}

-(void)setRepeatCount_:(id)count
{
	repeatCount = [TiUtils intValue:count];
    [self imageView].animationRepeatCount = [TiUtils intValue:count];
}


-(void)setReverse_:(id)value
{
	reverse = [TiUtils boolValue:value def:reverse];
    if (_animatedImage) {
        _animatedImage.reverse = reverse;
    }
}

-(void)setAutoreverse_:(id)value
{
	autoreverse = [TiUtils boolValue:value];
    if (_animatedImage) {
        _animatedImage.autoreverse = autoreverse;
    }
}

-(void)setAnimatedImages_:(id)args
{
	ENSURE_TYPE_OR_NIL(args,NSArray);
    if (args == nil) {
        RELEASE_TO_NIL(_animatedImage);
        [self transitionToImage:_currentImage];
        return;
    }
    
    NSMutableArray* images = [[NSMutableArray alloc] initWithCapacity:[args count]];
    NSMutableArray* durations = [[NSMutableArray alloc] initWithCapacity:[args count]];
    id anObject;
    NSEnumerator *enumerator = [args objectEnumerator];
    while (anObject = [enumerator nextObject]) {
        [images addObject:[self loadImage:anObject]];
        [durations addObject:NUMFLOAT(interval)];
    }
    _animatedImage = [[TiAnimatedImage alloc] initWithImages:images andDurations:durations];
    _animatedImage.reverse = reverse;
    _animatedImage.autoreverse = autoreverse;
    _animatedImage.delegate = self;
    [_animatedImage reset];
    if ([TiUtils boolValue:[[self proxy] valueForKey:@"animating"]]) {
        [_animatedImage resume];
    }
}

-(void)setImageMask_:(id)arg
{
    UIImage* image = [self loadImage:arg];
	UIImageView *imageview = [self imageView];
    if (image == nil) {
        imageview.layer.mask = nil;
    }
    else {
        if (imageview.layer.mask == nil) {
            imageview.layer.mask = [CALayer layer];
            imageview.layer.mask.frame = self.layer.bounds;
        }
        imageview.layer.opaque = NO;
        imageview.layer.mask.contentsScale = [image scale];
        imageview.layer.mask.magnificationFilter = @"nearest";
        imageview.layer.mask.contents = (id)image.CGImage;
    }
    
    [imageview.layer setNeedsDisplay];
}

-(void)setTransition_:(id)arg
{
    ENSURE_SINGLE_ARG_OR_NIL(arg, NSDictionary)
    self.transition = arg;
}


#pragma mark ImageLoader delegates

-(void)imageLoadSuccess:(ImageLoaderRequest*)request image:(id)image
{
    TiThreadPerformOnMainThread(^{
        RELEASE_TO_NIL(_currentImage);
        _currentImage = [image retain];
        [self transitionToImage:[self convertToUIImage:image]];
    }, NO);
}

-(void)imageLoadFailed:(ImageLoaderRequest*)request error:(NSError*)error
{
	NSLog(@"[ERROR] Failed to load image: %@, Error: %@",[request url], error);
}

@end

#endif
