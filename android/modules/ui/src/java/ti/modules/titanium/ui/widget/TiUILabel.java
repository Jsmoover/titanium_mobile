/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package ti.modules.titanium.ui.widget;

import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.common.Log;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.proxy.TiViewProxy;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.util.TiUIHelper;
import org.appcelerator.titanium.view.TiUIView;

import android.annotation.SuppressLint;
import android.content.Context;
import android.text.Html;
import android.text.InputType;
import android.text.TextUtils;
import android.text.util.Linkify;
import android.view.Gravity;
import android.view.View;
import android.widget.TextView;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Canvas;
import android.content.res.TypedArray;

// import android.annotation.SuppressLint;

import android.graphics.Typeface;
import android.text.Layout;
import android.text.Layout.Alignment;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.StaticLayout;
import android.text.TextPaint;
import android.text.TextUtils.TruncateAt;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.BackgroundColorSpan;
import android.text.style.BulletSpan;
import android.text.style.ForegroundColorSpan;
import android.text.style.ImageSpan;
// import android.text.style.LocaleSpan;
import android.text.style.MaskFilterSpan;
import android.text.style.QuoteSpan;
import android.text.style.RasterizerSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.ScaleXSpan;
import android.text.style.StrikethroughSpan;
import android.text.style.StyleSpan;
import android.text.style.SubscriptSpan;
import android.text.style.SuperscriptSpan;
import android.text.style.TextAppearanceSpan;
import android.text.style.TypefaceSpan;
import android.text.style.URLSpan;
import android.text.style.UnderlineSpan;

public class TiUILabel extends TiUIView
{
	private static final String TAG = "TiUILabel";

	private int shadowColor;
	private int shadowDx;
	private int shadowDy;
	private float shadowRadius;
	private Rect textPadding;
	
	public class CustomTypefaceSpan extends TypefaceSpan {
        private final Typeface newType;
        private final String fontFamily;

        public CustomTypefaceSpan(String family, Typeface type) {
            super(family);
        	this.fontFamily = family;
            newType = type;
        }
        
        public CustomTypefaceSpan(String family) {
            super(family);
            this.fontFamily = family;
            newType = null;
        }

        @Override
        public void updateDrawState(TextPaint ds) {
            applyCustomTypeFace(ds, newType);
        }

        @Override
        public void updateMeasureState(TextPaint paint) {
            applyCustomTypeFace(paint, newType);
        }

        private void applyCustomTypeFace(Paint paint, Typeface tf) {
    		TextView tv = (TextView) getNativeView();
    		tf = TiUIHelper.toTypeface(tv.getContext(), fontFamily);
            paint.setTypeface(tf);
        }
    }

	public class EllipsizingTextView extends TextView {

		private TruncateAt ellipsize = null;
		private TruncateAt multiLineEllipsize = null;
		private boolean isEllipsized;
		private boolean needsEllipsing;
		private boolean singleline = false;
		private boolean readyToEllipsize = false;
		private boolean programmaticChange;
		private CharSequence fullText;
		private int maxLines;
		private float lineSpacingMultiplier = 1.0f;
		private float lineAdditionalVerticalPadding = 0.0f;

		@Override
		protected void onLayout(boolean changed, int left, int top, int right, int bottom)
		{
			super.onLayout(changed, left, top, right, bottom);
			// this.SetReadyToEllipsize(true);
			if (changed || (isEllipsized && needsEllipsing)){
				updateEllipsize();

				if (proxy != null && proxy.hasListeners(TiC.EVENT_POST_LAYOUT)) {
					proxy.fireEvent(TiC.EVENT_POST_LAYOUT, null, false);
				}
			}
		}
		
		public EllipsizingTextView(Context context) {
			super(context);
		}

		public boolean isEllipsized() {
			return isEllipsized;
		}

		public void SetReadyToEllipsize(Boolean value){
			readyToEllipsize = value;
			// if (readyToEllipsize == true)
			// 	updateEllipsize();
		}

