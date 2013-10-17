//
//  TiTransitionSwipeFade.m
//  Titanium
//
//  Created by Martin Guillon on 14/10/13.
//
//

#import "TiTransitionSwipeFade.h"
#import "TiTransitionHelper.h"

@implementation TiTransitionSwipeFade
-(void)transformView:(UIView*)view withPosition:(CGFloat)position adjustTranslation:(BOOL)adjust size:(CGSize)size
{
//    if (position >1 || position < -1) {
//        view.alpha = 0;
//        return;
//    }
    BOOL before = (position < 0);
    float multiplier = 1;
    float dest = 0;
    if (![TiTransitionHelper isTransitionPush:self]) {
        multiplier = -1;
        before = !before;
    }
    
    int viewWidth = view.frame.size.width;
    int viewHeight = view.frame.size.height;
    
    float alpha = 1;
    if (before) { //out
        dest = multiplier* ABS(position)*(1.0f-kSwipeFadeTranslate);
        alpha = 1.0f - ABS(position);
    }
    
    view.alpha = alpha;
    if (adjust) {
        if ([TiTransitionHelper isTransitionVertical:self]) {
           view.layer.transform = CATransform3DMakeTranslation(0.0f, viewWidth * dest, 0.0f);
        }
        else {
            view.layer.transform = CATransform3DMakeTranslation(viewHeight * dest, 0.0f, 0.0f);
        }
    }
    
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
-(BOOL)needsReverseDrawOrder
{
    return ![TiTransitionHelper isTransitionPush:self];
}

-(void)prepareViewHolder:(UIView*)holder{}
@end
