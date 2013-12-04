/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#ifdef USE_TI_UILABEL

#import "TiUILabel.h"
#import "TiUILabelProxy.h"
#import "TiUtils.h"
#import "UIImage+Resize.h"
#import <CoreText/CoreText.h>
#ifdef USE_TI_UIIOSATTRIBUTEDSTRING
#import "TiUIiOSAttributedStringProxy.h"
#endif
#import "DTCoreText.h"

@implementation TiUILabel

#pragma mark Internal

-(id)init
{
    if (self = [super init]) {
        padding = CGRectZero;
        textPadding = CGRectZero;
        initialLabelFrame = CGRectZero;
    }
    return self;
}

-(void)dealloc
{
    RELEASE_TO_NIL(label);
    [super dealloc];
}

-(UIView*)viewForHitTest
{
    return label;
}

- (CGSize)suggestedFrameSizeToFitEntireStringConstraintedToSize:(CGSize)size
{
    CGSize maxSize = CGSizeMake(size.width<=0 ? 480 : size.width, 10000);
    maxSize.width -= textPadding.origin.x + textPadding.size.width;
    
    CGSize result = [[self label] sizeThatFits:maxSize];
    result.width = MIN(result.width,  maxSize.width);
    if (size.height > 0) result.height = MIN(result.height,  size.height);
    if (label.numberOfLines > 0 || label.attributedText != nil) {
        CGRect textRect = [[self label] textRectForBounds:CGRectMake(0,0,result.width, maxSize.height) limitedToNumberOfLines:label.numberOfLines];
        
        textRect.size.height -= 2*textRect.origin.y;
        result =textRect.size;
    }
    result.width += textPadding.origin.x + textPadding.size.width;
    result.height += textPadding.origin.y + textPadding.size.height;
    return result;
}

-(CGSize)contentSizeForSize:(CGSize)size
{
    return [self suggestedFrameSizeToFitEntireStringConstraintedToSize:size];
}

-(void)padLabel
{
    if (!configurationSet) {
        needsPadLabel = YES;
        return; // lazy init
    }
	CGRect	initFrame = CGRectMake(initialLabelFrame.origin.x + textPadding.origin.x
                                   , initialLabelFrame.origin.y + textPadding.origin.y
                                   , initialLabelFrame.size.width - textPadding.origin.x - textPadding.size.width
                                   , initialLabelFrame.size.height - textPadding.origin.y - textPadding.size.height);
    [label setFrame:initFrame];
    if ([self backgroundLayer] != nil && !CGRectIsEmpty(initialLabelFrame))
    {
        [self updateBackgroundImageFrameWithPadding];
    }
	return;
}

-(void)setCenter:(CGPoint)newCenter
{
	[super setCenter:CGPointMake(floorf(newCenter.x), floorf(newCenter.y))];
}

-(void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
    initialLabelFrame = bounds;
    [self padLabel];
    [super frameSizeChanged:frame bounds:bounds];
}

- (void)configurationStart {
    [super configurationStart];
    needsUpdateBackgroundImageFrame = needsPadLabel = needsSetText = NO;
}

- (void)configurationSet {
    
    [super configurationSet];
    if (needsPadLabel)
        [self padLabel];
    
    if (needsUpdateBackgroundImageFrame)
        [self updateBackgroundImageFrameWithPadding];
    
    if (needsSetText)
        [self setAttributedTextViewContent];
}

