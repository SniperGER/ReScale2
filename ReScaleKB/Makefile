ARCHS = armv7 arm64 arm64e
TARGET = iphone:13.7:9.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ReScaleKB

ReScaleKB_FILES = Tweak.xm
ReScaleKB_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
