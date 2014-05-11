/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2010 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#ifdef USE_TI_APP

#import "TiAppPropertiesProxy.h"
#import "TiUtils.h"
#import "TiApp.h"


@implementation TiAppPropertiesProxy {
	NSData *_defaultsNull;
    NSString* _changedProperty;
}

-(void)dealloc
{
	TiThreadPerformOnMainThread(^{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}, YES);
	RELEASE_TO_NIL(_defaultsNull);
	RELEASE_TO_NIL(_changedProperty);
    
	[super dealloc];
}

-(NSString*)apiName
{
    return @"Ti.App.Properties";
}

-(void)_listenerAdded:(NSString*)type count:(int)count
{
	if (count == 1 && [type isEqual:@"change"])
	{
		TiThreadPerformOnMainThread(^{
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NSUserDefaultsDidChange) name:NSUserDefaultsDidChangeNotification object:nil];
		}, YES);
	}
}

-(void)_listenerRemoved:(NSString*)type count:(int)count
{
	if (count == 0 && [type isEqual:@"change"])
	{
		TiThreadPerformOnMainThread(^{
			[[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
		}, YES);
	}
}

-(NSUserDefaults*)userDefaults
{
    return [[TiApp app] userDefaults];
}

-(void)_configure
{
	_defaultsNull = [[NSData alloc] initWithBytes:"NULL" length:4];
	[super _configure];
}

-(BOOL)propertyExists: (NSString *) key;
{
	if (![key isKindOfClass:[NSString class]]) return NO;
	[[self userDefaults] synchronize];
	return ([[self userDefaults] objectForKey:key] != nil);
}

#define GETPROP \
ENSURE_TYPE(args,NSArray);\
NSString *key = [args objectAtIndex:0];\
id appProp = [[TiApp tiAppProperties] objectForKey:key]; \
if(appProp) { \
return appProp; \
} \
id defaultValue = [args count] > 1 ? [args objectAtIndex:1] : [NSNull null];\
if (![self propertyExists:key]) return defaultValue; \

-(id)getBool:(id)args
{
	GETPROP
	return [NSNumber numberWithBool:[[self userDefaults] boolForKey:key]];
}

-(id)getDouble:(id)args
{
	GETPROP
	return [NSNumber numberWithDouble:[[self userDefaults] doubleForKey:key]];
}

-(id)getInt:(id)args
{
	GETPROP
	return [NSNumber numberWithInt:[[self userDefaults] integerForKey:key]];
}

-(id)getString:(id)args
{
	GETPROP
	return [[self userDefaults] stringForKey:key];
}

-(id)getList:(id)args
{
	GETPROP
	NSArray *value = [[self userDefaults] arrayForKey:key];
	NSMutableArray *array = [[[NSMutableArray alloc] initWithCapacity:[value count]] autorelease];
	[(NSArray *)value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if ([obj isKindOfClass:[NSData class]] && [_defaultsNull isEqualToData:obj]) {
			obj = [NSNull null];
		}
		[array addObject:obj];
	}];
	return array;
}

-(id)getObject:(id)args
{
    GETPROP
    id theObject = [[self userDefaults] objectForKey:key];
    if ([theObject isKindOfClass:[NSData class]]) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:theObject];
    }
    else {
        return theObject;
    }
    
}

#define SETPROP \
ENSURE_TYPE(args,NSArray);\
NSString *key = [args objectAtIndex:0];\
id appProp = [[TiApp tiAppProperties] objectForKey:key]; \
if(appProp) { \
DebugLog(@"[ERROR] Property \"%@\" already exist and cannot be overwritten", key); \
return; \
} \
id value = [args count] > 1 ? [args objectAtIndex:1] : nil;\
if (value==nil || value==[NSNull null]) {\
[[self userDefaults] removeObjectForKey:key];\
[[self userDefaults] synchronize]; \
return;\
}\
if ([self propertyExists:key] && [ [[self userDefaults] objectForKey:key] isEqual:value]) {\
return;\
}\

-(void)setBool:(id)args
{
	SETPROP
    _changedProperty = [key retain];
	[[self userDefaults] setBool:[TiUtils boolValue:value] forKey:key];
	[[self userDefaults] synchronize];
}

-(void)setDouble:(id)args
{
	SETPROP
    _changedProperty = [key retain];
	[[self userDefaults] setDouble:[TiUtils doubleValue:value] forKey:key];
	[[self userDefaults] synchronize];
}

-(void)setInt:(id)args
{
	SETPROP
    _changedProperty = [key retain];
	[[self userDefaults] setInteger:[TiUtils intValue:value] forKey:key];
	[[self userDefaults] synchronize];
}

-(void)setString:(id)args
{
	SETPROP
    _changedProperty = [key retain];
	[[self userDefaults] setObject:[TiUtils stringValue:value] forKey:key];
	[[self userDefaults] synchronize];
}

-(void)setList:(id)args
{
	SETPROP
	if ([value isKindOfClass:[NSArray class]]) {
		NSMutableArray *array = [[[NSMutableArray alloc] initWithCapacity:[value count]] autorelease];
		[(NSArray *)value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([obj isKindOfClass:[NSNull class]]) {
				obj = _defaultsNull;
			}
			[array addObject:obj];
		}];
		value = array;
	}
    _changedProperty = [key retain];
	[[self userDefaults] setObject:value forKey:key];
	[[self userDefaults] synchronize];
}

-(void)setObject:(id)args
{
	SETPROP
	NSData* encoded = [NSKeyedArchiver archivedDataWithRootObject:value];
    _changedProperty = [key retain];
	[[self userDefaults] setObject:encoded forKey:key];
	[[self userDefaults] synchronize];
}

-(void)removeProperty:(id)args
{
	ENSURE_SINGLE_ARG(args,NSString);
    if([[TiApp tiAppProperties] objectForKey:args] != nil) {
        DebugLog(@"[ERROR] Cannot remove property \"%@\", it is read-only.", args);
        return;
    }
    _changedProperty = [[TiUtils stringValue:args] retain];
	[[self userDefaults] removeObjectForKey:_changedProperty];
	[[self userDefaults] synchronize];
}

-(void)removeAllProperties {
	NSArray *keys = [[[self userDefaults] dictionaryRepresentation] allKeys];
	for(NSString *key in keys) {
		[[self userDefaults] removeObjectForKey:key];
	}
}

-(id)hasProperty:(id)args
{
    ENSURE_SINGLE_ARG(args,NSString);
    BOOL inUserDefaults = [self propertyExists:[TiUtils stringValue:args]];
    BOOL inTiAppProperties = [[TiApp tiAppProperties] objectForKey:args] != nil;
    return NUMBOOL(inUserDefaults || inTiAppProperties);
}

-(id)listProperties:(id)args
{
    NSMutableArray *array = [NSMutableArray array];
    [array addObjectsFromArray:[[[self userDefaults] dictionaryRepresentation] allKeys]];
    [array addObjectsFromArray:[[TiApp tiAppProperties] allKeys]];
    return array;
}

-(void) NSUserDefaultsDidChange
{
    NSDictionary* event = nil;
    if (_changedProperty != nil) {
        event = [NSDictionary dictionaryWithObject:_changedProperty forKey:@"property"];
        RELEASE_TO_NIL(_changedProperty);
    }
	[self fireEvent:@"change" withObject:event];
}


@end

#endif
