/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.modules.titanium.ui.widget;

import java.util.HashMap;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.util.TiUIHelper;
import org.appcelerator.titanium.view.TiUIView;
import org.appcelerator.titanium.view.TiCompositeLayout;

import android.content.Context;
import android.graphics.Rect;
import android.text.Editable;
import android.text.InputType;
import android.text.TextUtils.TruncateAt;
import android.text.TextWatcher;
import android.text.method.DialerKeyListener;
import android.text.method.DigitsKeyListener;
import android.text.method.NumberKeyListener;
import android.text.method.PasswordTransformationMethod;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnFocusChangeListener;
import android.view.inputmethod.EditorInfo;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;
import android.content.res.ColorStateList;

public class TiUIText extends TiUIView
	implements TextWatcher, OnEditorActionListener, OnFocusChangeListener
{
	private static final String TAG = "TiUIText";

	public static final int RETURNKEY_GO = 0;
	public static final int RETURNKEY_GOOGLE = 1;
	public static final int RETURNKEY_JOIN = 2;
	public static final int RETURNKEY_NEXT = 3;
	public static final int RETURNKEY_ROUTE = 4;
	public static final int RETURNKEY_SEARCH = 5;
	public static final int RETURNKEY_YAHOO = 6;
	public static final int RETURNKEY_DONE = 7;
	public static final int RETURNKEY_EMERGENCY_CALL = 8;
	public static final int RETURNKEY_DEFAULT = 9;
	public static final int RETURNKEY_SEND = 10;

	private static final int KEYBOARD_ASCII = 0;
	private static final int KEYBOARD_NUMBERS_PUNCTUATION = 1;
	private static final int KEYBOARD_URL = 2;
	private static final int KEYBOARD_NUMBER_PAD = 3;
	private static final int KEYBOARD_PHONE_PAD = 4;
	private static final int KEYBOARD_EMAIL_ADDRESS = 5;
	private static final int KEYBOARD_NAMEPHONE_PAD = 6;
	private static final int KEYBOARD_DEFAULT = 7;
	private static final int KEYBOARD_DECIMAL_PAD = 8;
	
	// UIModule also has these as values - there's a chance they won't stay in sync if somebody changes one without changing these
	private static final int TEXT_AUTOCAPITALIZATION_NONE = 0;
	private static final int TEXT_AUTOCAPITALIZATION_SENTENCES = 1;
	private static final int TEXT_AUTOCAPITALIZATION_WORDS = 2;
	private static final int TEXT_AUTOCAPITALIZATION_ALL = 3;

	private int defaultColor;
	private boolean field;
	private int maxLength = -1;
	private boolean isTruncatingText = false;
	private boolean disableChangeEvent = false;

	protected FocusFixedEditText tv;
	protected TiEditText realtv;

	public static void requestSoftInputChange(KrollProxy proxy, View view) 
	{
		int focusState = TiUIView.SOFT_KEYBOARD_DEFAULT_ON_FOCUS;
		
		if (proxy.hasProperty(TiC.PROPERTY_SOFT_KEYBOARD_ON_FOCUS)) {
			focusState = TiConvert.toInt(proxy.getProperty(TiC.PROPERTY_SOFT_KEYBOARD_ON_FOCUS));
		}

		if (focusState > TiUIView.SOFT_KEYBOARD_DEFAULT_ON_FOCUS) {
			if (focusState == TiUIView.SOFT_KEYBOARD_SHOW_ON_FOCUS) {
				TiUIHelper.showSoftKeyboard(view, true);
			} else if (focusState == TiUIView.SOFT_KEYBOARD_HIDE_ON_FOCUS) {
				TiUIHelper.showSoftKeyboard(view, false);
			} else {
				Log.w(TAG, "Unknown onFocus state: " + focusState);
			}
		}
		else {
			TiUIHelper.showSoftKeyboard(view, true);
		}
	}
	
	public class TiEditText extends EditText 
	{
		public TiEditText(Context context) 
		{
			super(context);
		}
		
		/** 
		 * Check whether the called view is a text editor, in which case it would make sense to 
		 * automatically display a soft input window for it.
		 */
		@Override
		public boolean onCheckIsTextEditor () {
			if (proxy.hasProperty(TiC.PROPERTY_SOFT_KEYBOARD_ON_FOCUS)
					&& TiConvert.toInt(proxy.getProperty(TiC.PROPERTY_SOFT_KEYBOARD_ON_FOCUS)) == TiUIView.SOFT_KEYBOARD_HIDE_ON_FOCUS) {
					return false;
			}
			if (proxy.hasProperty(TiC.PROPERTY_EDITABLE)
					&& !(TiConvert.toBoolean(proxy.getProperty(TiC.PROPERTY_EDITABLE)))) {
				return false;
			}
			return true;
		}

		@Override
		protected void onLayout(boolean changed, int left, int top, int right, int bottom)
		{
			super.onLayout(changed, left, top, right, bottom);
			TiUIHelper.firePostLayoutEvent(TiUIText.this);
		}

		@Override
		public boolean dispatchTouchEvent(MotionEvent event) {
			if (touchPassThrough == true)
				return false;
			return super.dispatchTouchEvent(event);
		}
	}

	public class FocusFixedEditText extends LinearLayout {
		TiEditText editText;
		LinearLayout layout;
		protected TiCompositeLayout leftPane;
		protected TiCompositeLayout rightPane;
		private TiViewProxy leftView;
		private TiViewProxy rightView;

		private LinearLayout.LayoutParams createBaseParams()
		{
			return new LinearLayout.LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.FILL_PARENT);
		}

		private void init(Context context) {
			layout = this;
			this.setFocusableInTouchMode(true);
			this.setFocusable(true);
			this.setDescendantFocusability(ViewGroup.FOCUS_BEFORE_DESCENDANTS);
			this.requestFocus();
			this.setOrientation(LinearLayout.HORIZONTAL);

			LinearLayout.LayoutParams params;

			leftPane = new TiCompositeLayout(context);
			leftPane.setId(100);
			leftPane.setTag("leftPane");
			params = createBaseParams();
			params.gravity = Gravity.CENTER;
			this.addView(leftPane, params);

			editText = new TiEditText(context);
			editText.setId(200);
			params = new LinearLayout.LayoutParams(0, LayoutParams.FILL_PARENT, 1.0f);
			this.addView(editText, params);

			rightPane = new TiCompositeLayout(context);
			rightPane.setId(300);
			rightPane.setTag("rightPane");
			params = createBaseParams();
			params.gravity = Gravity.CENTER;
			layout.addView(rightPane, params);

		}

		public FocusFixedEditText(Context context) {
			super(context);
			init(context);
		}

		public void setLeftView(Object leftView) {
			Log.i(TAG, "setLeftView ");
			leftPane.removeAllViews();
			if (leftView == null){
				leftPane.setVisibility(View.GONE);
				this.leftView = null;
			} else if (leftView instanceof TiViewProxy) {
				this.leftView = (TiViewProxy)leftView;
				leftPane.addView((this.leftView.getOrCreateView()).getOuterView());
				leftPane.setVisibility(View.VISIBLE);
			} else if (leftView instanceof View) {
				leftPane.addView((View)leftView);
				leftPane.setVisibility(View.VISIBLE);
			} else {
				leftPane.setVisibility(View.GONE);
				Log.e(TAG, "Invalid type for rightView");
			}
		}

		public TiViewProxy getLeftView()
		{
			return leftView;
		}

		public TiViewProxy getRightView()
		{
			return rightView;
		}

		public void setRightView(Object rightView) {
			Log.i(TAG, "setRightView ");
			rightPane.removeAllViews();
			if (rightView == null){
				rightPane.setVisibility(View.GONE);
			} else if (rightView instanceof TiViewProxy) {
				this.rightView = (TiViewProxy)rightView;
				rightPane.addView((this.rightView.getOrCreateView()).getOuterView());
				rightPane.setVisibility(View.VISIBLE);
			} else if (rightView instanceof View) {
				rightPane.addView((View)rightView);
				rightPane.setVisibility(View.VISIBLE);
			} else {
				rightPane.setVisibility(View.GONE);
				Log.e(TAG, "Invalid type for rightView");
			}
		}

		public void hideLeftView()
		{
			leftPane.setVisibility(View.GONE);
		}

		public void showLeftView()
		{
			if (leftView != null){
				leftPane.setVisibility(View.VISIBLE);
			}
		}

		public void hideRightView()
		{
			rightPane.setVisibility(View.GONE);
		}

		public void showRightView()
		{
			if (rightView != null){
				rightPane.setVisibility(View.VISIBLE);
			}
		}

		public void onFocusChange(View v, boolean hasFocus)
		{
			Log.d(TAG, "onFocusChange "  + hasFocus + "  for FocusFixedEditText with text " + editText.getText(), Log.DEBUG_MODE);

		}

		@Override
		public boolean onCheckIsTextEditor () {
			return editText.onCheckIsTextEditor();
		}

		public TiEditText getRealEditText() {
			return editText;
		}
		
		public boolean hasFocus() {
			return editText.hasFocus();
		}

		public void focus() {
			if (this.getVisibility() == View.INVISIBLE) return;
			if (proxy.hasProperty(TiC.PROPERTY_EDITABLE) 
					&& !(TiConvert.toBoolean(proxy.getProperty(TiC.PROPERTY_EDITABLE)))) {
				editText.clearFocus();
				this.requestFocus();
				TiUIHelper.hideSoftKeyboard(editText);
			}
			else {
				editText.requestFocus();
				TiUIText.requestSoftInputChange(proxy, editText);
			}
		}

		public void blur() {
			if (editText.hasFocus()) {
				editText.clearFocus();
				this.requestFocus();
				TiUIHelper.hideSoftKeyboard(editText);
			}

		}

		public void setOnFocusChangeListener(OnFocusChangeListener l) {
			editText.setOnFocusChangeListener(l);
		}
	}

	public TiUIText(final TiViewProxy proxy, boolean field)
	{
		super(proxy);
		Log.d(TAG, "Creating a text field", Log.DEBUG_MODE);

		this.field = field;
		tv = new FocusFixedEditText(getProxy().getActivity());
		realtv = tv.getRealEditText();
		if (field) {
			realtv.setSingleLine();
			realtv.setMaxLines(1);
		}
		realtv.addTextChangedListener(this);
		realtv.setOnEditorActionListener(this);
		// realtv.setOnFocusChangeListener(this); // TODO refactor to TiUIView?
		realtv.setIncludeFontPadding(true); 
		if (field) {
			realtv.setGravity(Gravity.CENTER_VERTICAL | Gravity.LEFT);
		} else {
			realtv.setGravity(Gravity.TOP | Gravity.LEFT);
		}
		defaultColor = realtv.getCurrentTextColor();
		setNativeView(tv);
	}


	private void setTextColors(int color, int selectedColor, int disabledColor) {
		
		int[][] states = new int[][] {
			TiUIHelper.BACKGROUND_DISABLED_STATE, // disabled
			TiUIHelper.BACKGROUND_SELECTED_STATE, // pressed
			TiUIHelper.BACKGROUND_FOCUSED_STATE,  // pressed
			TiUIHelper.BACKGROUND_CHECKED_STATE,  // pressed
			new int [] {android.R.attr.state_pressed},  // pressed
			new int [] {android.R.attr.state_focused},  // pressed
			new int [] {}
		};

		ColorStateList colorStateList = new ColorStateList(
			states,
			new int[] {disabledColor, selectedColor, selectedColor, selectedColor, selectedColor, selectedColor, color}
		);

		realtv.setTextColor(colorStateList);
	}

	@Override
	public void processProperties(KrollDict d)
	{
		super.processProperties(d);

		if (d.containsKey(TiC.PROPERTY_ENABLED)) {
			realtv.setEnabled(d.optBoolean(TiC.PROPERTY_ENABLED, true));
		}
		
		if (d.containsKey(TiC.PROPERTY_MAX_LENGTH) && field) {
			maxLength = TiConvert.toInt(d.get(TiC.PROPERTY_MAX_LENGTH), -1);
		}
		
		// Disable change event temporarily as we are setting the default value
		disableChangeEvent = true;
		if (d.containsKey(TiC.PROPERTY_VALUE)) {
			realtv.setText(d.getString(TiC.PROPERTY_VALUE));
			int pos = realtv.getText().length();
			realtv.setSelection(pos);
		}
		disableChangeEvent = false;
		
		if (d.containsKey(TiC.PROPERTY_COLOR) || d.containsKey(TiC.PROPERTY_SELECTED_COLOR) || d.containsKey(TiC.PROPERTY_DISABLED_COLOR)) {
			int color = d.optColor(TiC.PROPERTY_COLOR, defaultColor);
			int selectedColor = d.optColor(TiC.PROPERTY_SELECTED_COLOR, color);
			int disabledColor = d.optColor(TiC.PROPERTY_DISABLED_COLOR, color);
			setTextColors(color, selectedColor, disabledColor);
		}
		
		if (d.containsKey(TiC.PROPERTY_HINT_TEXT)) {
			realtv.setHint(d.getString(TiC.PROPERTY_HINT_TEXT));
		}
		
		if (d.containsKey(TiC.PROPERTY_ELLIPSIZE)) {
			if (TiConvert.toBoolean(d, TiC.PROPERTY_ELLIPSIZE)) {
				realtv.setEllipsize(TruncateAt.END);
			} else {
				realtv.setEllipsize(null);
			}
		}
		
		if (d.containsKey(TiC.PROPERTY_FONT)) {
			TiUIHelper.styleText(realtv, d.getKrollDict(TiC.PROPERTY_FONT));
		}
		
		if (d.containsKey(TiC.PROPERTY_TEXT_ALIGN) || d.containsKey(TiC.PROPERTY_VERTICAL_ALIGN)) {
			String textAlign = null;
			String verticalAlign = null;
			if (d.containsKey(TiC.PROPERTY_TEXT_ALIGN)) {
				textAlign = d.getString(TiC.PROPERTY_TEXT_ALIGN);
			}
			if (d.containsKey(TiC.PROPERTY_VERTICAL_ALIGN)) {
				verticalAlign = d.getString(TiC.PROPERTY_VERTICAL_ALIGN);
			}
			handleTextAlign(textAlign, verticalAlign);
		}
		
		if (d.containsKey(TiC.PROPERTY_RETURN_KEY_TYPE)) {
			handleReturnKeyType(TiConvert.toInt(d.get(TiC.PROPERTY_RETURN_KEY_TYPE), RETURNKEY_DEFAULT));
		}
		
		if (d.containsKey(TiC.PROPERTY_KEYBOARD_TYPE) || d.containsKey(TiC.PROPERTY_AUTOCORRECT) || d.containsKey(TiC.PROPERTY_PASSWORD_MASK) || d.containsKey(TiC.PROPERTY_AUTOCAPITALIZATION) || d.containsKey(TiC.PROPERTY_EDITABLE)) {
			handleKeyboard(d);
		} else if (!field) {
			realtv.setInputType(InputType.TYPE_TEXT_FLAG_IME_MULTI_LINE);
		}
		
		if (d.containsKey(TiC.PROPERTY_AUTO_LINK)) {
			TiUIHelper.linkifyIfEnabled(realtv, d.get(TiC.PROPERTY_AUTO_LINK));
		}

		if (d.containsKey(TiC.PROPERTY_LEFT_BUTTON)) {
			tv.setLeftView(d.get(TiC.PROPERTY_LEFT_BUTTON));
		}

		if (d.containsKey(TiC.PROPERTY_RIGHT_BUTTON)) {
			tv.setRightView(d.get(TiC.PROPERTY_RIGHT_BUTTON));
		}
	}


	@Override
	public void propertyChanged(String key, Object oldValue, Object newValue, KrollProxy proxy)
	{
		if (Log.isDebugModeEnabled()) {
			Log.d(TAG, "Property: " + key + " old: " + oldValue + " new: " + newValue, Log.DEBUG_MODE);
		}
		if (key.equals(TiC.PROPERTY_ENABLED)) {
			realtv.setEnabled(TiConvert.toBoolean(newValue));
		} else if (key.equals(TiC.PROPERTY_VALUE)) {
			realtv.setText(TiConvert.toString(newValue));
			int pos = realtv.getText().length();
			realtv.setSelection(pos);
		} else if (key.equals(TiC.PROPERTY_MAX_LENGTH)) {
			maxLength = TiConvert.toInt(newValue);
			//truncate if current text exceeds max length
			Editable currentText = realtv.getText();
			if (maxLength >= 0 && currentText.length() > maxLength) {
				CharSequence truncateText = currentText.subSequence(0, maxLength);
				int cursor = realtv.getSelectionStart() - 1;
				if (cursor > maxLength) {
					cursor = maxLength;
				}
				realtv.setText(truncateText);
				realtv.setSelection(cursor);
			}
		} else if (key.equals(TiC.PROPERTY_COLOR) || key.equals(TiC.PROPERTY_SELECTED_COLOR) || key.equals(TiC.PROPERTY_DISABLED_COLOR)) {
			KrollDict properties = proxy.getProperties();
			int color = properties.optColor(TiC.PROPERTY_COLOR, defaultColor);
			int selectedColor = properties.optColor(TiC.PROPERTY_SELECTED_COLOR, color);
			int disabledColor = properties.optColor(TiC.PROPERTY_DISABLED_COLOR, color);
			setTextColors(color, selectedColor, disabledColor);
		} else if (key.equals(TiC.PROPERTY_HINT_TEXT)) {
			realtv.setHint((String) newValue);
		} else if (key.equals(TiC.PROPERTY_ELLIPSIZE)) {
			if (TiConvert.toBoolean(newValue)) {
				realtv.setEllipsize(TruncateAt.END);
			} else {
				realtv.setEllipsize(null);
			}
		} else if (key.equals(TiC.PROPERTY_TEXT_ALIGN) || key.equals(TiC.PROPERTY_VERTICAL_ALIGN)) {
			String textAlign = null;
			String verticalAlign = null;
			if (key.equals(TiC.PROPERTY_TEXT_ALIGN)) {
				textAlign = TiConvert.toString(newValue);
			} else if (proxy.hasProperty(TiC.PROPERTY_TEXT_ALIGN)){
				textAlign = TiConvert.toString(proxy.getProperty(TiC.PROPERTY_TEXT_ALIGN));
			}
			if (key.equals(TiC.PROPERTY_VERTICAL_ALIGN)) {
				verticalAlign = TiConvert.toString(newValue);
			} else if (proxy.hasProperty(TiC.PROPERTY_VERTICAL_ALIGN)){
				verticalAlign = TiConvert.toString(proxy.getProperty(TiC.PROPERTY_VERTICAL_ALIGN));
			}
			handleTextAlign(textAlign, verticalAlign);
		} else if (key.equals(TiC.PROPERTY_KEYBOARD_TYPE) || (key.equals(TiC.PROPERTY_AUTOCORRECT) || key.equals(TiC.PROPERTY_AUTOCAPITALIZATION) || key.equals(TiC.PROPERTY_PASSWORD_MASK) || key.equals(TiC.PROPERTY_EDITABLE))) {
			KrollDict d = proxy.getProperties();
			handleKeyboard(d);
		} else if (key.equals(TiC.PROPERTY_RETURN_KEY_TYPE)) {
			handleReturnKeyType(TiConvert.toInt(newValue));
		} else if (key.equals(TiC.PROPERTY_FONT)) {
			TiUIHelper.styleText(realtv, (HashMap) newValue);
		} else if (key.equals(TiC.PROPERTY_AUTO_LINK)){
			TiUIHelper.linkifyIfEnabled(realtv, newValue);
		} else if (key.equals(TiC.PROPERTY_LEFT_BUTTON)){
			tv.setLeftView(newValue);
		} else if (key.equals(TiC.PROPERTY_RIGHT_BUTTON)){
			tv.setRightView(newValue);
		} else {
			super.propertyChanged(key, oldValue, newValue, proxy);
		}
	}

	@Override
	public void afterTextChanged(Editable editable)
	{
		if (maxLength >= 0 && editable.length() > maxLength) {
			// The input characters are more than maxLength. We need to truncate the text and reset text.
			isTruncatingText = true;
			String newText = editable.subSequence(0, maxLength).toString();
			int cursor = realtv.getSelectionStart();
			if (cursor > maxLength) {
				cursor = maxLength;
			}
			realtv.setText(newText); // This method will invoke onTextChanged() and afterTextChanged().
			realtv.setSelection(cursor);
		} else {
			isTruncatingText = false;
		}
	}

	@Override
	public void beforeTextChanged(CharSequence s, int start, int before, int count)
	{

	}

	@Override
	public void onTextChanged(CharSequence s, int start, int before, int count)
	{
		/**
		 * There is an Android bug regarding setting filter on EditText that impacts auto completion.
		 * Therefore we can't use filters to implement "maxLength" property. Instead we manipulate
		 * the text to achieve perfect parity with other platforms.
		 * Android bug url for reference: http://code.google.com/p/android/issues/detail?id=35757
		 */
		if (maxLength >= 0 && s.length() > maxLength) {
			// Can only set truncated text in afterTextChanged. Otherwise, it will crash.
			return;
		}
		String newText = realtv.getText().toString();
		if (!disableChangeEvent
			&& (!isTruncatingText || (isTruncatingText && proxy.shouldFireChange(proxy.getProperty(TiC.PROPERTY_VALUE), newText)))) {
			KrollDict data = new KrollDict();
			data.put(TiC.PROPERTY_VALUE, newText);
			proxy.setProperty(TiC.PROPERTY_VALUE, newText);
			fireEvent(TiC.EVENT_CHANGE, data);
		}
	}

	@Override
	public void applyCustomBackground()
	{
		super.applyCustomBackground();
		realtv.setBackgroundDrawable(null);
		realtv.postInvalidate();
	}

	@Override
	public void setVisibility(int visibility)
	{
		if ((visibility == View.INVISIBLE))
			this.blur();
		super.setVisibility(visibility);
	}

	@Override
	public void blur()
	{
		if (tv != null) {
			tv.blur();
		}
	}
	
	@Override
	public void focus()
	{
		tv.focus();
	}

	@Override
	public void onFocusChange(View v, boolean hasFocus)
	{
		tv.setDescendantFocusability(ViewGroup.FOCUS_BEFORE_DESCENDANTS);
		if (v == realtv)
			Log.d(TAG, "onFocusChange "  + hasFocus + "  for FocusFixedEditText with text " + realtv.getText(), Log.DEBUG_MODE);
		else
			Log.d(TAG, "onFocusChange "  + hasFocus + "  for FocusFixedEditText  layout with text " + realtv.getText(), Log.DEBUG_MODE);
		if (hasFocus) {
			Boolean clearOnEdit = (Boolean) proxy.getProperty(TiC.PROPERTY_CLEAR_ON_EDIT);
			if (clearOnEdit != null && clearOnEdit) {
				realtv.setText("");
			}
			Rect r = new Rect();
			nativeView.getFocusedRect(r);
			nativeView.requestRectangleOnScreen(r);

		}
		super.onFocusChange(v, hasFocus);
	}

	@Override
	protected KrollDict getFocusEventObject(boolean hasFocus)
	{
		KrollDict event = new KrollDict();
		event.put(TiC.PROPERTY_VALUE, realtv.getText().toString());
		return event;
	}

	@Override
	public boolean onEditorAction(TextView v, int actionId, KeyEvent keyEvent)
	{
		String value = realtv.getText().toString();
		KrollDict data = new KrollDict();
		data.put(TiC.PROPERTY_VALUE, value);

		proxy.setProperty(TiC.PROPERTY_VALUE, value);
		Log.d(TAG, "ActionID: " + actionId + " KeyEvent: " + (keyEvent != null ? keyEvent.getKeyCode() : null),
			Log.DEBUG_MODE);

		
		//This is to prevent 'return' event from being fired twice when return key is hit. In other words, when return key is clicked,
		//this callback is triggered twice (except for keys that are mapped to EditorInfo.IME_ACTION_NEXT or EditorInfo.IME_ACTION_DONE). The first check is to deal with those keys - filter out
		//one of the two callbacks, and the next checks deal with 'Next' and 'Done' callbacks, respectively.
		//Refer to TiUIText.handleReturnKeyType(int) for a list of return keys that are mapped to EditorInfo.IME_ACTION_NEXT and EditorInfo.IME_ACTION_DONE.
		if ((actionId == EditorInfo.IME_NULL && keyEvent != null) || 
				actionId == EditorInfo.IME_ACTION_NEXT || 
				actionId == EditorInfo.IME_ACTION_DONE ) {
			Log.d(TAG, "onEditorAction for textview with text " + v.getText(), Log.DEBUG_MODE);
			tv.setDescendantFocusability(ViewGroup.FOCUS_AFTER_DESCENDANTS);
			fireEvent("return", data);
		}

		Boolean enableReturnKey = (Boolean) proxy.getProperty(TiC.PROPERTY_ENABLE_RETURN_KEY);
		if (enableReturnKey != null && enableReturnKey && v.getText().length() == 0) {
			return true;
		}
		return false;
	}

	public void handleTextAlign(String textAlign, String verticalAlign)
	{
		if (verticalAlign == null) {
			verticalAlign = field ? "middle" : "top";
		}
		if (textAlign == null) {
			textAlign = "left";
		}
		TiUIHelper.setAlignment(realtv, textAlign, verticalAlign);
	}

	public void handleKeyboard(KrollDict d) 
	{
		int type = KEYBOARD_ASCII;
		boolean passwordMask = false;
		boolean editable = true;
		int autocorrect = InputType.TYPE_TEXT_FLAG_AUTO_CORRECT;
		int autoCapValue = 0;

		if (d.containsKey(TiC.PROPERTY_AUTOCORRECT) && !TiConvert.toBoolean(d, TiC.PROPERTY_AUTOCORRECT, true)) {
			autocorrect = InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
		}

		if (d.containsKey(TiC.PROPERTY_EDITABLE)) {
			editable = TiConvert.toBoolean(d, TiC.PROPERTY_EDITABLE, true);
		}

		if (d.containsKey(TiC.PROPERTY_AUTOCAPITALIZATION)) {

			switch (TiConvert.toInt(d.get(TiC.PROPERTY_AUTOCAPITALIZATION), TEXT_AUTOCAPITALIZATION_NONE)) {
				case TEXT_AUTOCAPITALIZATION_NONE:
					autoCapValue = 0;
					break;
				case TEXT_AUTOCAPITALIZATION_ALL:
					autoCapValue = InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS | 
						InputType.TYPE_TEXT_FLAG_CAP_SENTENCES |
						InputType.TYPE_TEXT_FLAG_CAP_WORDS
						;
					break;
				case TEXT_AUTOCAPITALIZATION_SENTENCES:
					autoCapValue = InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
					break;
				
				case TEXT_AUTOCAPITALIZATION_WORDS:
					autoCapValue = InputType.TYPE_TEXT_FLAG_CAP_WORDS;
					break;
				default:
					Log.w(TAG, "Unknown AutoCapitalization Value ["+d.getString(TiC.PROPERTY_AUTOCAPITALIZATION)+"]");
				break;
			}
		}

		if (d.containsKey(TiC.PROPERTY_PASSWORD_MASK)) {
			passwordMask = TiConvert.toBoolean(d, TiC.PROPERTY_PASSWORD_MASK, false);
		}

		if (d.containsKey(TiC.PROPERTY_KEYBOARD_TYPE)) {
			type = TiConvert.toInt(d.get(TiC.PROPERTY_KEYBOARD_TYPE), KEYBOARD_DEFAULT);
		}

		int typeModifiers = autocorrect | autoCapValue;
		int textTypeAndClass = typeModifiers;
		// For some reason you can't set both TYPE_CLASS_TEXT and TYPE_TEXT_FLAG_NO_SUGGESTIONS together.
		// Also, we need TYPE_CLASS_TEXT for passwords.
		if (autocorrect != InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS || passwordMask) {
			textTypeAndClass = textTypeAndClass | InputType.TYPE_CLASS_TEXT;
		}
		if (!field) {
			realtv.setSingleLine(false);
		}
		realtv.setCursorVisible(true);
		switch(type) {
			case KEYBOARD_DEFAULT:
			case KEYBOARD_ASCII:
				// Don't need a key listener, inputType handles that.
				break;
			case KEYBOARD_NUMBERS_PUNCTUATION:
				textTypeAndClass |= InputType.TYPE_CLASS_NUMBER;
				realtv.setKeyListener(new NumberKeyListener()
				{
					@Override
					public int getInputType() {
						return InputType.TYPE_CLASS_NUMBER;
					}

					@Override
					protected char[] getAcceptedChars() {
						return new char[] {
							'0', '1', '2','3','4','5','6','7','8','9',
							'.','-','+','_','*','-','!','@', '#', '$',
							'%', '^', '&', '*', '(', ')', '=',
							'{', '}', '[', ']', '|', '\\', '<', '>',
							',', '?', '/', ':', ';', '\'', '"', '~'
						};
					}
				});
				break;
			case KEYBOARD_URL:
				Log.d(TAG, "Setting keyboard type URL-3", Log.DEBUG_MODE);
				realtv.setImeOptions(EditorInfo.IME_ACTION_GO);
				textTypeAndClass |= InputType.TYPE_TEXT_VARIATION_URI;
				break;
			case KEYBOARD_DECIMAL_PAD:
				textTypeAndClass |= (InputType.TYPE_NUMBER_FLAG_DECIMAL | InputType.TYPE_NUMBER_FLAG_SIGNED);
			case KEYBOARD_NUMBER_PAD:
				realtv.setKeyListener(DigitsKeyListener.getInstance(true,true));
				textTypeAndClass |= InputType.TYPE_CLASS_NUMBER;
				break;
			case KEYBOARD_PHONE_PAD:
				realtv.setKeyListener(DialerKeyListener.getInstance());
				textTypeAndClass |= InputType.TYPE_CLASS_PHONE;
				break;
			case KEYBOARD_EMAIL_ADDRESS:
				textTypeAndClass |= InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS;
				break;
		}
		if (passwordMask) {
			textTypeAndClass |= InputType.TYPE_TEXT_VARIATION_PASSWORD;
			// Sometimes password transformation does not work properly when the input type is set after the transformation method.
			// This issue has been filed at http://code.google.com/p/android/issues/detail?id=7092
			realtv.setInputType(textTypeAndClass);
			realtv.setTransformationMethod(PasswordTransformationMethod.getInstance());

			//turn off text UI in landscape mode b/c Android numeric passwords are not masked correctly in landscape mode.
			if (type == KEYBOARD_NUMBERS_PUNCTUATION || type == KEYBOARD_DECIMAL_PAD || type == KEYBOARD_NUMBER_PAD) {
				realtv.setImeOptions(EditorInfo.IME_FLAG_NO_EXTRACT_UI);
			}

		} else {
			realtv.setInputType(textTypeAndClass);
			if (realtv.getTransformationMethod() instanceof PasswordTransformationMethod) {
				realtv.setTransformationMethod(null);
			}
		}
		if (!editable) {
			realtv.setKeyListener(null);
			realtv.setCursorVisible(false);
		}

	}

	public void setSelection(int start, int end) 
	{
		int textLength = realtv.length();
		if (start < 0 || start > textLength || end < 0 || end > textLength) {
			Log.w(TAG, "Invalid range for text selection. Ignoring.");
			return;
		}
		realtv.setSelection(start, end);
	}

	public void handleReturnKeyType(int type)
	{
		if (!field) {
			realtv.setInputType(InputType.TYPE_TEXT_FLAG_IME_MULTI_LINE);
		}
		switch(type) {
			case RETURNKEY_GO:
				realtv.setImeOptions(EditorInfo.IME_ACTION_GO);
				break;
			case RETURNKEY_GOOGLE:
				realtv.setImeOptions(EditorInfo.IME_ACTION_GO);
				break;
			case RETURNKEY_JOIN:
				realtv.setImeOptions(EditorInfo.IME_ACTION_DONE);
				break;
			case RETURNKEY_NEXT:
				realtv.setImeOptions(EditorInfo.IME_ACTION_NEXT);
				break;
			case RETURNKEY_ROUTE:
				realtv.setImeOptions(EditorInfo.IME_ACTION_DONE);
				break;
			case RETURNKEY_SEARCH:
				realtv.setImeOptions(EditorInfo.IME_ACTION_SEARCH);
				break;
			case RETURNKEY_YAHOO:
				realtv.setImeOptions(EditorInfo.IME_ACTION_GO);
				break;
			case RETURNKEY_DONE:
				realtv.setImeOptions(EditorInfo.IME_ACTION_DONE);
				break;
			case RETURNKEY_EMERGENCY_CALL:
				realtv.setImeOptions(EditorInfo.IME_ACTION_GO);
				break;
			case RETURNKEY_DEFAULT:
				realtv.setImeOptions(EditorInfo.IME_ACTION_UNSPECIFIED);
				break;
			case RETURNKEY_SEND:
				realtv.setImeOptions(EditorInfo.IME_ACTION_SEND);
				break;
		}
	}
}