-(TTTAttributedLabel*)label
{
	if (label==nil)
	{
        label = [[TDTTTAttributedLabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.numberOfLines = 0;//default wordWrap to True
        label.lineBreakMode = UILineBreakModeWordWrap; //default ellipsis to none
        label.layer.shadowRadius = 0; //for backward compatibility
        label.layer.shadowOffset = CGSizeZero;
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.touchDelegate = self;
        label.strokeColorAttributeProperty = DTBackgroundStrokeColorAttribute;
        label.strokeWidthAttributeProperty = DTBackgroundStrokeWidthAttribute;
        label.cornerRadiusAttributeProperty = DTBackgroundCornerRadiusAttribute;
        label.delegate = self;
        [self addSubview:label];
	}
	return label;
}

-(BOOL)proxyHasGestureListeners
{
    return [super proxyHasGestureListeners] || [(TiViewProxy*)[self proxy] _hasListeners:@"link" checkParent:NO];
}

-(void)ensureGestureListeners
{
    if ([(TiViewProxy*)[self proxy] _hasListeners:@"link" checkParent:NO]) {
        [[self gestureRecognizerForEvent:@"link"] setEnabled:YES];
    }
    [super ensureGestureListeners];
}

- (UIGestureRecognizer *)gestureRecognizerForEvent:(NSString *)event
{
    if ([event isEqualToString:@"link"]) {
        return [super gestureRecognizerForEvent:@"longpress"];
    }
    return [super gestureRecognizerForEvent:event];
}

-(void)handleListenerRemovedWithEvent:(NSString *)event
{
	ENSURE_UI_THREAD_1_ARG(event);
	// unfortunately on a remove, we have to check all of them
	// since we might be removing one but we still have others
    if ([event isEqualToString:@"link"] || [event isEqualToString:@"longpress"]) {
        BOOL enableListener = [self.proxy _hasListeners:@"longpress"] || [self.proxy _hasListeners:@"link"];
        [[self gestureRecognizerForEvent:event] setEnabled:enableListener];
    } else {
        [super handleListenerRemovedWithEvent:event];
    }
}

-(BOOL)checkLinkAttributeForString:(NSMutableAttributedString*)theString atPoint:(CGPoint)p
{
    CGPoint thePoint = [self convertPoint:p toView:label];
    CGRect drawRect = [label textRectForBounds:[label bounds] limitedToNumberOfLines:label.numberOfLines];
    drawRect.origin.y = (label.bounds.size.height - drawRect.size.height)/2;
    thePoint = CGPointMake(thePoint.x - drawRect.origin.x, thePoint.y - drawRect.origin.y);
    //Convert to CT point;
    thePoint.y = (drawRect.size.height - thePoint.y);
    CTFramesetterRef theRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)theString);
    if (theRef == NULL) {
        return;
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathAddRect(path, NULL, drawRect);

    CTFrameRef frame = CTFramesetterCreateFrame(theRef, CFRangeMake(0, [theString length]), path, NULL);
    //Don't need this anymore
    CFRelease(theRef);

    if (frame == NULL) {
        CFRelease(path);
        return NO;
    }
    //Get Lines
    CFArrayRef lines = CTFrameGetLines(frame);
    if (lines == NULL) {
        CFRelease(frame);
        CFRelease(path);
        return NO;
    }
    
    NSInteger lineCount = CFArrayGetCount(lines);
    if (lineCount == 0) {
        CFRelease(frame);
        CFRelease(path);
        //CFRelease(lines);
        return NO;
    }
    //Get Line Origins
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, lineCount), lineOrigins);
    
    NSUInteger idx = NSNotFound;
    for (CFIndex lineIndex = 0; (lineIndex < lineCount) && (idx == NSNotFound); lineIndex++) {
        
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        // Get bounding information of line
        CGRect lineRect = CTLineGetBoundsWithOptions(line,0);
        CGFloat ymin = lineRect.origin.y + lineOrigin.y;
        CGFloat ymax = ymin + lineRect.size.height;
        
        if (ymin <= thePoint.y && ymax >= thePoint.y) {
            if (thePoint.x >= lineOrigin.x && thePoint.x <= lineOrigin.x + lineRect.size.width) {
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(thePoint.x - lineOrigin.x, thePoint.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
            }
        }
    }
    
    //Don't need frame,path or lines now
    CFRelease(frame);
    CFRelease(path);
    //CFRelease(lines);
    
    if (idx != NSNotFound) {
        if(idx > theString.string.length) {
            return NO;
        }
        NSRange theRange = NSMakeRange(0, 0);
        NSString *url = [theString attribute:NSLinkAttributeName atIndex:idx effectiveRange:&theRange];
        if(url != nil && url.length) {
            NSDictionary *eventDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                       url, @"url",
                                       [NSArray arrayWithObjects:NUMINT(theRange.location), NUMINT(theRange.length),nil],@"range",
                                       nil];
                                            
            [[self proxy] fireEvent:@"link" withObject:eventDict propagate:NO reportSuccess:NO errorCode:0 message:nil];
            return YES;
        }
    }
    return NO;
}