		@Override
		public void setMaxLines(int maxLines) {
			super.setMaxLines(maxLines);
			this.maxLines = maxLines;
			updateEllipsize();
		}
		
		public void updateEllipsize(){
			needsEllipsing = true;
			if (readyToEllipsize == true) ellipseText();
		}

		@SuppressLint("Override")
		public int getMaxLines() {
			return maxLines;
		}
		
		private void resetText(){
			if (isEllipsized){
				isEllipsized = false;
				programmaticChange = true;
				try {
					setText(fullText);
				} finally {
					programmaticChange = false;
				}
			}
		}

		@Override
		public void setLineSpacing(float add, float mult) {
			this.lineAdditionalVerticalPadding = add;
			this.lineSpacingMultiplier = mult;
			super.setLineSpacing(add, mult);
			updateEllipsize();
		}
		
		
		@Override
		public void setTypeface(Typeface tf, int style){
			super.setTypeface(tf, style);
			updateEllipsize();
		}
		
		@Override
		public void setTextSize(int unit, float size){
			super.setTextSize(unit, size);
			updateEllipsize();
		}

		@Override
		public void setText(CharSequence text, BufferType type) {
			if (!programmaticChange) {
				fullText = text;
			}
			super.setText(text, type);
		}

		@Override
		protected void onSizeChanged(int w, int h, int oldw, int oldh) {
			super.onSizeChanged(w, h, oldw, oldh);
			// updateEllipsize();
		}

		public void setPadding(int left, int top, int right, int bottom) {
			super.setPadding(left, top, right, bottom);
			// updateEllipsize();
		}
		
		
		@Override
		public void setSingleLine (boolean singleLine) {
			this.singleline = singleLine;
			if (this.maxLines == 1 && singleLine == false){
				//we were at maxLines==1 and singleLine==true
				//it s actually the same thing now so let s not change anything
			}
			else{
				super.setSingleLine(singleLine);
			}
			updateEllipsize();
		}

		@Override
		public void setEllipsize(TruncateAt where) {			
			super.setEllipsize(where);
			ellipsize = where;
			updateEllipsize();
		}

		public void setMultiLineEllipsize(TruncateAt where) {
			multiLineEllipsize = where;
			updateEllipsize();
		}
		
		private CharSequence ellipsisWithStyle(CharSequence text, TruncateAt where)
		{
			if (text instanceof SpannableStringBuilder){
				SpannableStringBuilder builder = new SpannableStringBuilder(text);
				SpannableStringBuilder htmlText = (SpannableStringBuilder) text;
				if (where == TruncateAt.END){
					Object[] spans = htmlText.getSpans(text.length() - 1, text.length(), Object.class);
					builder.append("...");
					for (int i = 0; i < spans.length; i++) {
						int flags = htmlText.getSpanFlags(spans[i]);
						int start = htmlText.getSpanStart(spans[i]);
						int end = htmlText.getSpanEnd(spans[i]);
						builder.setSpan(spans[i], start, end + 3, flags);
					}
				}
				else if (where == TruncateAt.START){
					Object[] spans = htmlText.getSpans(0, 1, Object.class);
					builder.insert(0, "...");
					for (int i = 0; i < spans.length; i++) {
						int flags = htmlText.getSpanFlags(spans[i]);
						int start = htmlText.getSpanStart(spans[i]);
						int end = htmlText.getSpanEnd(spans[i]);
						builder.setSpan(spans[i], start, end + 3, flags);
					}
				}
				else if (where == TruncateAt.MIDDLE){
					int middle = (int) Math.floor(htmlText.length() / 2);
					Object[] spans = htmlText.getSpans(middle-1, middle, Object.class);
					builder.insert(middle, "...");
					for (int i = 0; i < spans.length; i++) {
						int flags = htmlText.getSpanFlags(spans[i]);
						int start = htmlText.getSpanStart(spans[i]);
						int end = htmlText.getSpanEnd(spans[i]);
						builder.setSpan(spans[i], start, end + 3, flags);
					}
				}
				return builder;
			}
			else {
				if (where == TruncateAt.END){
					return TextUtils.concat(text, "...");
				}
				else if (where == TruncateAt.START){
					return TextUtils.concat( "..." , text);

				}
				else if (where == TruncateAt.MIDDLE){
					int middle = (int) Math.floor(text.length() / 2);
					return TextUtils.concat(text.subSequence(0, middle), "...", text.subSequence(middle, text.length()));
				}
			}
			return text;
		}
		
