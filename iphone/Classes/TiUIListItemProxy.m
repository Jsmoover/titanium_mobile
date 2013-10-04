/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#ifdef USE_TI_UILISTVIEW

#import "TiUIListItemProxy.h"
#import "TiUtils.h"
#import "TiUIListItem.h"
#import "TiUIListViewProxy.h"

#define CHILD_ACCESSORY_WIDTH 20.0
#define CHECK_ACCESSORY_WIDTH 20.0
#define DETAIL_ACCESSORY_WIDTH 33.0
#define IOS7_ACCESSORY_EXTRA_OFFSET 15.0

static void SetEventOverrideDelegateRecursive(NSArray *children, id<TiViewEventOverrideDelegate> eventOverrideDelegate);

@implementation TiUIListItemProxy {
	TiUIListViewProxy *_listViewProxy; // weak
	NSDictionary *_bindings;
    NSMutableDictionary *_initialValues;
	NSMutableDictionary *_currentValues;
	NSMutableSet *_resetKeys;
    BOOL unarchived;
    BOOL enumeratingResetKeys;
}

@synthesize listItem = _listItem;
@synthesize indexPath = _indexPath;
@synthesize parentForBubbling = _parentForBubbling;

static NSArray* keysToGetFromListView;
-(NSArray *)keysToGetFromListView
{
	if (keysToGetFromListView == nil)
	{
		keysToGetFromListView = [[NSArray arrayWithObjects:@"accessoryType",@"selectionStyle",@"selectedBackgroundColor",@"selectedBackgroundImage",@"selectedBackgroundGradient", nil] retain];
	}
	return keysToGetFromListView;
}


