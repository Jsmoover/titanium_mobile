//
//  TiTransitionCube.m
//  Titanium
//
//  Created by Martin Guillon on 16/10/13.
//
//

#import "TiTransitionCube.h"
#import "TiTransitionHelper.h"

#define kArc M_PI * 2.0f

@interface TiTransitionCube()

@end
@implementation TiTransitionCube

- (id)initWithDuration:(CFTimeInterval)duration orientation:(ADTransitionOrientation)orientation sourceRect:(CGRect)sourceRect {
    if (self = [super initWithDuration:duration orientation:orientation sourceRect:sourceRect]) {
        _faceNb = 4;
    }
    return self;
}


-(void)transformView:(UIView*)view withPosition:(CGFloat)position adjustTranslation:(BOOL)adjust size:(CGSize)size
{
    if (fabs(position) >= _faceNb - 1)
    {
        view.layer.hidden = YES;
        return;
    }
    view.layer.hidden = NO;
    view.layer.shouldRasterize = YES;
    view.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    view.layer.doubleSided = NO;
    
    float multiplier = 1;
    if (![TiTransitionHelper isTransitionPush:self]) {
        multiplier = -1;
    }
    CATransform3D transform = CATransform3DIdentity;
    if (!adjust) {
        transform.m34 = 1.0 / kPerspective;
    }
    if ([TiTransitionHelper isTransitionVertical:self]) {
        CGFloat radius = fmaxf(0.0f, size.height / 2.0f / tanf(kArc/2.0f/_faceNb));
        CGFloat angle = position / _faceNb * kArc;
        if (adjust) {
            CGFloat translateY = -position * size.height * multiplier;
            transform = CATransform3DTranslate(transform, 0, -translateY, 0);
        }
        transform = CATransform3DTranslate(transform, 0.0f, 0.0f, -radius);
        transform = CATransform3DRotate(transform, angle, -1.0f, 0.0f, 0.0f);
        transform =  CATransform3DTranslate(transform, 0.0f, 0.0f, radius);
    }
    else {
        CGFloat radius = fmaxf(0.0f, size.width / 2.0f / tanf(kArc/2.0f/_faceNb));
        CGFloat angle = position * kArc / _faceNb;
        if (adjust) {
            CGFloat translateX = -position * size.width * multiplier;
            transform = CATransform3DTranslate(transform, translateX, 0, 0);
        }
        transform = CATransform3DTranslate(transform, 0.0f, 0.0f, -radius);
        transform = CATransform3DRotate(transform, angle, 0.0f, 1.0f, 0.0f);
        transform =  CATransform3DTranslate(transform, 0.0f, 0.0f, radius);
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