-(void)recognizedLongPress:(UILongPressGestureRecognizer*)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint p = [recognizer locationInView:self];
        if ([self.proxy _hasListeners:@"longpress"]) {
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NUMFLOAT(p.x), @"x",
                                   NUMFLOAT(p.y), @"y",
                                   nil];
            [self.proxy fireEvent:@"longpress" withObject:event];
        }
        if ([(TiViewProxy*)[self proxy] _hasListeners:@"link" checkParent:NO] && (label != nil) && [TiUtils isIOS7OrGreater]) {
            NSMutableAttributedString* optimizedAttributedText = [label.attributedText mutableCopy];
            if (optimizedAttributedText != nil) {
                // use label's font and lineBreakMode properties in case the attributedText does not contain such attributes
                [label.attributedText enumerateAttributesInRange:NSMakeRange(0, [label.attributedText length]) options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                    if (!attrs[(NSString*)kCTFontAttributeName]) {
                        [optimizedAttributedText addAttribute:(NSString*)kCTFontAttributeName value:label.font range:range];
                    }
                    if (!attrs[(NSString*)kCTParagraphStyleAttributeName]) {
                        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                        [paragraphStyle setLineBreakMode:label.lineBreakMode];
                        [optimizedAttributedText addAttribute:(NSString*)kCTParagraphStyleAttributeName value:paragraphStyle range:range];
                    }
                }];
                
                // modify kCTLineBreakByTruncatingTail lineBreakMode to kCTLineBreakByWordWrapping
                [optimizedAttributedText enumerateAttribute:(NSString*)kCTParagraphStyleAttributeName inRange:NSMakeRange(0, [optimizedAttributedText length]) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
                    NSMutableParagraphStyle* paragraphStyle = [value mutableCopy];
                    if ([paragraphStyle lineBreakMode] == kCTLineBreakByTruncatingTail) {
                        [paragraphStyle setLineBreakMode:kCTLineBreakByWordWrapping];
                    }
                    [optimizedAttributedText removeAttribute:(NSString*)kCTParagraphStyleAttributeName range:range];
                    [optimizedAttributedText addAttribute:(NSString*)kCTParagraphStyleAttributeName value:paragraphStyle range:range];
                }];
                [self checkLinkAttributeForString:optimizedAttributedText atPoint:p];
                [optimizedAttributedText release];
            }
        }
    }
}

- (id)accessibilityElement
{
	return [self label];
}

- (void)setAttributedTextViewContent {
    if (!configurationSet) {
        needsSetText = YES;
        return; // lazy init
    }
    if (![NSThread isMainThread])
    {
        TiThreadPerformOnMainThread(^{
            [self setAttributedTextViewContent];
        }, NO);
        return;
    }
    
    id attr = [(TiUILabelProxy*)[self proxy] getLabelContent];
    [[self label] setText:attr];
}

-(void)setHighlighted:(BOOL)newValue
{
    [super setHighlighted:newValue];
    [[self label] setHighlighted:newValue];
}

- (void)didMoveToSuperview
{
	[self setHighlighted:NO];
	[super didMoveToSuperview];
}

- (void)didMoveToWindow
{
    /*
     * See above
     */
    [self setHighlighted:NO];
    [super didMoveToWindow];
}

-(BOOL)isHighlighted
{
    return [[self label] isHighlighted];
}

#pragma mark Public APIs

-(void)setVerticalAlign_:(id)value
{
    UIControlContentVerticalAlignment verticalAlign = [TiUtils contentVerticalAlignmentValue:value];
    [[self label] setVerticalAlignment:(TTTAttributedLabelVerticalAlignment)verticalAlign];
}
-(void)setAutoLink_:(id)value
{
    [[self label] setDataDetectorTypes:[TiUtils intValue:value]];
    //we need to update the text
    [self setAttributedTextViewContent];
}

-(void)setColor_:(id)color
{
	UIColor * newColor = [[TiUtils colorValue:color] _color];
    if (newColor == nil)
        newColor = [UIColor darkTextColor];
	[[self label] setTextColor:newColor];
}

//-(void)setText_:(id)value
//{
//	[self setAttributedTextViewContent];
//}
//
//-(void)setHtml_:(id)value
//{
//	[self setAttributedTextViewContent];
//}

