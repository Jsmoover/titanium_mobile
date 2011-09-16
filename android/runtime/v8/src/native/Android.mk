# 
# Top level v8 runtime Makefile
#

LOCAL_PATH := $(call my-dir)
LIBV8_DIR := $(LOCAL_PATH)/../../../dist/android/libv8/3.6.2
ABS_LIBV8_DIR := $(TI_DIST_DIR)/android/libv8/3.6.2

THIS_DIR := $(LOCAL_PATH)
GENERATED_DIR := $(LOCAL_PATH)/../../generated
SRC_JS_DIR := $(LOCAL_PATH)/../js
TITANIUM_APT_GEN_DIR := $(LOCAL_PATH)/../../../../titanium/.apt_generated

TOOLS_DIR := $(THIS_DIR)/../../tools
JS2C := $(TOOLS_DIR)/js2c.py

include $(CLEAR_VARS)

LOCAL_MODULE := kroll-v8
LOCAL_CFLAGS := -I$(LIBV8_DIR)/include -I$(TITANIUM_APT_GEN_DIR) -I$(GENERATED_DIR) -g
LOCAL_LDLIBS := -L$(SYSROOT)/usr/lib -L$(LIBV8_DIR)/lib -ldl -llog -L$(TARGET_OUT)
LOCAL_SRC_FILES += \
	../../generated/KrollNatives.h \
	Assets.cpp \
	EventEmitter.cpp \
	JNIUtil.cpp \
	KrollJavaScript.cpp \
	KrollProxy.cpp \
	TypeConverter.cpp \
	V8Object.cpp \
	V8Runtime.cpp \
	../../../../titanium/.apt_generated/org.appcelerator.kroll.KrollProxy.cpp

LOCAL_JS_FILES := \
	$(SRC_JS_DIR)/kroll.js \
	$(SRC_JS_DIR)/events.js

$(GENERATED_DIR)/KrollNatives.h: $(LOCAL_JS_FILES)
	mkdir $(GENERATED_DIR) || echo
	python $(JS2C) $(GENERATED_DIR)/KrollNatives.h $(LOCAL_JS_FILES)
 
LOCAL_STATIC_LIBRARIES := libv8

include $(BUILD_SHARED_LIBRARY)

NDK_MODULE_PATH := $(LOCAL_PATH)/../ndk-modules
$(call import-module,libv8)
