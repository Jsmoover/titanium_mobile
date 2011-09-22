/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2011 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#ifndef V8_RUNTIME_H
#define V8_RUNTIME_H

#include <jni.h>
#include <v8.h>

using namespace v8;

namespace titanium {
class V8Runtime
{
public:
	static Persistent<Context> globalContext;

	static void setKrollProxyHandle(jobject krollProxy, Handle<Object> v8Object);

	static void collectWeakRef(Persistent<Value> ref, void *parameter);
	static void bootstrap(Local<Object> global);
};
}
;

#endif
