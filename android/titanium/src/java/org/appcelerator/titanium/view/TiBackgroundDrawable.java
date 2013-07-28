/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package org.appcelerator.titanium.view;

import java.io.IOException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;

import org.appcelerator.kroll.common.Log;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.PaintDrawable;
import android.graphics.drawable.StateListDrawable;
import android.util.AttributeSet;
import android.util.SparseArray;
import android.util.StateSet;
import android.view.View;

public class TiBackgroundDrawable extends Drawable {
	private static final int NOT_SET = -1;
	private int alpha = NOT_SET;
	
	private RectF innerRect;
	private SparseArray<OneStateDrawable> drawables;
	private OneStateDrawable currentDrawable;
	private SparseArray<int[]> mStateSets;
	

	public TiBackgroundDrawable()
	{
		currentDrawable = null;
		mStateSets = new SparseArray<int[]>();
		drawables = new SparseArray<OneStateDrawable>();
		innerRect = new RectF();
	}
	
	private int keyOfStateSet(int[] stateSet) {
		int length = mStateSets.size();
		for(int i = 0; i < length; i++) {
			if (mStateSets.valueAt(i).equals(stateSet)) {
               return mStateSets.keyAt(i);
			}
		}
        return -1;
    }
	
	private int keyOfFirstMatchingStateSet(int[] stateSet) {
		int length = mStateSets.size();
		for(int i = 0; i < length; i++) {
		   if (StateSet.stateSetMatches(mStateSets.valueAt(i), stateSet)) {
               return mStateSets.keyAt(i);
           }
		}
        return -1;
    }
	
	private int keyOfBestMatchingStateSet(int[] stateSet) {
		int length = mStateSets.size();
		int bestSize = 0;
		int result = -1;
		for(int i = 0; i < length; i++) {
			int[] matchingStateSet = mStateSets.valueAt(i);
			if (StateSet.stateSetMatches(matchingStateSet, stateSet) && matchingStateSet.length > bestSize) {
			   bestSize = matchingStateSet.length;
			   result = mStateSets.keyAt(i);
			}
		}
        return result;
    }

	@Override
	public void draw(Canvas canvas)
	{
		canvas.save();
		
		if (currentDrawable != null) {
			currentDrawable.draw(canvas);
		}

		canvas.restore();
	}

	@Override
	protected void onBoundsChange(Rect bounds)
	{
		super.onBoundsChange(bounds);
		innerRect.set(bounds);
		int length = drawables.size();
		for(int i = 0; i < length; i++) {
		   Drawable drawable = drawables.valueAt(i);
		   drawable.setBounds(bounds);
		}
	}
	
	// @Override
	// protected boolean onLevelChange(int level)
	// {
	// 	return super.onLevelChange(level);
	// }
	
	// @Override
	// public boolean setState (int[] stateSet) {
	// 	return super.setState(stateSet);
	// }

	@Override
	protected boolean onStateChange(int[] stateSet) {
		
		super.onStateChange(stateSet);
		setState(stateSet);
		int key = keyOfBestMatchingStateSet(stateSet);
        if (key < 0) {
        	key = keyOfBestMatchingStateSet(StateSet.WILD_CARD);
        }
		OneStateDrawable newdrawable = null;
		if (key != -1)
		{
			newdrawable = drawables.get(key);
			invalidateSelf();
		}
		
		if (newdrawable != currentDrawable)
		{
			currentDrawable = newdrawable;
			invalidateSelf();
			return true;
		}
		return false;
	}
	
	public boolean isStateful()
	{
		return true;
	}
	
	private OneStateDrawable getOrCreateDrawableForState(int[] stateSet)
	{
		OneStateDrawable drawable;
		int key = keyOfStateSet(stateSet);
		if (key == -1)
		{
			key = mStateSets.size();
			mStateSets.append(key, stateSet);
			drawable = new OneStateDrawable();
			drawables.append(key, drawable);
		}
		else
		{
			drawable = drawables.get(key);
		}
		return drawable;
	}
	
	public int getColorForState(int[] stateSet)
	{
		int result = 0;
		int key = keyOfStateSet(stateSet);
		if (key != -1)
			result = drawables.get(key).getColor();
		return result;
	}
	
	public void setColorDrawableForState(int[] stateSet, Drawable drawable)
	{
		if (drawable != null) {
			drawable.setBounds(this.getBounds());
			drawable.setAlpha(this.alpha);
		}
		getOrCreateDrawableForState(stateSet).setColorDrawable(drawable);
		onStateChange(getState());
	}
	
	public void setImageDrawableForState(int[] stateSet, Drawable drawable)
	{
		if (drawable != null) {
			drawable.setBounds(this.getBounds());
			drawable.setAlpha(this.alpha);
		}
		getOrCreateDrawableForState(stateSet).setBitmapDrawable(drawable);
		onStateChange(getState());
	}
	
	public void setGradientDrawableForState(int[] stateSet, Drawable drawable)
	{
		if (drawable != null) {
			drawable.setBounds(this.getBounds());
			drawable.setAlpha(this.alpha);
		}
		getOrCreateDrawableForState(stateSet).setGradientDrawable(drawable);
		onStateChange(getState());
	}
	
	protected void setNativeView(View view)
	{
		int length = drawables.size();
		for(int i = 0; i < length; i++) {
			OneStateDrawable drawable = drawables.valueAt(i);
			drawable.setNativeView(view);
		}
	}
	
	public void setImageRepeat(boolean repeat)
	{
		int length = drawables.size();
		for(int i = 0; i < length; i++) {
			OneStateDrawable drawable = drawables.valueAt(i);
			drawable.setImageRepeat(repeat);
		}
	}

	// @Override
	// public void invalidateSelf() {
	// 	super.invalidateSelf();
	// }

	public void invalidateDrawable(Drawable who) {
		
		int length = drawables.size();
		for(int i = 0; i < length; i++) {
			OneStateDrawable drawable = drawables.valueAt(i);
			drawable.invalidateDrawable(who);
		}

	}

	public void releaseDelegate() {
		int length = drawables.size();
		for(int i = 0; i < length; i++) {
			OneStateDrawable drawable = drawables.valueAt(i);
			drawable.releaseDelegate();
		}
	}

	@Override
	public void setAlpha(int alpha)
	{
		this.alpha = alpha;
		int key = 0;
		int length = drawables.size();
		for(int i = 0; i < length; i++) {
		   key = drawables.keyAt(i);
		   Drawable drawable = drawables.get(key);
			drawable.setAlpha(alpha);
		}
	}

	@Override
	public int getOpacity() {
		return 0;
	}

	@Override
	public void setColorFilter(ColorFilter cf) {
		
	}
}
