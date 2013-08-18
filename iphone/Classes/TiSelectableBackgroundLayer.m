#import "TiSelectableBackgroundLayer.h"
#import "TiGradient.h"

@interface TiDrawable()
{
    UIImage* _bufferImage;
}
-(void)updateInLayer:(TiSelectableBackgroundLayer*)layer onlyCreateImage:(BOOL)onlyCreate;

@end
@implementation TiDrawable
@synthesize gradient, color, image, imageRepeat;

- (id)init {
    if (self = [super init])
    {
        imageRepeat = NO;
    }
    return self;
}

- (void) dealloc
{
	[_bufferImage release];
	[gradient release];
	[color release];
	[image release];
	[super dealloc];
}

-(void)setInLayer:(TiSelectableBackgroundLayer*)layer onlyCreateImage:(BOOL)onlyCreate animated:(BOOL)animated
{
    
    if (_bufferImage == nil && (gradient != nil ||
                                color != nil ||
                                image != nil)) {
        if (CGRectEqualToRect(layer.frame, CGRectZero))
            return;
        [self drawBufferFromLayer:layer];
    }
    if (onlyCreate) return;
    if (animated) {
        layer.animateTransition = YES;
        [CATransaction begin];
        [CATransaction setDisableActions:NO];
    }
    if (_bufferImage == nil) {
        if (layer.contents != nil) {
            [layer setContents:nil];
        }
    } else if (layer.contents == nil) {
        
        if (image != nil) {
            layer.contentsScale = image.scale;
            layer.contentsCenter = TiDimensionLayerContentCenterFromInsents(image.capInsets, [image size]);
            
        }
        else {
            layer.contentsScale = [[UIScreen mainScreen] scale];
            layer.contentsCenter = CGRectMake(0, 0, 1, 1);
        }
        if (!CGPointEqualToPoint(layer.contentsCenter.origin,CGPointZero)) {
            layer.magnificationFilter = @"nearest";
        } else {
            layer.magnificationFilter = @"linear";
        }
        id content = layer.contents;
        [layer setContents:(id)_bufferImage.CGImage];
    }
    if (animated) {
        [CATransaction commit];
        layer.animateTransition = NO;
    }
}
-(void)drawBufferFromLayer:(CALayer*)layer
{
    CGRect rect = layer.bounds;
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (ctx == 0) {
        UIGraphicsEndImageContext();
        return;
    }
    [self drawInContext:UIGraphicsGetCurrentContext() inRect:rect];
    _bufferImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
    UIGraphicsEndImageContext();
}

-(void)drawInContext:(CGContextRef)ctx inRect:(CGRect)rect
{
    CGContextSaveGState(ctx);
    
    CGContextSetAllowsAntialiasing(ctx, true);
    if (color) {
        CGContextSetFillColorWithColor(ctx, [color CGColor]);
        CGContextFillRect(ctx, rect);
    }
    if (gradient){
        [gradient paintContext:ctx bounds:rect];
    }
    
    if (image){
        if (imageRepeat) {
            CGContextTranslateCTM(ctx, 0, rect.size.height);
            CGContextScaleCTM(ctx, 1.0, -1.0);
            CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
            CGContextDrawTiledImage(ctx, imageRect, image.CGImage);
        }
        else {
            UIGraphicsPushContext(ctx);
            [image drawInRect:rect];
            UIGraphicsPopContext();
        }
    }
    CGContextRestoreGState(ctx);
}

-(void)updateInLayer:(TiSelectableBackgroundLayer*)layer  onlyCreateImage:(BOOL)onlyCreate
{
    if (_bufferImage == nil || imageRepeat) {
        RELEASE_TO_NIL(_bufferImage);
        [self setInLayer:layer  onlyCreateImage:onlyCreate animated:NO];
    }
}

@end

@interface TiSelectableBackgroundLayer()
{
    TiDrawable* currentDrawable;
    UIControlState currentState;
    BOOL _animateTransition;
    BOOL _needsToSetDrawables;
}
@end

@implementation TiSelectableBackgroundLayer
@synthesize stateLayers, stateLayersMap, imageRepeat = _imageRepeat, readyToCreateDrawables, animateTransition = _animateTransition;

- (id) initWithLayer:(id)layer {
    if(self = [super initWithLayer:layer]) {
        if([layer isKindOfClass:[TiSelectableBackgroundLayer class]]) {
            TiSelectableBackgroundLayer *other = (TiSelectableBackgroundLayer*)layer;
        }
    }
    return self;
}

- (id)init {
    if (self = [super init])
    {
        stateLayersMap = [[NSMutableDictionary dictionaryWithCapacity:4] retain];
        currentDrawable = [self getOrCreateDrawableForState:UIControlStateNormal];
        stateLayers = [[NSMutableArray array] retain];
        currentState = UIControlStateNormal;
        _imageRepeat = NO;
        readyToCreateDrawables = NO;
        _needsToSetDrawables = NO;
        _animateTransition = NO;
        self.masksToBounds=YES;
        self.contentsScale = [[UIScreen mainScreen] scale];
   }
    return self;
}

- (void) dealloc
{
    currentDrawable = nil;
	[stateLayersMap release];
	[stateLayers release];
	[super dealloc];
}

-(void)setFrame:(CGRect)frame
{
    BOOL needsToUpdate = (frame.size.width != 0 && frame.size.height!= 0 && (!CGSizeEqualToSize(frame.size, self.frame.size) || _needsToSetDrawables));
    
	[super setFrame:frame];
    if (needsToUpdate) {
        CGSize size = self.frame.size;
       _needsToSetDrawables = NO;
        [stateLayersMap enumerateKeysAndObjectsUsingBlock: ^(id key, TiDrawable* drawable, BOOL *stop) {
            if (drawable != nil) {
                [drawable updateInLayer:self onlyCreateImage:(drawable != currentDrawable)];
            }
        }];
    }
}

-(void)setImageRepeat:(BOOL)imageRepeat
{
    _imageRepeat = imageRepeat;
    
    [stateLayersMap enumerateKeysAndObjectsUsingBlock: ^(id key, TiDrawable* drawable, BOOL *stop) {
        if (drawable != nil) {
            drawable.imageRepeat = _imageRepeat;
        }
    }];
}

- (void)setState:(UIControlState)state animated:(BOOL)animated
{
    if (state == currentState) return;
    
    TiDrawable* newDrawable = (TiDrawable*)[stateLayersMap objectForKey:[[NSNumber numberWithInt:state] stringValue]];
    if (newDrawable == nil && state != UIControlStateNormal) {
        newDrawable = (TiDrawable*)[stateLayersMap objectForKey:[[NSNumber numberWithInt:UIControlStateNormal] stringValue]];
        state = UIControlStateNormal;
    }
    if (newDrawable != nil && newDrawable != currentDrawable) {
        currentDrawable = newDrawable;
        [currentDrawable setInLayer:self onlyCreateImage:NO animated:animated];
    }
    currentState = state;
}

- (void)setState:(UIControlState)state
{
    [self setState:state animated:NO];
}

- (UIControlState)getState
{
    return currentState;
    
}

- (id<CAAction>)actionForKey:(NSString *)event
{
    if (!_animateTransition && ([event isEqualToString:@"contents"] || [event isEqualToString:@"hidden"] || [event isEqualToString:@"mask"]))
        return nil;
    if ([event isEqualToString:@"contents"])
    {
        return [CATransition animation];
    }
    
    id action = [super actionForKey:event];
    return action;
}

-(TiDrawable*) getOrCreateDrawableForState:(UIControlState)state
{
    NSString* key = [[NSNumber numberWithInt:state] stringValue];
    TiDrawable* drawable = (TiDrawable*)[stateLayersMap objectForKey:key];
    if (drawable == nil) {
        drawable = [[TiDrawable alloc] init];
        drawable.imageRepeat = _imageRepeat;
        [stateLayersMap setObject:drawable forKey:key];
        [drawable release];
        if (currentDrawable == nil && state == currentState) {
            currentDrawable = drawable;
        }
    }
    return drawable;
}


-(TiDrawable*) getDrawableForState:(UIControlState)state
{
    NSString* key = [[NSNumber numberWithInt:state] stringValue];
    TiDrawable* drawable = (TiDrawable*)[stateLayersMap objectForKey:key];
    return drawable;
}

- (void)setColor:(UIColor*)color forState:(UIControlState)state
{
    TiDrawable* drawable = [self getOrCreateDrawableForState:state];
    drawable.color = color;
    if (readyToCreateDrawables) {
        [drawable updateInLayer:self onlyCreateImage:(state != currentState)];
    }
}


- (void)setImage:(UIImage*)image forState:(UIControlState)state
{
    TiDrawable* drawable = [self getOrCreateDrawableForState:state];
    drawable.image = image;
    if (readyToCreateDrawables) {
        [drawable updateInLayer:self onlyCreateImage:(state != currentState)];
    }
}

- (void)setGradient:(TiGradient*)gradient forState:(UIControlState)state
{
    TiDrawable* drawable = [self getOrCreateDrawableForState:state];
    drawable.gradient = gradient;
    if (readyToCreateDrawables) {
        [drawable updateInLayer:self onlyCreateImage:(state != currentState)];
    }
}

- (void)setReadyToCreateDrawables:(BOOL)value
{
    if (value != readyToCreateDrawables) {
        readyToCreateDrawables = value;
        if (readyToCreateDrawables) {
            if (self.frame.size.width != 0 && self.frame.size.height!= 0) {
                CGSize size = self.frame.size;
                [stateLayersMap enumerateKeysAndObjectsUsingBlock: ^(id key, TiDrawable* drawable, BOOL *stop) {
                    if (drawable != nil) {
                        [drawable updateInLayer:self onlyCreateImage:(drawable != currentDrawable)];
                    }
                }];
            }
            else {
                _needsToSetDrawables = YES;
            }
            
        }
    }
}

-(void) setHidden:(BOOL)hidden animated:(BOOL)animated
{
    self.animateTransition = animated;
    [self setHidden:hidden];
    self.animateTransition = NO;

}


@end