		private CharSequence getEllipsedTextForMaxLine(CharSequence text, int maxlines, TruncateAt where){
			int strimEnd = text.toString().trim().length();
			if (strimEnd != text.length()){
				text = text.subSequence(0, strimEnd);
			}
			TruncateAt realWhere = (maxlines == 1)?where:TruncateAt.END; 
			
			if (realWhere == TruncateAt.START){
				CharSequence newText = ellipsisWithStyle(text, realWhere);
				while (createWorkingLayout(newText).getLineCount() > maxlines) {
					int firstSpace = text.toString().indexOf(' ');
					if (firstSpace == -1) {
						firstSpace = 3;
					}
					text = (CharSequence) text.subSequence(firstSpace, text.length());
					newText = ellipsisWithStyle(text, realWhere);
				}
				return newText;
			}
			else if (realWhere == TruncateAt.MIDDLE){
						
				CharSequence newText = ellipsisWithStyle(text, realWhere);
				while (createWorkingLayout(newText).getLineCount() > maxlines) {
					if (text.length() < 3) return newText;
					int middle = text.length() / 2;
					if (text instanceof SpannableStringBuilder)
						((SpannableStringBuilder)text).delete(middle - 1, middle + 1);
					else
						text = TextUtils.concat(text.subSequence(0, middle -1), text.subSequence(middle + 1, text.length()));
					newText = ellipsisWithStyle(text, realWhere);
				}
				return newText;
			}
			else {
				CharSequence newText = ellipsisWithStyle(text, realWhere);
				while (createWorkingLayout(newText).getLineCount() > maxlines) {
					if (text.length() < 3) return newText;
					int lastSpace = text.toString().lastIndexOf(' ');
					if (lastSpace == -1) {
						lastSpace = text.length() - 4;
					}					
					newText = ellipsisWithStyle((CharSequence) text.subSequence(0, lastSpace), realWhere);
				}
				return newText;
			}
		}
		
		// @SuppressLint("NewApi")
		private Object duplicateSpan(Object span){
			if (span instanceof ForegroundColorSpan){
				return new ForegroundColorSpan(((ForegroundColorSpan)span).getForegroundColor());
			}
			if (span instanceof BackgroundColorSpan){
				return new BackgroundColorSpan(((BackgroundColorSpan)span).getBackgroundColor());
			}
			else if (span instanceof AbsoluteSizeSpan){
				return new AbsoluteSizeSpan(((AbsoluteSizeSpan)span).getSize(), ((AbsoluteSizeSpan)span).getDip());
			}
			else if (span instanceof RelativeSizeSpan){
				return new RelativeSizeSpan(((RelativeSizeSpan)span).getSizeChange());
			}
			else if (span instanceof TextAppearanceSpan){
				return new TextAppearanceSpan(((TextAppearanceSpan)span).getFamily(), ((TextAppearanceSpan)span).getTextStyle(), ((TextAppearanceSpan)span).getTextSize(), ((TextAppearanceSpan)span).getTextColor(), ((TextAppearanceSpan)span).getLinkTextColor());
			}
			else if (span instanceof URLSpan){
				return new URLSpan(((URLSpan)span).getURL());
			}
			else if (span instanceof UnderlineSpan){
				return new UnderlineSpan();
			}
			else if (span instanceof SuperscriptSpan){
				return new SuperscriptSpan();
			}
			else if (span instanceof SubscriptSpan){
				return new SubscriptSpan();
			}
			else if (span instanceof StrikethroughSpan){
				return new StrikethroughSpan();
			}
			else if (span instanceof BulletSpan){
				return new BulletSpan();
			}
//			else if (span instanceof ClickableSpan){
//				return new ClickableSpan();
//			}
			else if (span instanceof ScaleXSpan){
				return new ScaleXSpan(((ScaleXSpan)span).getScaleX());
			}
			else if (span instanceof StyleSpan){
				return new StyleSpan(((StyleSpan)span).getStyle());
			}
			else if (span instanceof TypefaceSpan){
				return new TypefaceSpan(((TypefaceSpan)span).getFamily());
			}
			else if (span instanceof CustomTypefaceSpan){
				return new CustomTypefaceSpan(((TypefaceSpan)span).getFamily());
			}
			else if (span instanceof ImageSpan){
				return new ImageSpan(((ImageSpan)span).getDrawable());
			}
			else if (span instanceof RasterizerSpan){
				return new RasterizerSpan(((RasterizerSpan)span).getRasterizer());
			}
			else if (span instanceof QuoteSpan){
				return new QuoteSpan(((QuoteSpan)span).getColor());
			}
			else if (span instanceof MaskFilterSpan){
				return new MaskFilterSpan(((MaskFilterSpan)span).getMaskFilter());
			}
			// else if (span instanceof LocaleSpan){
			// 	return new LocaleSpan(((LocaleSpan)span).getLocale());
			// }
			
			return null;
		}
		