- (id)initWithListViewProxy:(TiUIListViewProxy *)listViewProxy inContext:(id<TiEvaluator>)context
{
    self = [self _initWithPageContext:context];
    if (self) {
        unarchived = NO;
        enumeratingResetKeys = NO;
        _initialValues = [[NSMutableDictionary alloc] initWithCapacity:10];
		_currentValues = [[NSMutableDictionary alloc] initWithCapacity:10];
		_resetKeys = [[NSMutableSet alloc] initWithCapacity:10];
		_listViewProxy = listViewProxy;
		[context.krollContext invokeBlockOnThread:^{
			[context registerProxy:self];
			[listViewProxy rememberProxy:self];
		}];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(void) setListItem:(TiUIListItem *)newListItem
{
    //we must not retain the item or we get a cyclic retain problem
//    RELEASE_TO_NIL(_listItem);
    _listItem = newListItem;
    view = _listItem.viewHolder;
    [view initializeState];
    viewInitialized = YES;
    [self setReadyToCreateView:YES];
    [self windowWillOpen];
    [self windowDidOpen];
    [self willShow];
}

-(void)dealloc
{
    _listItem = nil;
    _parentForBubbling = nil;
    [_initialValues release];
	[_currentValues release];
	[_resetKeys release];
	[_indexPath release];
	[_bindings release];
	[super dealloc];
}

-(TiProxy*)parentForBubbling
{
	return _parentForBubbling;
}


- (void)detachView
{
	view = nil;
	[super detachView];
}

-(void)_destroy
{
	view = nil;
	[super _destroy];
}

-(void)_initWithProperties:(NSDictionary*)properties
{
    [super _initWithProperties:properties];
//    if (_listItem != nil) {
//        [self applyCellProps:properties];
//    }
//    else {
//        [self getCellPropsFromDict:properties];
//    }
}

- (void)unarchiveFromTemplate:(id)viewTemplate
{
	[super unarchiveFromTemplate:viewTemplate];
	SetEventOverrideDelegateRecursive(self.children, self);
    unarchived = YES;
}

- (void)unarchiveFakeFromTemplate:(id)viewTemplate
{
	[super unarchiveFakeFromTemplate:viewTemplate];
    unarchived = YES;
}

- (NSDictionary *)bindings
{
	if (_bindings == nil &&  unarchived) {
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
		[self buildBindingsForViewProxy:self intoDictionary:dict];
		_bindings = [dict copy];
		[dict release];
	}
	return _bindings;
}

//-(void)setValue:(id)value forUndefinedKey:(NSString *)key
//{
//    if ([self shouldUpdateValue:value forKeyPath:key]) {
//        [self recordChangeValue:value forKeyPath:key withBlock:^{
//            [super setValue:value forUndefinedKey:key];
//        }];
//    }
//}

-(void)setValue:(id)value forKey:(NSString *)key
{
    if ([self shouldUpdateValue:value forKeyPath:key]) {
        [self recordChangeValue:value forKeyPath:key withBlock:^{
            [super setValue:value forKey:key];
        }];
    }
}

- (void)setDataItem:(NSDictionary *)dataItem
{
	[_resetKeys addObjectsFromArray:[_currentValues allKeys]];
	id propertiesValue = [dataItem objectForKey:@"properties"];
    NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:propertiesValue];
    NSInteger templateStyle = (_listItem != nil)?_listItem.templateStyle:TiUIListItemTemplateStyleCustom;
	switch (templateStyle) {
		case UITableViewCellStyleSubtitle:
		case UITableViewCellStyleValue1:
		case UITableViewCellStyleValue2:
		case UITableViewCellStyleDefault:
            unarchived = YES;
			break;
			
		default:
			[dataItem enumerateKeysAndObjectsUsingBlock:^(NSString *bindId, id dict, BOOL *stop) {
				if (![dict isKindOfClass:[NSDictionary class]] || [bindId isEqualToString:@"properties"]) {
					return;
				}
				id bindObject = [self valueForUndefinedKey:bindId];
				if (bindObject != nil) {
					BOOL reproxying = NO;
					if ([bindObject isKindOfClass:[TiProxy class]]) {
						[bindObject setReproxying:YES];
						reproxying = YES;
					}
					[(NSDictionary *)dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
						NSString *keyPath = [NSString stringWithFormat:@"%@.%@", bindId, key];
						if ([self shouldUpdateValue:value forKeyPath:keyPath]) {
							[self recordChangeValue:value forKeyPath:keyPath withBlock:^{
								[bindObject setValue:value forKey:key];
							}];
						}
					}];
					if (reproxying) {
						[bindObject setReproxying:NO];
					}
				}
			}];
			break;
	}
    
    NSDictionary* listViewProps = [_listViewProxy allProperties];
    for (NSString* key in [self keysToGetFromListView]) {
        if ([listViewProps objectForKey:key] && ![properties objectForKey:key]) {
            [properties setObject:[listViewProps objectForKey:key] forKey:key];
        }
    }
    
    if (_listItem != nil) {
        [self setValuesForKeysWithDictionary:properties];
    }
    
    
    enumeratingResetKeys = YES;
	[_resetKeys enumerateObjectsUsingBlock:^(NSString *keyPath, BOOL *stop) {
		id value = [_initialValues objectForKey:keyPath];
		[super setValue:(value != [NSNull null] ? value : nil) forKeyPath:keyPath];
		[_currentValues removeObjectForKey:keyPath];
	}];
    [_resetKeys removeAllObjects];
    enumeratingResetKeys = NO;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    if ([self.bindings objectForKey:key])
        return [self.bindings objectForKey:key];
    return [super valueForUndefinedKey:key];
}


- (void)recordChangeValue:(id)value forKeyPath:(NSString *)keyPath withBlock:(void(^)(void))block
{
    if (!unarchived) {
        block();
        return;
    }
	if ([_initialValues objectForKey:keyPath] == nil) {
		id initialValue = [self valueForKeyPath:keyPath];
		[_initialValues setObject:(initialValue != nil ? initialValue : [NSNull null]) forKey:keyPath];
	}
	block();
	if (value != nil) {
		[_currentValues setObject:value forKey:keyPath];
	} else {
		[_currentValues removeObjectForKey:keyPath];
	}
	if (!enumeratingResetKeys) [_resetKeys removeObject:keyPath];
}

- (BOOL)shouldUpdateValue:(id)value forKeyPath:(NSString *)keyPath
{
	id current = [_currentValues objectForKey:keyPath];
	BOOL sameValue = ((current == value) || [current isEqual:value]);
	if (sameValue && !enumeratingResetKeys) {
		[_resetKeys removeObject:keyPath];
	}
	return !sameValue;
}

#pragma mark - Static

