/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#ifndef DebugLog
#if defined(APSHTTP_DEBUG) || defined(DEVELOPER)
#define DebugLog(...) { NSLog(__VA_ARGS__); }
#else
#define DebugLog(...) {}
#endif
#endif

#import "APSHTTPRequest.h"
#import "APSHTTPResponse.h"
#import "APSHTTPPostForm.h"
#import "APSHTTPHelper.h"