		private void updateSpans()
		{
			
		}

		private void ellipseText() {
			if (fullText == null || needsEllipsing == false || (ellipsize == null && multiLineEllipsize == null)
				|| (getWidth() - getPaddingLeft() - getPaddingRight() < 0) || (this.maxLines == 1 || this.singleline == true)) return;
			
			boolean ellipsized = false;
			CharSequence workingText = fullText;

			if (fullText instanceof Spanned){
				SpannableStringBuilder htmlWorkingText = new SpannableStringBuilder(fullText);
				if (this.singleline == false && multiLineEllipsize != null) {
					SpannableStringBuilder newText = new SpannableStringBuilder();
					String str = htmlWorkingText.toString();
					String[] separated = str.split("\n");
					int start = 0;
					int newStart = 0;
					for (int i = 0; i < separated.length; i++) {
						String linestr = separated[i];
						int end = start +  linestr.length();
						if (linestr.length() > 0){
							SpannableStringBuilder lineSpanned = (SpannableStringBuilder) htmlWorkingText.subSequence(start, end);
							Object[] spans = lineSpanned.getSpans(0, lineSpanned.length(), Object.class);
							
							//this is a trick to get the Spans for the last line to be used in getEllipsedTextForMaxLine
							//we append,setSpans, getlastline with spans, ellipse, replace last line with last line ellipsized
							newText.append(lineSpanned.toString());
							for (int j = 0; j < spans.length; j++) {
								int start2 = htmlWorkingText.getSpanStart(spans[j]);
								int end2 = htmlWorkingText.getSpanEnd(spans[j]);
								int mystart = newStart + Math.max(0, start2 - start);
								int spanlengthonline = Math.min(end2, start + linestr.length()) - Math.max(start2, start);
								int myend = Math.min(mystart + spanlengthonline, newStart + lineSpanned.length());
								int flags = htmlWorkingText.getSpanFlags(spans[j]);
								if (myend > mystart){
									Object newSpan = duplicateSpan(spans[j]);
									newText.setSpan(newSpan, mystart, myend, flags);
								}
							}

							SpannableStringBuilder lastLine = (SpannableStringBuilder)newText.subSequence(newStart, newStart + lineSpanned.length());
							if (createWorkingLayout(lastLine).getLineCount() > 1) 
								lastLine = (SpannableStringBuilder)getEllipsedTextForMaxLine(lastLine, 1, multiLineEllipsize);

							newText.replace(newStart, newStart + lineSpanned.length(), lastLine);
						}
						if (i < (separated.length - 1)) newText.append('\n');
						start = end + 1;
						newStart = newText.length();
					}
					workingText = newText;
				}
				else {
					Layout layout = createWorkingLayout(workingText);
					int linesCount = getLinesCount(layout);
					if (layout.getLineCount() > linesCount && ellipsize != null) {
						// We have more lines of text than we are allowed to display.
						workingText = fullText.subSequence(0, layout.getLineEnd(linesCount - 1));
						workingText = getEllipsedTextForMaxLine(workingText, linesCount, ellipsize);
					}
				}
			}
			else {
				if (this.singleline == false && multiLineEllipsize != null) {
					String str = workingText.toString();
					String newText = new String();
					String[] separated = str.split("\n");
					for (int i = 0; i < separated.length; i++) {
						String linestr = separated[i];
						if (linestr.length() > 0){
							if (createWorkingLayout(linestr).getLineCount() > 1)
								newText += getEllipsedTextForMaxLine(linestr, 1, multiLineEllipsize);
							else
								newText += linestr;
						}
						if (i < (separated.length - 1)) 
							newText += '\n';
					}
					workingText = newText;
				}
				else {
					Layout layout = createWorkingLayout(workingText);
					int linesCount = getLinesCount(layout);
					if (layout.getLineCount() > linesCount && ellipsize != null) {
						// We have more lines of text than we are allowed to display.
						workingText = fullText.subSequence(0, layout.getLineEnd(linesCount - 1));
						workingText = getEllipsedTextForMaxLine(workingText, linesCount, ellipsize);
					}
				}
			}
			
			
			if (!workingText.equals(getText())) {
				programmaticChange = true;
				try {
					setText(workingText);
				} finally {
					programmaticChange = false;
					ellipsized = true;
				}
			}
			needsEllipsing = false;
			if (ellipsized != isEllipsized) {
				isEllipsized = ellipsized;
			}
		}

