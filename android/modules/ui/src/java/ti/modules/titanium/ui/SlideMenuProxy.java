/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.modules.titanium.ui;

import java.lang.ref.WeakReference;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.kroll.common.AsyncResult;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.kroll.common.TiMessenger;
import org.appcelerator.titanium.TiActivity;
import org.appcelerator.titanium.TiActivityWindow;
import org.appcelerator.titanium.TiActivityWindows;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.TiBaseActivity;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.TiContext;
import org.appcelerator.titanium.TiDimension;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.proxy.TiWindowProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.util.TiUIHelper;

import com.slidingmenu.lib.SlidingMenu;

import ti.modules.titanium.ui.slidemenu.TiUISlideMenu;
import ti.modules.titanium.ui.widget.webview.TiUIWebView;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Message;
import android.view.Display;
import android.view.WindowManager;

@Kroll.proxy(creatableInModule=UIModule.class, propertyAccessors={
	TiC.PROPERTY_LEFT_VIEW,
	TiC.PROPERTY_CENTER_VIEW,
	TiC.PROPERTY_RIGHT_VIEW,
	TiC.PROPERTY_PANNING_MODE,
	TiC.PROPERTY_LEFT_VIEW_WIDTH,
	TiC.PROPERTY_RIGHT_VIEW_WIDTH,
	TiC.PROPERTY_FADING,
	TiC.PROPERTY_MENU_SCROLL_SCALE,
	TiC.PROPERTY_SHADOW_WIDTH
})
public class SlideMenuProxy extends TiWindowProxy implements TiActivityWindow
{
	private static final String TAG = "SlideMenuProxy";

	private static final int MSG_FIRST_ID = TiWindowProxy.MSG_LAST_ID + 1;

	private static final int MSG_TOGGLE_LEFT_VIEW = MSG_FIRST_ID + 100;
	private static final int MSG_TOGGLE_RIGHT_VIEW = MSG_FIRST_ID + 101;
	private static final int MSG_OPEN_LEFT_VIEW = MSG_FIRST_ID + 102;
	private static final int MSG_OPEN_RIGHT_VIEW = MSG_FIRST_ID + 103;
	private static final int MSG_CLOSE_LEFT_VIEW = MSG_FIRST_ID + 104;
	private static final int MSG_CLOSE_RIGHT_VIEW = MSG_FIRST_ID + 105;
	private static final int MSG_CLOSE_VIEWS = MSG_FIRST_ID + 106;

	protected static final int MSG_LAST_ID = MSG_FIRST_ID + 999;

	private WeakReference<Activity> slideMenuActivity;
	private WeakReference<SlidingMenu> slidingMenu;

	public SlideMenuProxy()
	{
		super();
	}

	public SlideMenuProxy(TiContext tiContext)
	{
		this();
	}

	@Override
	public boolean handleMessage(Message msg)
	{
		switch (msg.what) {
			case MSG_TOGGLE_LEFT_VIEW: {
				handleToggleLeftView((Boolean)msg.obj);
				return true;
			}
			case MSG_TOGGLE_RIGHT_VIEW: {
				handleToggleLeftView((Boolean)msg.obj);
				return true;
			}
			case MSG_OPEN_LEFT_VIEW: {
				handleOpenLeftView((Boolean)msg.obj);
				return true;
			}
			case MSG_OPEN_RIGHT_VIEW: {
				handleOpenRightView((Boolean)msg.obj);
				return true;
			}
			case MSG_CLOSE_LEFT_VIEW: {
				handleCloseLeftView((Boolean)msg.obj);
				return true;
			}
			case MSG_CLOSE_RIGHT_VIEW: {
				handleCloseRightView((Boolean)msg.obj);
				return true;
			}
			case MSG_CLOSE_VIEWS: {
				handleCloseViews((Boolean)msg.obj);
				return true;
			}
			default : {
				return super.handleMessage(msg);
			}
		}
	}

	@Override
	public void handleCreationDict(KrollDict options) {
		super.handleCreationDict(options);

		// Support setting orientation modes at creation.
		Object orientationModes = options.get(TiC.PROPERTY_ORIENTATION_MODES);
		if (orientationModes != null && orientationModes instanceof Object[]) {
			try {
				int[] modes = TiConvert.toIntArray((Object[]) orientationModes);
				setOrientationModes(modes);

			} catch (ClassCastException e) {
				Log.e(TAG, "Invalid orientationMode array. Must only contain orientation mode constants.");
			}
		}
	}


	@Override
	protected void handleOpen(KrollDict options)
	{
		Activity topActivity = TiApplication.getAppCurrentActivity();
		Intent intent = new Intent(topActivity, TiActivity.class);
		fillIntent(topActivity, intent);

		int windowId = TiActivityWindows.addWindow(this);
		intent.putExtra(TiC.INTENT_PROPERTY_USE_ACTIVITY_WINDOW, true);
		intent.putExtra(TiC.INTENT_PROPERTY_WINDOW_ID, windowId);

		topActivity.startActivity(intent);
	}

