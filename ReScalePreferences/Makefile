ARCHS = armv7 arm64 arm64e
TARGET = iphone:13.7:9.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = ReScalePreferences

ReScalePreferences_FILES = $(wildcard *.m) PFHeaderCell.mm
ReScalePreferences_FRAMEWORKS = UIKit
ReScalePreferences_PRIVATE_FRAMEWORKS = Preferences
ReScalePreferences_INSTALL_PATH = /Library/PreferenceBundles
ReScalePreferences_CFLAGS = -fobjc-arc -include Prefix.pch

include $(THEOS_MAKE_PATH)/bundle.mk
