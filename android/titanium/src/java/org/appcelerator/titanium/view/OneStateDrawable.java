package org.appcelerator.titanium.view;

import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.Rect;
import android.graphics.Shader;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.view.View;

public class OneStateDrawable extends Drawable {
			
	Drawable colorDrawable;
	Drawable imageDrawable; //BitmapDrawable or NinePatchDrawable
	Drawable gradientDrawable;

	@Override
	public void draw(Canvas canvas) {
		if (colorDrawable != null)
			colorDrawable.draw(canvas);
		if (gradientDrawable != null)
			gradientDrawable.draw(canvas);
		if (imageDrawable != null)
			imageDrawable.draw(canvas);
	}

	@Override
	public int getOpacity() {
		return 0;
	}

	@Override
	public void setAlpha(int alpha) {
		if (colorDrawable != null)
			colorDrawable.setAlpha(alpha);
		if (gradientDrawable != null)
			gradientDrawable.setAlpha(alpha);
		if (imageDrawable != null)
			imageDrawable.setAlpha(alpha);
	}

	@Override
	public void setColorFilter(ColorFilter cf) {			
	}
	
	@Override
	public void setBounds (Rect bounds) {
		if (colorDrawable != null)
			colorDrawable.setBounds(bounds);
		if (gradientDrawable != null)
			gradientDrawable.setBounds(bounds);
		if (imageDrawable != null)
			imageDrawable.setBounds(bounds);
	}
	
	@Override
	public boolean setState (int[] stateSet) {
		boolean result = false;
		if (colorDrawable != null)
			result |= colorDrawable.setState(stateSet);
		if (gradientDrawable != null)
			result |= gradientDrawable.setState(stateSet);
		if (imageDrawable != null)
			result |= imageDrawable.setState(stateSet);
		return result;
	}
	
	@Override
	public void invalidateSelf() {
		if (colorDrawable != null)
			colorDrawable.invalidateSelf();
		if (gradientDrawable != null)
			gradientDrawable.invalidateSelf();
		if (imageDrawable != null)
			imageDrawable.invalidateSelf();
	}
	
	public void releaseDelegate() {
		if (imageDrawable != null && imageDrawable instanceof BitmapDrawable)
			((BitmapDrawable)imageDrawable).getBitmap().recycle();
		imageDrawable = null;
		colorDrawable = null;
		gradientDrawable = null;
	}
	
	public void invalidateDrawable(Drawable who) {
		if (colorDrawable == who)
			colorDrawable.invalidateSelf();
		else if (gradientDrawable  == who)
			gradientDrawable.invalidateSelf();
		else if (imageDrawable  == who)
			imageDrawable.invalidateSelf();
	}
	
	public void setColorDrawable(Drawable drawable)
	{
		colorDrawable = drawable;
	}
	
	public void setBitmapDrawable(Drawable drawable)
	{
		if (imageDrawable != null && imageDrawable instanceof BitmapDrawable)
			((BitmapDrawable)imageDrawable).getBitmap().recycle();
		imageDrawable = drawable;
	}
	
	public void setImageRepeat(boolean repeat)
	{
		if (imageDrawable != null && imageDrawable instanceof BitmapDrawable) {
			BitmapDrawable drawable  = (BitmapDrawable)imageDrawable;
			drawable.setTileModeX(Shader.TileMode.REPEAT);
			drawable.setTileModeY(Shader.TileMode.REPEAT);
		}
	}
	
	public void setGradientDrawable(Drawable drawable)
	{
		gradientDrawable = drawable;
	}
	
	protected void setNativeView(View view)
	{
		if (gradientDrawable != null && imageDrawable instanceof TiGradientDrawable) {
			TiGradientDrawable drawable  = (TiGradientDrawable)gradientDrawable;
			drawable.setView(view);
			drawable.invalidateSelf();
		}
	}
	
}