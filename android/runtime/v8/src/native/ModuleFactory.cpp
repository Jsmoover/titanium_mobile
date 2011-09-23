/*
 * Appcelerator Titanium Mobile
 * Copyright (c) 2011 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#include <v8.h>
#include "ModuleFactory.h"
#include "JNIUtil.h"
#include "KrollJavaScript.h"

#include "ModuleInit.h"

namespace titanium {
using namespace internal;

bool ModuleFactory::HasModule(const char *moduleName)
{
	return !!ModuleHash::lookupModuleInit(moduleName, strlen(moduleName));
}

bool ModuleFactory::InitializeModule(const char *moduleName, v8::Handle<v8::Object> target)
{
	moduleInit* module = ModuleHash::lookupModuleInit(moduleName, strlen(moduleName));
	if (module) {
		if (strcmp(moduleName, "titanium") == 0) {
			KrollProxy::Initialize(target);
			KrollJavaScript::initExtend(KrollProxy::proxyTemplate->PrototypeTemplate());
		}
		module->fn(target);
	}
	return (!!module);
}

}

