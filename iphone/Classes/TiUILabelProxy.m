/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#ifdef USE_TI_UILABEL

#import "TiUILabelProxy.h"
#import "TiUILabel.h"
#import "TiUtils.h"
#import "DTCoreText.h"

#define kDefaultFontSize 12.0

static inline CTTextAlignment UITextAlignmentToCTTextAlignment(UITextAlignment alignment)
{
    switch (alignment) {
        case UITextAlignmentLeft:
            return kCTLeftTextAlignment;
        case UITextAlignmentRight:
            return kCTRightTextAlignment;
        default:
            return kCTCenterTextAlignment;
            break;
    }
}

static inline CTLineBreakMode UILineBreakModeToCTLineBreakMode(UILineBreakMode linebreak)
{
    switch (linebreak) {
        case UILineBreakModeClip:
            return kCTLineBreakByClipping;
        case UILineBreakModeCharacterWrap:
            return kCTLineBreakByCharWrapping;
        case UILineBreakModeHeadTruncation:
            return kCTLineBreakByTruncatingHead;
        case UILineBreakModeTailTruncation:
            return kCTLineBreakByTruncatingTail;
        case UILineBreakModeMiddleTruncation:
            return kCTLineBreakByTruncatingMiddle;
        case UILineBreakModeWordWrap:
        default:
            return kCTLineBreakByWordWrapping;
            break;
    }
}

@implementation TiUILabelProxy

USE_VIEW_FOR_CONTENT_WIDTH

-(id)init
{
    if (self = [super init]) {
        attributeTextNeedsUpdate = YES;
        UIColor* color = [UIColor darkTextColor];
        options = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt:kCTLeftTextAlignment], DTDefaultTextAlignment,
                    color, DTDefaultTextColor,
                    color, DTDefaultLinkColor,
                    [NSNumber numberWithInt:0], DTDefaultFontStyle,
                    @"Helvetica", DTDefaultFontFamily,
                     [NSNumber numberWithFloat:(17 / kDefaultFontSize)], NSTextSizeMultiplierDocumentOption,
                     kCTLineBreakByWordWrapping, DTDefaultLineBreakMode, nil] retain];
    }
    return self;
}

- (void)updateAttributeText {
    
    if (!configSet) {
        attributeTextNeedsUpdate = YES;
        return; // lazy init
    }
    
    RELEASE_TO_NIL(realLabelContent);
    switch (_contentType) {
        case kContentTypeHTML:
        {
            realLabelContent = [[NSAttributedString alloc] initWithHTMLData:[contentString dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil];
            break;
        }
        default:
        {
            realLabelContent = [contentString retain];
            break;
        }
    }
    [(TiUILabel*)[self view] setAttributedTextViewContent];
    attributeTextNeedsUpdate = NO;
    [self contentsWillChange];
}

-(void)_initWithProperties:(NSDictionary *)properties
{
    configSet = FALSE;
    [super _initWithProperties:properties];
    configSet = YES;
    if (attributeTextNeedsUpdate)
        [self updateAttributeText];
}

-(CGFloat)contentHeightForWidth:(CGFloat)suggestedWidth
{
//    if ([self view])
        return [[self view] contentHeightForWidth:suggestedWidth];
//    else
//    {
//        if (realLabelContent != nil)
//        {
//            CGSize resultSize = CGSizeZero;
//            CGRect textPadding = CGRectZero;
//            if ([self valueForKey:@"textPaddingLeft"])
//                textPadding.origin.x = [TiUtils intValue:[self valueForKey:@"textPaddingLeft"]];
//            if ([self valueForKey:@"textPaddingRight"])
//                textPadding.size.width = [TiUtils intValue:[self valueForKey:@"textPaddingRight"]];
//            if ([self valueForKey:@"textPaddingTop"])
//                textPadding.origin.y = [TiUtils intValue:[self valueForKey:@"textPaddingTop"]];
//            if ([self valueForKey:@"textPaddingBottom"])
//                textPadding.size.height = [TiUtils intValue:[self valueForKey:@"textPaddingBottom"]];
//            
//            CGSize maxSize = CGSizeMake(suggestedWidth<=0 ? 480 : suggestedWidth, 10000);
//            maxSize.width -= textPadding.origin.x + textPadding.size.width;
//            if ([realLabelContent isKindOfClass:[NSAttributedString class]])
//                resultSize = [(NSAttributedString*)realLabelContent boundingRectWithSize:maxSize options:0 context:nil].size;
//            else
//            {
//                UILineBreakMode breakMode = UILineBreakModeWordWrap;
//                if ([self valueForKey:@"ellipsize"])
//                    breakMode = [TiUtils intValue:[self valueForKey:@"ellipsize"]];
//                id fontValue = [self valueForKey:@"font"];
//                UIFont * font;
//                if (fontValue!=nil)
//                {
//                    font = [[TiUtils fontValue:fontValue] font];
//                }
//                else
//                {
//                    font = [UIFont systemFontOfSize:17];
//                }
//                resultSize = [(NSString*)realLabelContent sizeWithFont:font constrainedToSize:maxSize lineBreakMode:breakMode];
//            }
//            resultSize.width += textPadding.origin.x + textPadding.size.width;
//            resultSize.height += textPadding.origin.y + textPadding.size.height;
//            return resultSize.height;
//        }
//    }
//    return 0;
}

-(CGFloat) verifyWidth:(CGFloat)suggestedWidth
{
	int width = ceil(suggestedWidth);
	if (width & 0x01)
	{
		width ++;
	}
	return width;
}

-(CGFloat) verifyHeight:(CGFloat)suggestedHeight
{
	int height = ceil(suggestedHeight);
	if (height & 0x01)
	{
		height ++;
	}
	return height;
}

-(NSArray *)keySequence
{
	static NSArray *labelKeySequence = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		labelKeySequence = [[NSArray arrayWithObjects:@"font",@"color",@"textAlign",@"multiLineEllipsize",nil] retain];
	});
	return labelKeySequence;
}