-(void)setText_:(id)value
{
    needsSetText = YES;
}

-(void)setHtml_:(id)value
{
    needsSetText = YES;
}

-(void)setHighlightedColor_:(id)color
{
	UIColor * newColor = [[TiUtils colorValue:color] _color];
	[[self label] setHighlightedTextColor:(newColor != nil)?newColor:[UIColor lightTextColor]];
}

-(void)setSelectedColor_:(id)color
{
	UIColor * newColor = [[TiUtils colorValue:color] _color];
	[[self label] setHighlightedTextColor:(newColor != nil)?newColor:[UIColor lightTextColor]];
}

-(void)setFont_:(id)fontValue
{
    UIFont * font;
    if (fontValue!=nil)
    {
        font = [[TiUtils fontValue:fontValue] font];
    }
    else
    {
        font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
    }
	[[self label] setFont:font];
}

-(void)setMinimumFontSize_:(id)size
{
    CGFloat newSize = [TiUtils floatValue:size];
    if (newSize < 4) { // Beholden to 'most minimum' font size
        [[self label] setAdjustsFontSizeToFitWidth:NO];
        [[self label] setMinimumFontSize:0.0];
    }
    else {
        [[self label] setAdjustsFontSizeToFitWidth:YES];
        [[self label] setMinimumFontSize:newSize];
    }
    [self updateNumberLines];   
}

-(void)setBackgroundImageLayerBounds:(CGRect)bounds
{
    if ([self backgroundLayer] != nil)
    {
        CGRect backgroundFrame = CGRectMake(bounds.origin.x - padding.origin.x,
                                            bounds.origin.y - padding.origin.y,
                                            bounds.size.width + padding.origin.x + padding.size.width,
                                            bounds.size.height + padding.origin.y + padding.size.height);
        [self backgroundLayer].frame = backgroundFrame;
    }
}

-(void) updateBackgroundImageFrameWithPadding
{
    if (!configurationSet){
        needsUpdateBackgroundImageFrame = YES;
        return; // lazy init
    }
    [self setBackgroundImageLayerBounds:self.bounds];
}

-(void)setAttributedString_:(id)arg
{
#ifdef USE_TI_UIIOSATTRIBUTEDSTRING
    ENSURE_SINGLE_ARG(arg, TiUIiOSAttributedStringProxy);
    [[self proxy] replaceValue:arg forKey:@"attributedString" notification:NO];
    [[self label] setAttributedText:[arg attributedString]];
    [self padLabel];
    [(TiViewProxy *)[self proxy] contentsWillChange];
#endif
}

-(void)setBackgroundImage_:(id)url
{
    [super setBackgroundImage_:url];
    //if using padding we must not mask to bounds.
    [self backgroundLayer].masksToBounds = CGRectEqualToRect(padding, CGRectZero) ;
    [self updateBackgroundImageFrameWithPadding];
}

-(void)setBackgroundPaddingLeft_:(id)left
{
    padding.origin.x = [TiUtils floatValue:left];
    [self updateBackgroundImageFrameWithPadding];
}

-(void)setBackgroundPaddingRight_:(id)right
{
    padding.size.width = [TiUtils floatValue:right];
    [self updateBackgroundImageFrameWithPadding];
}

-(void)setBackgroundPaddingTop_:(id)top
{
    padding.origin.y = [TiUtils floatValue:top];
    [self updateBackgroundImageFrameWithPadding];
}

-(void)setBackgroundPaddingBottom_:(id)bottom
{
    padding.size.height = [TiUtils floatValue:bottom];
    [self updateBackgroundImageFrameWithPadding];
}

-(void)setTextAlign_:(id)alignment
{
	[[self label] setTextAlignment:[TiUtils textAlignmentValue:alignment]];
}

-(void)setShadowColor_:(id)color
{
	if (color==nil)
	{
		[[[self label] layer]setShadowColor:nil];
	}
	else
	{
		color = [TiUtils colorValue:color];
		[[self label] setShadowColor:[color _color]];
	}
}

-(void)setShadowRadius_:(id)arg
{
    [[self label] setShadowRadius:[TiUtils floatValue:arg]];
}
-(void)setShadowOffset_:(id)value
{
	CGPoint p = [TiUtils pointValue:value];
	CGSize size = {p.x,p.y};
	[[self label] setShadowOffset:size];
}

