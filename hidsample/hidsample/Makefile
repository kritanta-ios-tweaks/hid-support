
THEOS_DEVICE_IP=localhost
THEOS_DEVICE_PORT=2222

include $(THEOS)/makefiles/common.mk


ARCHS = arm64

TOOL_NAME = hidsample
#TOOL_CFLAGS= -I

hidsample_FILES = main.mm
hidsample_LDFLAGS=-lhidsupport


include $(THEOS_MAKE_PATH)/tool.mk
