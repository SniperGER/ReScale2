THEOS_DEVICE_IP = Janiks-iPhone-X.local

PACKAGE_VERSION = 1.0.5

INSTALL_TARGET_PROCESSES = backboardd aggregated
# INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += ReScale ReScaleUIKit ReScaleKB
SUBPROJECTS += ReScalePreferences
SUBPROJECTS += ReScaleActivator
include $(THEOS_MAKE_PATH)/aggregate.mk