-(void)setTextPadding_:(id)value
{
	ENSURE_SINGLE_ARG(value,NSDictionary);
    NSDictionary* paddingDict = (NSDictionary*)value;
    if ([paddingDict objectForKey:@"left"]) {
        textPadding.origin.x = [TiUtils floatValue:[paddingDict objectForKey:@"left"]];
    }
    if ([paddingDict objectForKey:@"right"]) {
        textPadding.size.width = [TiUtils floatValue:[paddingDict objectForKey:@"right"]];
    }
    if ([paddingDict objectForKey:@"top"]) {
        textPadding.origin.y = [TiUtils floatValue:[paddingDict objectForKey:@"top"]];
    }
    if ([paddingDict objectForKey:@"bottom"]) {
        textPadding.size.height = [TiUtils floatValue:[paddingDict objectForKey:@"bottom"]];
    }
    [self padLabel];
}

-(void) updateNumberLines
{
    if ([[self label] minimumFontSize] >= 4.0)
    {
        [[self label] setNumberOfLines:1];
    }
    else if ([[self proxy] valueForKey:@"maxLines"])
        [[self label] setNumberOfLines:([[[self proxy] valueForKey:@"maxLines"] integerValue])];
    else
    {
        BOOL shouldWordWrap = [TiUtils boolValue:[[self proxy] valueForKey:@"wordWrap"] def:YES];
        if (shouldWordWrap)
        {
            [[self label] setNumberOfLines:0];
        }
        else
        {
            [[self label] setNumberOfLines:1];
        }
    }
}

-(void)setWordWrap_:(id)value
{
    [self updateNumberLines];
}

-(void)setMaxLines_:(id)value
{
	[self updateNumberLines];
}

-(void)setEllipsize_:(id)value
{
    [[self label] setLineBreakMode:[TiUtils intValue:value]];
}


-(void)setMultiLineEllipsize_:(id)value
{
    int multilineBreakMode = [TiUtils intValue:value];
    if (multilineBreakMode != UILineBreakModeWordWrap)
    {
        [[self label] setLineBreakMode:UILineBreakModeWordWrap];
    }
}


#pragma mark -
#pragma mark DTAttributedTextContentViewDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

- (void)attributedLabel:(TTTAttributedLabel *)label
didSelectLinkWithAddress:(NSDictionary *)addressComponents
{
    NSMutableString* address = [NSMutableString string];
    NSString* temp = nil;
    if((temp = [addressComponents objectForKey:NSTextCheckingStreetKey]))
        [address appendString:temp];
    if((temp = [addressComponents objectForKey:NSTextCheckingCityKey]))
        [address appendString:[NSString stringWithFormat:@"%@%@", ([address length] > 0) ? @", " : @"", temp]];
    if((temp = [addressComponents objectForKey:NSTextCheckingStateKey]))
        [address appendString:[NSString stringWithFormat:@"%@%@", ([address length] > 0) ? @", " : @"", temp]];
    if((temp = [addressComponents objectForKey:NSTextCheckingZIPKey]))
        [address appendString:[NSString stringWithFormat:@" %@", temp]];
    if((temp = [addressComponents objectForKey:NSTextCheckingCountryKey]))
        [address appendString:[NSString stringWithFormat:@"%@%@", ([address length] > 0) ? @", " : @"", temp]];
    NSString* urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%@", [address stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (void)attributedLabel:(TTTAttributedLabel *)label
didSelectLinkWithPhoneNumber:(NSString *)phoneNumber
{
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
    [[UIApplication sharedApplication] openURL:url];
}

//- (void)attributedLabel:(TTTAttributedLabel *)label
//  didSelectLinkWithDate:(NSDate *)date
//{
//    [[UIApplication sharedApplication] openURL:url];
//}
//
//- (void)attributedLabel:(TTTAttributedLabel *)label
//  didSelectLinkWithDate:(NSDate *)date
//               timeZone:(NSTimeZone *)timeZone
//               duration:(NSTimeInterval)duration
//{
//    [[UIApplication sharedApplication] openURL:url];
//}

@end

#endif
