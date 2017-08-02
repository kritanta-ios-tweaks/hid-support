# lipoplastic setup for armv6 + arm64 compilation
export TARGET := iphone:clang
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 3.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
export ARCHS = armv7 arm64

export THEOS_DEVICE_IP=localhost
export THEOS_DEVICE_PORT=2222

THEOS_PACKAGE_DIR_NAME=debs

SUBPROJECTS = libhidsupport hidsupporttest hidspringboard hidlowtide hidsample

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/aggregate.mk