	@Override
	public void windowCreated(TiBaseActivity activity) {
		slideMenuActivity = new WeakReference<Activity>(activity);
		activity.setWindowProxy(this);
		setActivity(activity);
		view = new TiUISlideMenu(this, activity);
		slidingMenu = new WeakReference<SlidingMenu>(((TiUISlideMenu)view).getSlidingMenu());
		setModelListener(view);

		handlePostOpen();

		// Push the tab group onto the window stack. It needs to intercept
		// stack changes to properly dispatch tab focus and blur events
		// when windows open and close on top of it.
		activity.addWindowToStack(this);
	}

	@Override
	public void handlePostOpen()
	{
		super.handlePostOpen();

		opened = true;

		// First open before we load and focus our first tab.
		fireEvent(TiC.EVENT_OPEN, null);

		// Setup the new tab activity like setting orientation modes.
		onWindowActivityCreated();
	}

	@Override
	protected void handleClose(KrollDict options)
	{
		Log.d(TAG, "handleClose: " + options, Log.DEBUG_MODE);
		
		modelListener = null;
		releaseViews();
		view = null;

		opened = false;

		Activity activity = slideMenuActivity.get();
		if (activity != null && !activity.isFinishing()) {
			activity.finish();
		}
	}

	@Override
	public void closeFromActivity() {

		// Call super to fire the close event on the tab group.
		// This event must fire after each tab has been closed.
		super.closeFromActivity();
	}

	@Override
	public void onWindowFocusChange(boolean focused) {
	}

	private void fillIntent(Activity activity, Intent intent)
	{
		if (hasProperty(TiC.PROPERTY_FULLSCREEN)) {
			intent.putExtra(TiC.PROPERTY_FULLSCREEN, TiConvert.toBoolean(getProperty(TiC.PROPERTY_FULLSCREEN)));
		}
		if (hasProperty(TiC.PROPERTY_NAV_BAR_HIDDEN)) {
			intent.putExtra(TiC.PROPERTY_NAV_BAR_HIDDEN, TiConvert.toBoolean(getProperty(TiC.PROPERTY_NAV_BAR_HIDDEN)));
		}
		if (hasProperty(TiC.PROPERTY_WINDOW_SOFT_INPUT_MODE)) {
			intent.putExtra(TiC.PROPERTY_WINDOW_SOFT_INPUT_MODE, TiConvert.toInt(getProperty(TiC.PROPERTY_WINDOW_SOFT_INPUT_MODE)));
		}

		if (hasProperty(TiC.PROPERTY_EXIT_ON_CLOSE)) {
			intent.putExtra(TiC.INTENT_PROPERTY_FINISH_ROOT, TiConvert.toBoolean(getProperty(TiC.PROPERTY_EXIT_ON_CLOSE)));
		} else {
			intent.putExtra(TiC.INTENT_PROPERTY_FINISH_ROOT, activity.isTaskRoot());
		}
	}

	@Override
	public KrollDict handleToImage()
	{
		// TODO we need to expose properties again as a KrollDict?
		return TiUIHelper.viewToImage(new KrollDict(), getActivity().getWindow().getDecorView());
	}

	@Override
	public void releaseViews()
	{
		super.releaseViews();
//		if (hasProperty(TiC.PROPERTY_LEFT_VIEW))
//		{
//			((TiViewProxy)getProperty(TiC.PROPERTY_LEFT_VIEW)).releaseViews();
//		}
//		if (hasProperty(TiC.PROPERTY_RIGHT_VIEW))
//		{
//			((TiViewProxy)getProperty(TiC.PROPERTY_RIGHT_VIEW)).releaseViews();
//		}
//		if (hasProperty(TiC.PROPERTY_CENTER_VIEW))
//		{
//			((TiViewProxy)getProperty(TiC.PROPERTY_CENTER_VIEW)).releaseViews();
//		}
	}

	@Override
	protected Activity getWindowActivity()
	{
		return (slideMenuActivity != null) ? slideMenuActivity.get() : null;
	}

	@Kroll.method @Kroll.setProperty
	@Override
	public void setOrientationModes(int[] modes) {
		// Unlike Windows this setter is not defined in JavaScript.
		// We need to expose it here with an annotation.
		super.setOrientationModes(modes);
	}
	
	private void handleToggleLeftView(boolean animated)
	{
		SlidingMenu menu = slidingMenu.get();
		menu.toggle(animated);
	}
	
	private void handleToggleRightView(boolean animated)
	{
		SlidingMenu menu = slidingMenu.get();
		menu.toggleSecondary(animated);
	}
	
