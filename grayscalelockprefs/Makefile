ARCHS = armv7 armv7s arm64 arm64e

include theos/makefiles/common.mk

BUNDLE_NAME = GrayscaleLock
GrayscaleLock_FILES = GrayscaleLock.mm
GrayscaleLock_INSTALL_PATH = /Library/PreferenceBundles
GrayscaleLock_FRAMEWORKS = UIKit
GrayscaleLock_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GrayscaleLock.plist$(ECHO_END)
