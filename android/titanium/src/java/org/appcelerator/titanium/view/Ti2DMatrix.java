/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2012 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
package org.appcelerator.titanium.view;

import java.util.ArrayList;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.kroll.KrollProxy;
import org.appcelerator.kroll.annotations.Kroll;
import org.appcelerator.titanium.TiC;
import org.appcelerator.titanium.TiPoint;
import org.appcelerator.titanium.util.AffineTransform;
import org.appcelerator.titanium.util.TiConvert;
import org.appcelerator.titanium.TiDimension;
import org.appcelerator.titanium.proxy.TiViewProxy;

import android.graphics.Matrix;

import android.view.View;
import android.view.ViewParent;

@Kroll.proxy
public class Ti2DMatrix extends KrollProxy {
	public static final TiPoint DEFAULT_ANCHOR_VALUE = new TiPoint("50%", "50%");
	public static final TiPoint DEFAULT_TRANSLATETO_VALUE = new TiPoint(0, 0);
	public static final float VALUE_UNSPECIFIED = Float.MIN_VALUE;

	public ArrayList<Operation> operations = new ArrayList<Operation>();

	public TiPoint anchor;

	protected AffineTransform transform = null;

	protected static class Operation {
		protected static final int TYPE_SCALE = 0;
		protected static final int TYPE_TRANSLATE = 1;
		protected static final int TYPE_ROTATE = 2;
		protected static final int TYPE_INVERT = 3;
		protected static final int TYPE_MULTIPLY = 4;

		protected float scaleToX, scaleToY;
		protected float rotateOf;
		protected TiPoint anchor;
		protected TiPoint translateTo;
		protected Ti2DMatrix multiplyWith;
		protected int type;

		public Operation(Ti2DMatrix matrix, int type) {

			if (matrix != null && matrix.anchor != null) {
				this.anchor = matrix.anchor;
			}
			scaleToX = scaleToY = 1;
			translateTo = DEFAULT_TRANSLATETO_VALUE;
			rotateOf = 0;
			this.type = type;
		}

		public void apply(View view, AffineTransform transform) {
			float anchorX = 0;
			float anchorY = 0;
			if (type == TYPE_SCALE || type == TYPE_ROTATE) {
				TiPoint realAnchor = this.anchor;
				if (realAnchor == null)
					realAnchor = DEFAULT_ANCHOR_VALUE;
				anchorX = realAnchor.getX().getAsPixels(view);
				anchorY = realAnchor.getY().getAsPixels(view);
			}
			switch (type) {
			case TYPE_SCALE:
				transform.scale(scaleToX, scaleToY, anchorX, anchorY);
			case TYPE_TRANSLATE:
				View parent = (View) view.getParent();
				if (parent == null)
					parent = view;
				float translateToX = translateTo.getX().getAsPixels(parent);
				float translateToY = translateTo.getY().getAsPixels(parent);
				transform.translate(translateToX, translateToY);
				break;
			case TYPE_ROTATE:
				transform.rotate(rotateOf, anchorX, anchorY);
				break;
			case TYPE_MULTIPLY:
				transform.multiply(multiplyWith.getAffineTransform(view));
				break;
			case TYPE_INVERT:
				transform.inverse();
				break;
			}
		}
	}

	// protected Operation op;

	public Ti2DMatrix() {
	}

	public Ti2DMatrix(AffineTransform transform) {
		this.transform = transform;
	}

	public Ti2DMatrix(Ti2DMatrix prev) {
		if (prev != null) {
			handleAnchorPoint(prev.getProperties());
			operations.addAll(prev.operations);
		}
	}

	@Override
	public void handleCreationDict(KrollDict dict) {
		super.handleCreationDict(dict);
		handleAnchorPoint(dict);
		if (dict.containsKey(TiC.PROPERTY_ROTATE)) {

			Operation op = new Operation(this, Operation.TYPE_ROTATE);
			op.rotateOf = TiConvert.toFloat(dict, TiC.PROPERTY_ROTATE);
			operations.add(op);
			// If scale also specified in creation dict,
			// then we need to link a scaling matrix separately.
			if (dict.containsKey(TiC.PROPERTY_SCALE)) {
				KrollDict newDict = new KrollDict();
				newDict.put(TiC.PROPERTY_SCALE, dict.get(TiC.PROPERTY_SCALE));
				if (dict.containsKey(TiC.PROPERTY_ANCHOR_POINT)) {
					newDict.put(TiC.PROPERTY_ANCHOR_POINT,
							dict.get(TiC.PROPERTY_ANCHOR_POINT));
				}
				Operation scaleOp = new Operation(this, Operation.TYPE_SCALE);
				scaleOp.scaleToX = op.scaleToY = TiConvert.toFloat(dict,
						TiC.PROPERTY_SCALE);
				operations.add(0, op);
			}

		} else if (dict.containsKey(TiC.PROPERTY_SCALE)) {
			Operation op = new Operation(this, Operation.TYPE_SCALE);
			op.scaleToX = op.scaleToY = TiConvert.toFloat(dict,
					TiC.PROPERTY_SCALE);
			operations.add(op);
		}
	}

