/**
 * This file was auto-generated by the Titanium Module SDK helper for Android
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2013 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 */
package ti.modules.titanium.shape;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.util.TiUIHelper;
import org.appcelerator.titanium.view.TiCompositeLayout;
import org.appcelerator.titanium.view.TiUIView;

import ti.modules.titanium.shape.ShapeProxy.PRoundRect;

import android.app.Activity;
import android.app.NativeActivity;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Rect;
import android.graphics.drawable.shapes.Shape;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.MeasureSpec;
import android.widget.LinearLayout;

// This proxy can be created by calling Android.createExample({message: "hello world"})
@SuppressWarnings({ "unused", "unchecked", "rawtypes" })
@Kroll.proxy(name = "View", creatableInModule = ShapeModule.class, propertyAccessors = {})
public class ShapeViewProxy extends TiViewProxy {
	// Standard Debugging variables
	private static final String TAG = "ShapeViewProxy";

	private final ArrayList<ShapeProxy> mShapes;
	protected HashMap<String, ShapeProxy> mShapeBindings;
	private static final List<String> supportedEvents = Arrays.asList(
			TiC.EVENT_CLICK, TiC.EVENT_DOUBLE_CLICK, TiC.EVENT_DOUBLE_TAP,
			TiC.EVENT_SINGLE_TAP, TiC.EVENT_LONGPRESS, TiC.EVENT_TOUCH_CANCEL, TiC.EVENT_TOUCH_END,
			TiC.EVENT_TOUCH_MOVE, TiC.EVENT_TOUCH_START);

	protected class ShapeView extends TiCompositeLayout {

		public ShapeView(Context context) {
			super(context);
			setWillNotDraw(false); // or we wont draw if we dont have a
									// background
		}

		@Override
		protected void onDraw(Canvas canvas) {
			super.onDraw(canvas);
			for (int i = 0; i < mShapes.size(); i++) {
				ShapeProxy shapeProxy = mShapes.get(i);
				shapeProxy.drawOnCanvas(canvas);
			}
		}
	}

	protected class TiShapeView extends TiUIView {
		protected ShapeView nativeView;
		private Rect nativeViewBounds;

		protected void onLayoutChanged(int left, int top, int right, int bottom) {
			nativeViewBounds.set(0, 0, right - left, bottom - top);
			for (int i = 0; i < mShapes.size(); i++) {
				ShapeProxy shapeProxy = mShapes.get(i);
				shapeProxy.onLayoutChanged(nativeView.getContext(),
						nativeViewBounds);
			}
			// nativeView.requestLayout();
		}

		public void update() {
			for (int i = 0; i < mShapes.size(); i++) {
				ShapeProxy shapeProxy = mShapes.get(i);
				shapeProxy.onLayoutChanged(nativeView.getContext(),
						nativeViewBounds);
			}
		}

		protected void createNativeView(Activity activity) {
			nativeView = new ShapeView(activity) {
				@Override
				protected void onLayout(boolean changed, int left, int top,
						int right, int bottom) {
					super.onLayout(changed, left, top, right, bottom);
					if (changed) {
						onLayoutChanged(left, top, right, bottom);
					}
				}
			};
			setNativeView(nativeView);
			disableHWAcceleration(nativeView);
		}

		public TiShapeView(final TiViewProxy proxy, Activity activity) {
			super(proxy);
			hardwareAccSupported = false;
			nativeViewBounds = new Rect();
			createNativeView(activity);
		}

		@Override
		public void processProperties(KrollDict d) {

			super.processProperties(d);
			for (Entry<String, ShapeProxy> entry : mShapeBindings.entrySet()) {
			    String key = entry.getKey();
			    if (d.containsKey(key)) {
			    	KrollDict dict = d.getKrollDict(key);
			    	if (dict != null) {
				    	entry.getValue().processProperties(dict);
			    	}
			    }
			}
			redrawNativeView();
		}
		
		@Override
		public void propertyChanged(String key, Object oldValue, Object newValue, KrollProxy proxy) {
			if (mShapeBindings.containsKey(key)) {
				mShapeBindings.get(key).processProperties((KrollDict) newValue);
			}
			else super.propertyChanged(key, oldValue, newValue, proxy);
		}

		@Override
		public void release() {
			super.release();
			nativeView = null;
		}

