INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NetWorkPeek

NetWorkPeek_FILES = Tweak.xm $(shell find ./sources -name '*.m' -print)
NetWorkPeek_FRAMEWORKS = UIKit CFNetwork IOKit CoreFoundation
NetWorkPeek_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