		/**
		* Get how many lines of text we are allowed to display.
		*/
		private int getLinesCount() {
			int fullyVisibleLinesCount = getFullyVisibleLinesCount();
			if (fullyVisibleLinesCount == -1) {
				return fullyVisibleLinesCount = 1;
			}
			return (maxLines == 0)?fullyVisibleLinesCount:Math.min(maxLines, fullyVisibleLinesCount);
		}

		private int getLinesCount(Layout layout) {
			int fullyVisibleLinesCount = getFullyVisibleLinesCount(layout);
			if (fullyVisibleLinesCount == -1) {
				return fullyVisibleLinesCount = 1;
			}
			return (maxLines == 0)?fullyVisibleLinesCount:Math.min(maxLines, fullyVisibleLinesCount);
		}

		/**
		* Get how many lines of text we can display so their full height is visible.
		*/
		private int getFullyVisibleLinesCount() {
			Layout layout = createWorkingLayout(fullText);
			return getFullyVisibleLinesCount(layout);
		}

		private int getFullyVisibleLinesCount(Layout layout) {
			int totalLines = layout.getLineCount();
			int index = totalLines - 1;
			int height = getHeight() - getPaddingTop() - getPaddingBottom();
			int lineHeight = layout.getLineBottom(index);
			while(lineHeight > height) {
				index -= 1;
				lineHeight = layout.getLineBottom(index);
			}
			return index + 1;
		}

		private Layout createWorkingLayout(CharSequence workingText) {
			return new StaticLayout(workingText, getPaint(),
				getWidth() - getPaddingLeft() - getPaddingRight(),
				Alignment.ALIGN_NORMAL, lineSpacingMultiplier,
				lineAdditionalVerticalPadding, false /* includepad */);
		}
	}