- (void)buildBindingsForViewProxy:(TiViewProxy *)viewProxy intoDictionary:(NSMutableDictionary *)dict
{
    NSInteger templateStyle = TiUIListItemTemplateStyleCustom;
    if ([viewProxy isKindOfClass:[TiUIListItemProxy class]]) { //toplevel
        TiUIListItem* listItem = ((TiUIListItemProxy*)viewProxy).listItem;
        templateStyle = (listItem != nil)?listItem.templateStyle:TiUIListItemTemplateStyleCustom;
        
    }
    switch (templateStyle) {
        case UITableViewCellStyleSubtitle:
        case UITableViewCellStyleValue1:
        case UITableViewCellStyleValue2:
        case UITableViewCellStyleDefault:
            //only called in top level
            [dict setObject:[viewProxy autorelease] forKey:@"imageView"];
            [dict setObject:[viewProxy autorelease] forKey:@"textLabel"];
            break;
        default:
        {
            NSArray* myChildren = [viewProxy children];
            [myChildren enumerateObjectsUsingBlock:^(TiViewProxy *childViewProxy, NSUInteger idx, BOOL *stop) {
                [self buildBindingsForViewProxy:childViewProxy intoDictionary:dict];
            }];
            if (![viewProxy isKindOfClass:[TiUIListItemProxy class]]) {
                id bindId = [viewProxy valueForKey:@"bindId"];
                if (bindId != nil) {
                    [dict setObject:viewProxy forKey:bindId];
                }
            }
        }
    }
}

#pragma mark - TiViewEventOverrideDelegate

- (NSDictionary *)overrideEventObject:(NSDictionary *)eventObject forEvent:(NSString *)eventType fromViewProxy:(TiViewProxy *)viewProxy
{
	NSMutableDictionary *updatedEventObject = [eventObject mutableCopy];
	[updatedEventObject setObject:NUMINT(_indexPath.section) forKey:@"sectionIndex"];
	[updatedEventObject setObject:NUMINT(_indexPath.row) forKey:@"itemIndex"];
	[updatedEventObject setObject:[_listViewProxy sectionForIndex:_indexPath.section] forKey:@"section"];
	id propertiesValue = [_listItem.dataItem objectForKey:@"properties"];
	NSDictionary *properties = ([propertiesValue isKindOfClass:[NSDictionary class]]) ? propertiesValue : nil;
	id itemId = [properties objectForKey:@"itemId"];
	if (itemId != nil) {
		[updatedEventObject setObject:itemId forKey:@"itemId"];
	}
	id bindId = [viewProxy valueForKey:@"bindId"];
	if (bindId != nil) {
		[updatedEventObject setObject:bindId forKey:@"bindId"];
	}
	return [updatedEventObject autorelease];
}

-(CGFloat)sizeWidthForDecorations:(CGFloat)oldWidth forceResizing:(BOOL)force
{
    CGFloat width = oldWidth;
    BOOL updateForiOS7 = NO;
    if (force) {
        if ([TiUtils boolValue:[self valueForKey:@"hasChild"] def:NO]) {
            width -= CHILD_ACCESSORY_WIDTH;
            updateForiOS7 = YES;
        }
        else if ([TiUtils boolValue:[self valueForKey:@"hasDetail"] def:NO]) {
            width -= DETAIL_ACCESSORY_WIDTH;
            updateForiOS7 = YES;
        }
        else if ([TiUtils boolValue:[self valueForKey:@"hasCheck"] def:NO]) {
            width -= CHECK_ACCESSORY_WIDTH;
            updateForiOS7 = YES;
        }
    }
    
    if (updateForiOS7 && [TiUtils isIOS7OrGreater]) {
        width -= IOS7_ACCESSORY_EXTRA_OFFSET;
    }
	
    return width;
}

@end

static void SetEventOverrideDelegateRecursive(NSArray *children, id<TiViewEventOverrideDelegate> eventOverrideDelegate)
{
	[children enumerateObjectsUsingBlock:^(TiViewProxy *child, NSUInteger idx, BOOL *stop) {
		child.eventOverrideDelegate = eventOverrideDelegate;
		SetEventOverrideDelegateRecursive(child.children, eventOverrideDelegate);
	}];
}

#endif
