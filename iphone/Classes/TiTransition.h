//
//  TiTransion.h
//  Titanium
//
//  Created by Martin Guillon on 14/10/13.
//
//

#import "ADTransition.h"
#import "TiTransitionHelper.h"

#define kPerspective -1000
@interface TiTransition: NSObject
{
    ADTransition* _adTransition;
}
@property(nonatomic,readonly)	ADTransition* adTransition;
@property(nonatomic,assign)	NWTransition type;
@property(nonatomic,readonly)	ADTransitionOrientation orientation;

- (id)initWithADTransition:(ADTransition*)transition;
-(void)transformView:(UIView*)view withPosition:(CGFloat)position;
-(void)transformView:(UIView*)view withPosition:(CGFloat)position adjustTranslation:(BOOL)adjust;
-(void)transformView:(UIView*)view withPosition:(CGFloat)position size:(CGSize)size;
-(BOOL)needsReverseDrawOrder;
-(void)prepareViewHolder:(UIView*)holder;
-(BOOL)isTransitionVertical;
-(BOOL)isTransitionPush;
-(void)reverseADTransition;
@end
