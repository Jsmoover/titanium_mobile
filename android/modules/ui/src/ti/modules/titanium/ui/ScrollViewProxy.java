/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2011 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.modules.titanium.ui;

import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.AsyncResult;
import org.appcelerator.titanium.view.TiUIView;

import ti.modules.titanium.ui.widget.TiUIScrollView;
import android.app.Activity;
import android.os.Handler;
import android.os.Message;

@Kroll.proxy(creatableInModule=UIModule.class)
@Kroll.dynamicApis(properties = {
	"contentHeight", "contentWidth",
	"showHorizontalScrollIndicator",
	"showVerticalScrollIndicator",
	"scrollType"
})
public class ScrollViewProxy extends TiViewProxy
	implements Handler.Callback
{
	private static final int MSG_FIRST_ID = KrollProxy.MSG_LAST_ID + 1;

	private static final int MSG_SCROLL_TO = MSG_FIRST_ID + 100;
	private static final int MSG_SCROLL_TO_BOTTOM = MSG_FIRST_ID + 101;
	protected static final int MSG_LAST_ID = MSG_FIRST_ID + 999;

	@Override
	public TiUIView createView(Activity activity) {
		return new TiUIScrollView(this);
	}

	public TiUIScrollView getScrollView() {
		return (TiUIScrollView) getOrCreateView();
	}

	@Kroll.method
	public void scrollTo(int x, int y) {
		if (!TiApplication.isUIThread()) {
			sendBlockingUiMessage(MSG_SCROLL_TO, getActivity(), x, y);
		} else {
			handleScrollTo(x,y);
		}
	}
	
	@Kroll.method
	public void scrollToBottom() {
		if (!TiApplication.isUIThread()) {
			sendBlockingUiMessage(MSG_SCROLL_TO_BOTTOM, getActivity());
		} else {
			handleScrollToBottom();
		}
	}

	@Override
	public boolean handleMessage(Message msg) {
		if (msg.what == MSG_SCROLL_TO) {
			handleScrollTo(msg.arg1, msg.arg2);
			AsyncResult result = (AsyncResult) msg.obj;
			result.setResult(null); // signal scrolled
			return true;
		} else if (msg.what == MSG_SCROLL_TO_BOTTOM) {
			handleScrollToBottom();
			AsyncResult result = (AsyncResult) msg.obj;
			result.setResult(null); // signal scrolled
			return true;
		}
		return super.handleMessage(msg);
	}

	public void handleScrollTo(int x, int y) {
		getScrollView().scrollTo(x, y);
	}
	
	public void handleScrollToBottom() {
		getScrollView().scrollToBottom();
	}
}