		public void redrawNativeView() {
			super.redrawNativeView();
		}
	}

	// Constructor
	public ShapeViewProxy() {
		super();
		mShapes = new ArrayList<ShapeProxy>();
		mShapeBindings = new HashMap<String, ShapeProxy>();
	}

	@Override
	public boolean fireEvent(String eventName, Object data, boolean bubbles) {
		if (supportedEvents.contains(eventName) && mShapes.size() > 0) {
			int x = -1;
			int y = -1;
			if (data instanceof HashMap) {
				x = TiConvert.toInt((HashMap)data, TiC.PROPERTY_X);
				y = TiConvert.toInt((HashMap)data, TiC.PROPERTY_Y);
			}
			boolean handledByChildren = false;
			boolean result = false;
			for (int i = 0; i < mShapes.size(); i++) {
				ShapeProxy shapeProxy = mShapes.get(i);
				handledByChildren |= shapeProxy.handleTouchEvent(eventName, data, bubbles, x, y);
			}
			if (handledByChildren && bubbles) {
				return true;
			}
		}
		return super.fireEvent(eventName, data, bubbles);
	}

	@Override
	public TiUIView createView(Activity activity) {
		TiUIView view = new TiShapeView(this, activity);
		view.getLayoutParams().autoFillsHeight = true;
		view.getLayoutParams().autoFillsWidth = true;
		return view;
	}

	@Override
	public TiUIView getOrCreateView() {
		TiUIView view = super.getOrCreateView(true);
		return view;
	}
	

	private void processShapesAndBindings (Object[] array) {
		for (int i = 0; i < array.length; i++) {
		    HashMap dict = (HashMap) array[i];
		    if (dict != null) {
			    String bindId = TiConvert.toString(dict, TiC.PROPERTY_BIND_ID);
			    String type = TiConvert.toString(dict, TiC.PROPERTY_TYPE);
			    Class shapeClass = ShapeModule.ShapeClassFromString(type);
			    ShapeProxy proxy = (ShapeProxy) KrollProxy.createProxy(shapeClass, null, new Object[] { dict }, null);
				addShape(proxy);
				if (bindId != null) {
					mShapeBindings.put(bindId, proxy);
				}
		    }
		}
	}

	// Handle creation options
	@Override
	public void handleCreationDict(KrollDict options) {
		Log.d(TAG, "handleCreationDict ");
		if (options.containsKey(ShapeModule.PROPERTY_SHAPES)) {
			processShapesAndBindings((Object[]) options.get(ShapeModule.PROPERTY_SHAPES));
		}
		super.handleCreationDict(options);
		
	}

	@Kroll.method
	public void redraw() {
		if (view != null) {
			((TiShapeView) view).redrawNativeView();
		}
	}

	@Kroll.method
	public void update() {
		if (view != null) {
			((TiShapeView) view).update();
			((TiShapeView) view).redrawNativeView();
		}
	}

	private void addShape(ShapeProxy proxy) {
		if (!mShapes.contains(proxy)) {
			mShapes.add(proxy);
			proxy.setShapeViewProxy(this);
			redraw();
		}
	}

	private void removeShape(ShapeProxy proxy) {
		if (!mShapes.contains(proxy))
			return;
		mShapes.remove(proxy);
		proxy.setShapeViewProxy(null);
		redraw();
	}

	@Kroll.method
	public void add(Object arg) {
		Log.d(TAG, "add", Log.DEBUG_MODE);
		if ((arg instanceof TiViewProxy)) {
			super.add((TiViewProxy) arg);
			return;
		} else if (arg instanceof ShapeProxy) {
			addShape((ShapeProxy) arg);
		} else if (arg instanceof HashMap) {
			Class shapeClass = ShapeModule.ShapeClassFromString(TiConvert.toString(arg, TiC.PROPERTY_TYPE));
		    ShapeProxy proxy = (ShapeProxy) KrollProxy.createProxy(shapeClass, null, new Object[] { arg }, null);
			addShape(proxy);
		} else {
			Log.e(TAG, "add: must be a Shape");
		}
	}

	@Kroll.method
	public void remove(Object arg) {
		Log.d(TAG, "remove", Log.DEBUG_MODE);
		if ((arg instanceof TiViewProxy)) {
			super.remove((TiViewProxy) arg);
			return;
		}
		removeShape((ShapeProxy) arg);
	}
}