	protected void handleAnchorPoint(KrollDict dict) {
		if (dict.containsKey(TiC.PROPERTY_ANCHOR_POINT)) {
			KrollDict anchorPoint = dict
					.getKrollDict(TiC.PROPERTY_ANCHOR_POINT);
			setProperty(TiC.PROPERTY_ANCHOR_POINT, anchorPoint);
			anchor = TiConvert.toPoint(anchorPoint);
		}
	}

	@Kroll.method
	public Ti2DMatrix translate(Object args[]) {
		Ti2DMatrix newMatrix = new Ti2DMatrix(this);
		if (args.length == 2) {
			Operation op = new Operation(newMatrix, Operation.TYPE_TRANSLATE);
			op.translateTo = new TiPoint(TiConvert.toString(args[0]),
					TiConvert.toString(args[1]));
			newMatrix.operations.add(op);
		}
		return newMatrix;
	}

	@Kroll.method
	public Ti2DMatrix scale(Object args[]) {
		Ti2DMatrix newMatrix = new Ti2DMatrix(this);
		Operation op = new Operation(newMatrix, Operation.TYPE_SCALE);
		if (args.length == 2) {
			op.scaleToX = TiConvert.toFloat(args[0]);
			op.scaleToY = TiConvert.toFloat(args[1]);
		} else if (args.length == 1) {
			op.scaleToX = op.scaleToY = TiConvert.toFloat(args[0]);
		}
		newMatrix.operations.add(op);
		return newMatrix;
	}

	@Kroll.method
	public Ti2DMatrix rotate(Object[] args) {
		Ti2DMatrix newMatrix = new Ti2DMatrix(this);

		if (args.length >= 1) {
			Operation op = new Operation(newMatrix, Operation.TYPE_ROTATE);
			op.rotateOf = TiConvert.toFloat(args[0]);
			newMatrix.operations.add(op);
		}
		return newMatrix;
	}

	@Kroll.method
	public Ti2DMatrix invert() {
		Ti2DMatrix newMatrix = new Ti2DMatrix(this);
		Operation op = new Operation(newMatrix, Operation.TYPE_INVERT);
		newMatrix.operations.add(op);
		return newMatrix;
	}

	@Kroll.method
	public Ti2DMatrix multiply(Ti2DMatrix other) {
		Ti2DMatrix newMatrix = new Ti2DMatrix(this);
		Operation op = new Operation(newMatrix, Operation.TYPE_MULTIPLY);
		op.multiplyWith = other;
		newMatrix.operations.add(op);
		return newMatrix;
	}
	
	@Kroll.method @Kroll.setProperty
	public void setAnchorPoint(KrollDict dict) {
		setProperty(TiC.PROPERTY_ANCHOR_POINT, dict);
		anchor = TiConvert.toPoint(dict);
	}

	@Kroll.method
	public float[] finalValuesAfterInterpolation(TiViewProxy proxy) {
		View view = proxy.getOuterView();
		if (view != null) {
			float[] result = new float[9];
			Matrix m = getMatrix(proxy);
			m.getValues(result);
			return result;
		}
		return null;
	}

	public Matrix getMatrix(TiViewProxy proxy) {
		return getMatrix(proxy.getOuterView());
	}
	
	public AffineTransform getAffineTransform(View view) {
		if (transform != null) return transform;
		if (view == null || view.getMeasuredWidth() == 0 || view.getMeasuredHeight() == 0 ) return null;
		AffineTransform result = new AffineTransform();
		for (Operation op : operations) {
			if (op != null) {
				op.apply(view, result);
			}
		}
		return result;
	}

	public Matrix getMatrix(View view) {
		AffineTransform transform = getAffineTransform(view);
		return (transform != null)?transform.toMatrix():null;
	}
}
