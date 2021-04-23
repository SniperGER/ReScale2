ARCHS = armv7 arm64 arm64e
TARGET = iphone:13.7:9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReScale

ReScale_FILES = Tweak.xm
ReScale_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk