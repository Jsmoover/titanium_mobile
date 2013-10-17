//
//  TiTransitionCarousel.m
//  Titanium
//
//  Created by Martin Guillon on 14/10/13.
//
//

#import "TiTransitionCarousel.h"
#import "TiTransitionHelper.h"

#define kArc M_PI * 2.0f

@interface TiTransitionCarousel()

@end
@implementation TiTransitionCarousel

- (id)initWithDuration:(CFTimeInterval)duration orientation:(ADTransitionOrientation)orientation sourceRect:(CGRect)sourceRect {
    if (self = [super initWithDuration:duration orientation:orientation sourceRect:sourceRect]) {
        _faceNb = 4;
    }
    return self;
}

-(void)transformView:(UIView*)view withPosition:(CGFloat)position adjustTranslation:(BOOL)adjust size:(CGSize)size
{
    if (position >1 || position < -1) return;
    
    float multiplier = 1;
    if (![TiTransitionHelper isTransitionPush:self]) {
        multiplier = -1;
    }
    
    int viewWidth = view.bounds.size.width;
    int viewHeight = view.bounds.size.height;
    CATransform3D transform = CATransform3DIdentity;
    if (!adjust) transform.m34 = 1.0 / kPerspective;
    if ([TiTransitionHelper isTransitionVertical:self]) {
        CGFloat radius = -fmaxf(0.01f, viewHeight / 2.0f / tanf(kArc/2.0f/_faceNb));
        CGFloat angle = -position / _faceNb * kArc;
        CGFloat translateY = -position * viewHeight * multiplier;
        if (adjust) transform = CATransform3DTranslate(transform, 0, -translateY, 0);
        transform = CATransform3DTranslate(transform, 0.0f, 0.0f, -radius);
        transform = CATransform3DRotate(transform, angle, -1.0f, 0.0f, 0.0f);
        transform =  CATransform3DTranslate(transform, 0.0f, 0.0f, radius+ 0.01f);
    }
    else {
        CGFloat radius = -fmaxf(0.01f, viewWidth / 2.0f / tanf(kArc/2.0f/_faceNb));
        CGFloat angle = -position / _faceNb * kArc;
        CGFloat translateX = -position * viewWidth * multiplier;
        if (adjust) transform = CATransform3DTranslate(transform, translateX, 0, 0);
        transform = CATransform3DTranslate(transform, 0.0f, 0.0f, -radius);
        transform = CATransform3DRotate(transform, angle, 0.0f, 1.0f, 0.0f);
        transform =  CATransform3DTranslate(transform, 0.0f, 0.0f, radius+ 0.01f);

    }
    view.layer.transform = transform;

}

-(void)transformView:(UIView*)view withPosition:(CGFloat)position adjustTranslation:(BOOL)adjust
{
    [self transformView:view withPosition:position adjustTranslation:adjust size:view.bounds.size];
}
-(void)transformView:(UIView*)view withPosition:(CGFloat)position size:(CGSize)size
{
    [self transformView:view withPosition:position adjustTranslation:NO size:size];
}
-(void)transformView:(UIView*)view withPosition:(CGFloat)position
{
    [self transformView:view withPosition:position adjustTranslation:NO size:view.bounds.size];
}
-(void)prepareViewHolder:(UIView*)holder
{
    CATransform3D sublayerTransform = CATransform3DIdentity;
    sublayerTransform.m34 = 1.0 / kPerspective;
    holder.layer.sublayerTransform = sublayerTransform;
}

-(BOOL)needsReverseDrawOrder
{
    return [TiTransitionHelper isTransitionPush:self];
}
@end