	public TiUILabel(final TiViewProxy proxy)
	{
		super(proxy);
		shadowColor = 0;
		shadowDx = 0;
		shadowDy = 0;
		textPadding = new Rect();
		Log.d(TAG, "Creating a text label", Log.DEBUG_MODE);
		TextView tv = new EllipsizingTextView(getProxy().getActivity());
		shadowColor = 0;
		shadowRadius = 1;
		shadowDx = 0;
		shadowDy = 0;
		textPadding = new Rect();
		tv.setGravity(Gravity.CENTER_VERTICAL | Gravity.LEFT);
		tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
		tv.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_FLAG_MULTI_LINE);
		tv.setKeyListener(null);
		tv.setFocusable(false);
		setNativeView(tv);
	}
	
	private Spanned fromHtml(String str)
	{
		SpannableStringBuilder htmlText = new SpannableStringBuilder(Html.fromHtml(str));
		Object[] spans = htmlText.getSpans(0, htmlText.length(), Object.class);
		for (int j = 0; j < spans.length; j++) {
			Object span = spans[j];
			if (span instanceof TypefaceSpan){
				String family = ((TypefaceSpan)span).getFamily();
				CustomTypefaceSpan newSpan = new CustomTypefaceSpan(family);
				int flags = htmlText.getSpanFlags(span);
				int start = htmlText.getSpanStart(span);
				int end = htmlText.getSpanEnd(span);
				htmlText.setSpan(newSpan, start, end, flags);
			}
		}
		
		return htmlText;
	}

	@Override
	public void processProperties(KrollDict d)
	{

		super.processProperties(d);
		TextView tv = (TextView) getNativeView();
		if (tv == null) return;

		// Clear any text style left over here if view is recycled
//		TiUIHelper.styleText(tv, null, null, null);
		
		// Only accept one, prefer text to title.
		if (d.containsKey(TiC.PROPERTY_HTML)) {
			tv.setText(fromHtml(TiConvert.toString(d, TiC.PROPERTY_HTML)), TextView.BufferType.SPANNABLE);
		} else if (d.containsKey(TiC.PROPERTY_TEXT)) {
			tv.setText(TiConvert.toString(d, TiC.PROPERTY_TEXT));
		} else if (d.containsKey(TiC.PROPERTY_TITLE)) { //TODO this may not need to be supported.
			tv.setText(Html.fromHtml(TiConvert.toString(d, TiC.PROPERTY_TITLE)), TextView.BufferType.SPANNABLE);
		}

		if (d.containsKey(TiC.PROPERTY_COLOR)) {
			tv.setTextColor(TiConvert.toColor(d, TiC.PROPERTY_COLOR));
		}
		if (d.containsKey(TiC.PROPERTY_HIGHLIGHTED_COLOR)) {
			tv.setHighlightColor(TiConvert.toColor(d, TiC.PROPERTY_HIGHLIGHTED_COLOR));
		}
		if (d.containsKey(TiC.PROPERTY_FONT)) {
			TiUIHelper.styleText(tv, d.getKrollDict(TiC.PROPERTY_FONT));
		}
		if (d.containsKey(TiC.PROPERTY_TEXT_ALIGN) || d.containsKey(TiC.PROPERTY_VERTICAL_ALIGN)) {
			String textAlign = d.optString(TiC.PROPERTY_TEXT_ALIGN, "left");
			String verticalAlign = d.optString(TiC.PROPERTY_VERTICAL_ALIGN, "middle");
			TiUIHelper.setAlignment(tv, textAlign, verticalAlign);
		}
		if (d.containsKey(TiC.PROPERTY_ELLIPSIZE)) {
			Object value = d.get(TiC.PROPERTY_ELLIPSIZE);
			if (value instanceof Boolean) {
				tv.setEllipsize(((Boolean)value)?TruncateAt.END:null);
			}
			else {
				String str = TiConvert.toString(value);
				if (str != null && !str.equals("none")) //none represents TEXT_ELLIPSIS_NONE
					tv.setEllipsize(TruncateAt.valueOf(str));
				else
					tv.setEllipsize(null);
			}
		}
		if (d.containsKey(TiC.PROPERTY_MULTILINE_ELLIPSIZE)) {
			Object value = d.get(TiC.PROPERTY_MULTILINE_ELLIPSIZE);
			if (value instanceof Boolean) {
				((EllipsizingTextView)tv).setMultiLineEllipsize(((Boolean)value)?TruncateAt.END:null);
			}
			else {
				String str = TiConvert.toString(value);
				if (str != null && !str.equals("none")) //none represents TEXT_ELLIPSIS_NONE
					((EllipsizingTextView)tv).setMultiLineEllipsize(TruncateAt.valueOf(str));
				else
					((EllipsizingTextView)tv).setMultiLineEllipsize(null);
			}
		}
		if (d.containsKey(TiC.PROPERTY_WORD_WRAP)) {
			tv.setSingleLine(!TiConvert.toBoolean(d, TiC.PROPERTY_WORD_WRAP));
		}
		if (d.containsKey(TiC.PROPERTY_MAX_LINES)) {
			tv.setMaxLines(TiConvert.toInt(d, TiC.PROPERTY_MAX_LINES));
		}
		if (d.containsKey(TiC.PROPERTY_TEXT_PADDING_LEFT)) {
			textPadding.left = TiConvert.toInt(d, TiC.PROPERTY_TEXT_PADDING_LEFT);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
		}
		if (d.containsKey(TiC.PROPERTY_TEXT_PADDING_RIGHT)) {
			textPadding.right = TiConvert.toInt(d, TiC.PROPERTY_TEXT_PADDING_RIGHT);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
		}
		if (d.containsKey(TiC.PROPERTY_TEXT_PADDING_TOP)) {
			textPadding.top = TiConvert.toInt(d, TiC.PROPERTY_TEXT_PADDING_TOP);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
		}
		if (d.containsKey(TiC.PROPERTY_TEXT_PADDING_BOTTOM)) {
			textPadding.bottom = TiConvert.toInt(d, TiC.PROPERTY_TEXT_PADDING_BOTTOM);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
		}
		if (d.containsKey(TiC.PROPERTY_SHADOW_COLOR)) {
			shadowColor = TiConvert.toColor(d, TiC.PROPERTY_SHADOW_COLOR);
			tv.setShadowLayer(shadowRadius, shadowDx, shadowDy, shadowColor);
		}
		if (d.containsKey(TiC.PROPERTY_SHADOW_RADIUS)) {
			shadowRadius = TiConvert.toFloat(d, TiC.PROPERTY_SHADOW_RADIUS);
			tv.setShadowLayer(shadowRadius, shadowDx, shadowDy, shadowColor);
		}
		if (d.containsKey(TiC.PROPERTY_SHADOW_OFFSET)) {
			KrollDict value = d.getKrollDict(TiC.PROPERTY_SHADOW_OFFSET);
			shadowDx = value.getInt(TiC.PROPERTY_X);
			shadowDy = value.getInt(TiC.PROPERTY_Y);
			tv.setShadowLayer(shadowRadius, shadowDx, shadowDy, shadowColor);
		}
		// This needs to be the last operation.
		TiUIHelper.linkifyIfEnabled(tv, d.get(TiC.PROPERTY_AUTO_LINK));

		((EllipsizingTextView)tv).SetReadyToEllipsize(true);
		// tv.invalidate();
	}
	
	@Override
	public void propertyChanged(String key, Object oldValue, Object newValue, KrollProxy proxy)
	{
		TextView tv = (TextView) getNativeView();
		if (key.equals(TiC.PROPERTY_HTML)) {
			tv.setText(fromHtml(TiConvert.toString(newValue)), TextView.BufferType.SPANNABLE);
			TiUIHelper.linkifyIfEnabled(tv, proxy.getProperty(TiC.PROPERTY_AUTO_LINK));
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_TEXT) || key.equals(TiC.PROPERTY_TITLE)) {
			tv.setText(TiConvert.toString(newValue));
			TiUIHelper.linkifyIfEnabled(tv, proxy.getProperty(TiC.PROPERTY_AUTO_LINK));
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_COLOR)) {
			tv.setTextColor(TiConvert.toColor((String) newValue));
		} else if (key.equals(TiC.PROPERTY_HIGHLIGHTED_COLOR)) {
			tv.setHighlightColor(TiConvert.toColor((String) newValue));
		} else if (key.equals(TiC.PROPERTY_TEXT_ALIGN)) {
			TiUIHelper.setAlignment(tv, TiConvert.toString(newValue), null);
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_VERTICAL_ALIGN)) {
			TiUIHelper.setAlignment(tv, null, TiConvert.toString(newValue));
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_FONT)) {
			TiUIHelper.styleText(tv, (HashMap) newValue);
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_ELLIPSIZE)) {
			if (newValue instanceof Boolean) {
				tv.setEllipsize(((Boolean)newValue)?TruncateAt.END:null);
			}
			else {
				String str = TiConvert.toString(newValue);
				if (str != null && !str.equals("none")) //none represents TEXT_ELLIPSIS_NONE
					tv.setEllipsize(TruncateAt.valueOf(str));
				else
					tv.setEllipsize(null);
			}
		} else if (key.equals(TiC.PROPERTY_MULTILINE_ELLIPSIZE)) {
			if (newValue instanceof Boolean) {
				((EllipsizingTextView)tv).setMultiLineEllipsize(((Boolean)newValue)?TruncateAt.END:null);
			}
			else {
				String str = TiConvert.toString(newValue);
				if (str != null && !str.equals("none")) //none represents TEXT_ELLIPSIS_NONE
					((EllipsizingTextView)tv).setMultiLineEllipsize(TruncateAt.valueOf(str));
				else
					((EllipsizingTextView)tv).setMultiLineEllipsize(null);
			}
		} else if (key.equals(TiC.PROPERTY_WORD_WRAP)) {
			tv.setSingleLine(!TiConvert.toBoolean(newValue));
		} else if (key.equals(TiC.PROPERTY_MAX_LINES)) {
			tv.setMaxLines(TiConvert.toInt(newValue));
		} else if (key.equals(TiC.PROPERTY_AUTO_LINK)) {
			Linkify.addLinks(tv, TiConvert.toInt(newValue));
		} else if (key.equals(TiC.PROPERTY_TEXT_PADDING_LEFT)) {
			textPadding.left = TiConvert.toInt(newValue);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_TEXT_PADDING_RIGHT)) {
			textPadding.right = TiConvert.toInt(newValue);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_TEXT_PADDING_TOP)) {
			textPadding.top = TiConvert.toInt(newValue);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_TEXT_PADDING_BOTTOM)) {
			textPadding.bottom = TiConvert.toInt(newValue);
			tv.setPadding(textPadding.left, textPadding.top, textPadding.right, textPadding.bottom);
			tv.requestLayout();
		} else if (key.equals(TiC.PROPERTY_SHADOW_COLOR)) {
			shadowColor = TiConvert.toColor((String) newValue);
			tv.setShadowLayer(shadowRadius, shadowDx, shadowDy, shadowColor);
		} else if (key.equals(TiC.PROPERTY_SHADOW_RADIUS)) {
			shadowRadius = TiConvert.toFloat(newValue);
			tv.setShadowLayer(shadowRadius, shadowDx, shadowDy, shadowColor);
		} else if (key.equals(TiC.PROPERTY_SHADOW_OFFSET)) {
			shadowDx = TiConvert.toInt(((HashMap) newValue).get(TiC.PROPERTY_X));
			shadowDy = TiConvert.toInt(((HashMap) newValue).get(TiC.PROPERTY_Y));
			tv.setShadowLayer(shadowRadius, shadowDx, shadowDy, shadowColor);
			tv.requestLayout();
		} else {
			super.propertyChanged(key, oldValue, newValue, proxy);
		}
	}

	public void setClickable(boolean clickable) {
		((TextView)getNativeView()).setClickable(clickable);
	}

	@Override
	protected void setOpacity(View view, float opacity)
	{
		if (view != null && view instanceof TextView) {
			TiUIHelper.setPaintOpacity(((TextView) view).getPaint(), opacity);
		}
		super.setOpacity(view, opacity);
	}

	@Override
	public void clearOpacity(View view)
	{
		super.clearOpacity(view);
		if (view != null && view instanceof TextView) {
			((TextView) view).getPaint().setColorFilter(null);
		}
	}
	
}