	private void handleOpenLeftView(boolean animated)
	{
		SlidingMenu menu = slidingMenu.get();
		menu.showMenu(animated);
	}
	
	private void handleOpenRightView(boolean animated)
	{
		SlidingMenu menu = slidingMenu.get();
		menu.showSecondaryMenu(animated);
	}
	
	private void handleCloseLeftView(boolean animated)
	{
		SlidingMenu menu = slidingMenu.get();
		if (menu.isMenuShowing())
			menu.showContent(animated);
	}
	
	private void handleCloseRightView(boolean animated)
	{
		SlidingMenu menu = slidingMenu.get();
		if (menu.isSecondaryMenuShowing())
			menu.showContent(animated);
	}
	
	private void handleCloseViews(boolean animated)
	{
		SlidingMenu menu = slidingMenu.get();
		if (menu.isMenuShowing() || menu.isSecondaryMenuShowing())
			menu.showContent(animated);
	}
	
	
	@Kroll.method
	public void toggleLeftView(@Kroll.argument(optional = true) Object obj)
	{
		Boolean animated = true;
		if (obj != null) {
			animated = TiConvert.toBoolean(obj);
		}
		
		if (TiApplication.isUIThread()) {
			handleToggleLeftView(animated);
			return;
		}
		Message message = getMainHandler().obtainMessage(MSG_TOGGLE_LEFT_VIEW, animated);
		message.sendToTarget();
	}
	
	@Kroll.method
	public void toggleRightView(@Kroll.argument(optional = true) Object obj)
	{
		Boolean animated = true;
		if (obj != null) {
			animated = TiConvert.toBoolean(obj);
		}
		
		if (TiApplication.isUIThread()) {
			handleToggleRightView(animated);
			return;
		}
		Message message = getMainHandler().obtainMessage(MSG_TOGGLE_RIGHT_VIEW, animated);
		message.sendToTarget();
	}
	
	@Kroll.method
	public void openLeftView(@Kroll.argument(optional = true) Object obj)
	{
		Boolean animated = true;
		if (obj != null) {
			animated = TiConvert.toBoolean(obj);
		}
		
		if (TiApplication.isUIThread()) {
			handleOpenLeftView(animated);
			return;
		}
		Message message = getMainHandler().obtainMessage(MSG_OPEN_LEFT_VIEW, animated);
		message.sendToTarget();
	}
	
	@Kroll.method
	public void openRightView(@Kroll.argument(optional = true) Object obj)
	{
		Boolean animated = true;
		if (obj != null) {
			animated = TiConvert.toBoolean(obj);
		}
		
		if (TiApplication.isUIThread()) {
			handleOpenRightView(animated);
			return;
		}
		Message message = getMainHandler().obtainMessage(MSG_OPEN_RIGHT_VIEW, animated);
		message.sendToTarget();
	}
	
	@Kroll.method
	public void closeLeftView(@Kroll.argument(optional = true) Object obj)
	{
		Boolean animated = true;
		if (obj != null) {
			animated = TiConvert.toBoolean(obj);
		}
		
		if (TiApplication.isUIThread()) {
			handleCloseLeftView(animated);
			return;
		}
		Message message = getMainHandler().obtainMessage(MSG_CLOSE_LEFT_VIEW, animated);
		message.sendToTarget();
	}
	
	@Kroll.method
	public void closeRightView(@Kroll.argument(optional = true) Object obj)
	{
		Boolean animated = true;
		if (obj != null) {
			animated = TiConvert.toBoolean(obj);
		}
		
		if (TiApplication.isUIThread()) {
			handleCloseRightView(animated);
			return;
		}
		Message message = getMainHandler().obtainMessage(MSG_CLOSE_RIGHT_VIEW, animated);
		message.sendToTarget();
	}
	
	@Kroll.method
	public void closeViews(@Kroll.argument(optional = true) Object obj)
	{
		Boolean animated = true;
		if (obj != null) {
			animated = TiConvert.toBoolean(obj);
		}
		
		if (TiApplication.isUIThread()) {
			handleCloseViews(animated);
			return;
		}
		Message message = getMainHandler().obtainMessage(MSG_CLOSE_VIEWS, animated);
		message.sendToTarget();
	}
	
	@Kroll.method
	public boolean isLeftViewOpened()
	{
		SlidingMenu menu = slidingMenu.get();
		return menu.isMenuShowing();
	}
	
	@Kroll.method
	public boolean isRightViewOpened()
	{
		SlidingMenu menu = slidingMenu.get();
		return menu.isSecondaryMenuShowing();
	}
	
	@Kroll.method
	public int getRealLeftViewWidth()
	{
		SlidingMenu menu = slidingMenu.get();
		return menu.getBehindWidth();
	}
	
	@Kroll.method
	public int getRealRightViewWidth()
	{
		SlidingMenu menu = slidingMenu.get();
		return menu.getBehindWidth();
	}
}
