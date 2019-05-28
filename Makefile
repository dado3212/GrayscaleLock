ARCHS = armv7 armv7s arm64 arm64e

THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

FINALPACKAGE = 1

include theos/makefiles/common.mk

TWEAK_NAME = GrayscaleLock
GrayscaleLock_FILES = Tweak.xm
GrayscaleLock_FRAMEWORKS = UIKit
GrayscaleLock_LDFLAGS = -lAccessibility

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += grayscalelockprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
