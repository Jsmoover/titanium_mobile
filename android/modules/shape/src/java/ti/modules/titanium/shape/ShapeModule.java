package ti.modules.titanium.shape;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;

import org.appcelerator.titanium.TiApplication;
import org.appcelerator.titanium.TiC;
import org.appcelerator.kroll.common.Log;

@Kroll.module
public class ShapeModule extends KrollModule
{
	private static final String TAG = "ShapeModule";
	
	@Kroll.constant public static final String PROPERTY_POINT = "point";
	@Kroll.constant public static final String PROPERTY_RADIUS = "radius";
	@Kroll.constant public static final String PROPERTY_ANCHOR = "anchor";
	@Kroll.constant public static final String PROPERTY_SWEEPANGLE = "sweepAngle";
	@Kroll.constant public static final String PROPERTY_STARTANGLE = "startAngle";
	@Kroll.constant public static final String PROPERTY_RECT = "rect";
	@Kroll.constant public static final String PROPERTY_WIDTH_RADIUS = "widthRadius";
	@Kroll.constant public static final String PROPERTY_HEIGHT_RADIUS = "heightRadius";
	@Kroll.constant public static final String PROPERTY_X_RADIUS = "xRadius";
	@Kroll.constant public static final String PROPERTY_Y_RADIUS = "yRadius";

	
	
	@Kroll.constant public static final int ALIGNMENT_LEFT = 0;
	@Kroll.constant public static final int ALIGNMENT_CENTER = 1;
	@Kroll.constant public static final int ALIGNMENT_RIGHT = 2;
	@Kroll.constant public static final int ALIGNMENT_TOP = 3;
	@Kroll.constant public static final int ALIGNMENT_MIDDLE = 4;
	@Kroll.constant public static final int ALIGNMENT_BOTTOM = 5;
	@Kroll.constant public static final int LOCATION_TOP = 0;
	@Kroll.constant public static final int LOCATION_BOTTOM = 7;
	@Kroll.constant public static final int LOCATION_LEFT = 2;
	@Kroll.constant public static final int LOCATION_RIGHT = 5;
	@Kroll.constant public static final int CAP_BUTT = 0;
	@Kroll.constant public static final int CAP_ROUND = 1;
	@Kroll.constant public static final int CAP_SQUARE = 2;
	@Kroll.constant public static final int JOIN_MITER = 0;
	@Kroll.constant public static final int JOIN_ROUND = 1;
	@Kroll.constant public static final int JOIN_BEVEL = 2;

	@Kroll.constant public static final int HORIZONTAL = 0;
	@Kroll.constant public static final int VERTICAL = 1;
	
	@Kroll.constant public static final int CW = 0;
	@Kroll.constant public static final int CCW = 1;
	
	@Kroll.constant public static final int TOP_MIDDLE = 0;
	@Kroll.constant public static final int LEFT_TOP = 1;
	@Kroll.constant public static final int LEFT_MIDDLE = 2;
	@Kroll.constant public static final int LEFT_BOTTOM = 3;
	@Kroll.constant public static final int RIGHT_TOP = 4;
	@Kroll.constant public static final int RIGHT_MIDDLE = 5;
	@Kroll.constant public static final int RIGHT_BOTTOM = 6;
	@Kroll.constant public static final int BOTTOM_MIDDLE = 7;
	@Kroll.constant public static final int CENTER = 8;
	
	public ShapeModule()
	{
		super();
	}

	@Kroll.onAppCreate
	public static void onAppCreate(TiApplication app)
	{
		Log.d(TAG, "inside onAppCreate");
		// put module init code that needs to run when the application is created
	}
}

