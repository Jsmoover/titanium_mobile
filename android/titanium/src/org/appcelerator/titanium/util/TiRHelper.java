package org.appcelerator.titanium.util;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import org.appcelerator.titanium.TiApplication;

import android.util.Log;

/*
 * A Class which allows us to pull resource integers 
 * off of the various R class structures using
 * strings at runtime.
 */
public class TiRHelper {
	private static final String LCAT = "TiRHelper";
	
	private static Map<String, Class<?>> clsCache = Collections.synchronizedMap(new HashMap<String, Class<?>>());
	private static Map<String, Integer>  valCache = Collections.synchronizedMap(new HashMap<String, Integer>());
	
	public static final class ResourceNotFoundException extends ClassNotFoundException {
		private static final long serialVersionUID = 119234857198273641L;
		
		public ResourceNotFoundException(String resource) {
			super("Resource not found: " + resource);
		}
	}

	public static enum RType {
		ANDROID,
		APPLICATION,
		// Does Ti have its own R that should be represented here?
	}
	
	public static int getResource(RType type, String path) throws ResourceNotFoundException {
		// Check the cache for this value
		String tp = type.toString() + "/" + path;
		Integer i = valCache.get(tp);
		if (i != null) return i;
		
		// Figure out what the base classname is based on the type of R we will query
		String classname = "";
		String fieldname = "";
		switch (type) {
		case ANDROID:
			classname = "android.R";
			break;
		case APPLICATION:
		default:
			classname = TiApplication.getInstance().getApplicationInfo().packageName + ".R";
			break;
		}
		
		// Get the fieldname and any extra path (as internal classes)
		if (path.lastIndexOf('.') < 0)
			fieldname = path;
		else {
			classname = classname + "$" + path.substring(0, path.lastIndexOf('.')).replace('.', '$');
			fieldname = path.substring(path.lastIndexOf('.')+1);
		}

		// Get the Class, from the cache if possible
		Class<?> cls = clsCache.get(classname);
		if (cls == null) {
			try {
				cls = Class.forName(classname);
				clsCache.put(classname, cls);
			} catch (ClassNotFoundException e) {
				Log.w(LCAT, "Unable to find resource: " + e.getMessage());
				throw new TiRHelper.ResourceNotFoundException(path);
			}
		}
		
		// Load the field
		try {
			i = cls.getDeclaredField(fieldname).getInt(null);
		} catch (Exception e) {
			Log.w(LCAT, "Unable to find resource: " + e.getMessage());
			throw new TiRHelper.ResourceNotFoundException(path);
		}
		
		valCache.put(tp, i);
		return i;
	}
	
	public static int getResource(String path) throws ResourceNotFoundException {
		try {
			return getResource(RType.APPLICATION, path);
		}
		catch (ResourceNotFoundException e) {
			return getResource(RType.ANDROID, path);
		}
	}
	
	public static int getString(String path) throws ResourceNotFoundException {
		return getResource("string." + path);
	}

	public static int getDrawable(String path) throws ResourceNotFoundException {
		return getResource("drawable." + path);
	}
}
