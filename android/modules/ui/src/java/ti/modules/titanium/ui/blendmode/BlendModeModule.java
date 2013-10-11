package ti.modules.titanium.ui.blendmode;

import org.appcelerator.kroll.KrollModule;
import org.appcelerator.kroll.annotations.Kroll;

import android.graphics.PorterDuff.Mode;

import ti.modules.titanium.ui.UIModule;

@Kroll.module(parentModule=UIModule.class)
public class BlendModeModule extends KrollModule {

	@Kroll.constant public static final int DARKEN = Mode.DARKEN.ordinal();
	@Kroll.constant public static final int LIGHTEN = Mode.LIGHTEN.ordinal();
	@Kroll.constant public static final int MULTIPLY = Mode.MULTIPLY.ordinal();
	@Kroll.constant public static final int ADD = Mode.ADD.ordinal();
	@Kroll.constant public static final int SCREEN = Mode.SCREEN.ordinal();
	@Kroll.constant public static final int CLEAR = Mode.CLEAR.ordinal();
	@Kroll.constant public static final int DST = Mode.DST.ordinal();
	@Kroll.constant public static final int SRC = Mode.SRC.ordinal();
	@Kroll.constant public static final int DST_ATOP = Mode.DST_ATOP.ordinal();
	@Kroll.constant public static final int DST_IN = Mode.DST_IN.ordinal();
	@Kroll.constant public static final int DST_OUT = Mode.DST_OUT.ordinal();
	@Kroll.constant public static final int DST_OVER = Mode.DST_OVER.ordinal();
	@Kroll.constant public static final int SRC_ATOP = Mode.SRC_ATOP.ordinal();
	@Kroll.constant public static final int SRC_IN = Mode.SRC_IN.ordinal();
	@Kroll.constant public static final int SRC_OUT = Mode.SRC_OUT.ordinal();
	@Kroll.constant public static final int SRC_OVER = Mode.SRC_OVER.ordinal();
	@Kroll.constant public static final int OVERLAY = Mode.OVERLAY.ordinal();
	@Kroll.constant public static final int XOR = Mode.XOR.ordinal();
}