-(NSMutableDictionary*)langConversionTable
{
    return [NSMutableDictionary dictionaryWithObject:@"text" forKey:@"textid"];
}

-(TiDimension)defaultAutoWidthBehavior:(id)unused
{
    return TiDimensionAutoSize;
}
-(TiDimension)defaultAutoHeightBehavior:(id)unused
{
    return TiDimensionAutoSize;
}


//we do it in the proxy for faster performances in tableviews
-(void)setText:(id)value
{
    [self setAttributedTextViewContent:[TiUtils stringValue:value] ofType:kContentTypeText];
	[self replaceValue:value forKey:@"text" notification:YES];
}

-(void)setHtml:(id)value
{
    [self setAttributedTextViewContent:[TiUtils stringValue:value] ofType:kContentTypeHTML];
	[self replaceValue:value forKey:@"html" notification:YES];
}

-(void)setColor:(id)color
{
	UIColor * newColor = [[TiUtils colorValue:color] _color];
    if (newColor == nil)
        newColor = [UIColor darkTextColor];
    [options setValue:newColor forKey:DTDefaultTextColor];
    [options setValue:newColor forKey:DTDefaultLinkColor];
    
    //we need to reset the text to update default paragraph settings
    [self updateAttributeText];
	[self replaceValue:color forKey:@"color" notification:YES];
}

-(void)setFont:(id)font
{
    WebFont* webFont =[TiUtils fontValue:font];
    int traitsDefault = 0;
    if (webFont.isItalicStyle)
        traitsDefault |= kCTFontItalicTrait;
    if (webFont.isBoldWeight)
        traitsDefault |= kCTFontBoldTrait;
    [options setValue:[NSNumber numberWithInt:traitsDefault] forKey:DTDefaultFontStyle];
    if (webFont.family)
        [options setValue:webFont.family forKey:DTDefaultFontFamily];
    else
        [options setValue:@"Helvetica" forKey:DTDefaultFontFamily];
    [options setValue:[NSNumber numberWithFloat:(webFont.size / kDefaultFontSize)] forKey:NSTextSizeMultiplierDocumentOption];
    
    //we need to reset the text to update default paragraph settings
    [self updateAttributeText];
	[self replaceValue:font forKey:@"font" notification:YES];
}

-(void)setTextAlign:(id)alignment
{
    [options setValue:[NSNumber numberWithInt:UITextAlignmentToCTTextAlignment([TiUtils textAlignmentValue:alignment])] forKey:DTDefaultTextAlignment];
    
    //we need to reset the text to update default paragraph settings
    [self updateAttributeText];
	[self replaceValue:alignment forKey:@"textAlign" notification:YES];
}

-(void)setMultiLineEllipsize:(id)value
{
    int multilineBreakMode = [TiUtils intValue:value];
    if (multilineBreakMode != UILineBreakModeWordWrap)
    {
        [options setValue:[NSNumber numberWithInt:UILineBreakModeToCTLineBreakMode(multilineBreakMode)]  forKey:DTDefaultLineBreakMode];
        
        //we need to update the text
        [self updateAttributeText];
    }
	[self replaceValue:value forKey:@"multiLineEllipsize" notification:YES];
}

- (void)setAttributedTextViewContent:(id)newContentString ofType:(ContentType)contentType {
    if (newContentString == nil) {
        RELEASE_TO_NIL(contentString);
        RELEASE_TO_NIL(realLabelContent);
        _contentHash = 0;
        return;
    }
    
    // we don't preserve the string but compare it's hash
	NSUInteger newHash = [newContentString hash];
	
	if (newHash == _contentHash)
	{
		return;
	}
    _contentHash = newHash;
    RELEASE_TO_NIL(contentString);
    contentString = [newContentString retain];
    _contentType = contentType;
    [self updateAttributeText];
}

-(id)getLabelContent
{
    return realLabelContent;
}


@end

#endif