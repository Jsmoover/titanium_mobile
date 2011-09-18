package org.appcelerator.kroll.runtime.v8;

import java.io.IOException;

import org.appcelerator.kroll.runtime.Assets;

import android.util.Log;

public final class V8Runtime
{
	private static final String TAG = "V8Runtime";
	private static V8Context globalContext;

	private V8Runtime() { }

	public static V8Context init()
	{
		if (globalContext == null) {
			System.loadLibrary("kroll-v8");
			long contextPtr = nativeInit(new V8Runtime());
			globalContext = new V8Context(contextPtr);
		}
		return globalContext;
	}

	public static void evalFile(V8Object scope, String filename)
	{
		try {
			Log.d(TAG, "evalFile: " + filename);
			char[] chars = Assets.readResource(filename);
			if (chars != null && chars.length > 0) {
				V8Script.runInContext(new String(chars), globalContext, filename);
			}
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}

	private static native long nativeInit(V8Runtime runtime);
	public static native void dispose();

	/*
	private static native void nativeInitModuleTemplate(Class<?> moduleClass);
	public static void initModuleTemplate(Class<?> moduleClass)
	{
		nativeInitModuleTemplate(moduleClass);
	}
	*/

}
