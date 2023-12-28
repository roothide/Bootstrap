ARCHS = arm64
TARGET = iphone:latest:15.0
DEB_ARCH = iphoneos-arm64e
IPHONEOS_DEPLOYMENT_TARGET = 15.0

INSTALL_TARGET_PROCESSES = Bootstrap

THEOS_PACKAGE_SCHEME = roothide

THEOS_DEVICE_IP = iphone13.local

CFVER ?= 1900

XCRUN := /usr/bin/xcrun
SDKROOT := $(shell $(XCRUN) -sdk 'iphoneos' -show-sdk-path)
CODESIGN := $(shell $(XCRUN) -sdk "$(SDKROOT)" -find codesign)
CODESIGN_ALLOCATE := $(shell $(XCRUN) -sdk "$(SDKROOT)" -find codesign_allocate)

#disable theos auto sign for all mach-o
TARGET_CODESIGN = echo "don't sign"

include $(THEOS)/makefiles/common.mk

XCODE_SCHEME = Bootstrap

XCODEPROJ_NAME = Bootstrap

Bootstrap_XCODEFLAGS = MARKETING_VERSION=$(THEOS_PACKAGE_BASE_VERSION) \
	IPHONEOS_DEPLOYMENT_TARGET="$(IPHONEOS_DEPLOYMENT_TARGET)" \
	CODE_SIGN_IDENTITY="" \
	AD_HOC_CODE_SIGNING_ALLOWED=YES
Bootstrap_XCODE_SCHEME = $(XCODE_SCHEME)
#Bootstrap_CODESIGN_FLAGS = -Sentitlements.plist
Bootstrap_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/xcodeproj.mk

clean::
	rm -rf ./packages/*

before-package::
	rm -rf ./packages
	cp ./bootstrap-$(CFVER).tar.zst ./.theos/_/Applications/Bootstrap.app/bootstrap.tar.zst
	env CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) \
	    $(CODESIGN) -s - --entitlements entitlements.plist ./.theos/_/Applications/Bootstrap.app/Bootstrap
	mkdir -p ./packages/Payload
	cp -R ./.theos/_/Applications/Bootstrap.app ./packages/Payload
	cd ./packages && zip -mry ./Bootstrap.tipa ./Payload
	rm -rf ./.theos/_/Applications
	mkdir ./.theos/_/tmp
	cp ./packages/Bootstrap.tipa ./.theos/_/tmp/

after-install::
	install.exec 'uiopen -b com.roothide.Bootstrap'
