TARGET := iphone:clang:latest:7.0
THEOS_DEVICE_IP = 172.16.100.139
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LIBLocationManager
LIBLocationManager_FILES = LocationManager.x  LocationTransformer.m
LIBLocationManager_FRAMEWORKS = CoreLocation
LIBLocationManager_CFLAGS = -fobjc-arc
LIBLocationManager_ARCHS = arm64

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = LocationManager
LocationManager_FILES = LMMapViewController.m LMApplicationListController.m LMRootViewController.m LMModels.m
LocationManager_FRAMEWORKS = UIKit MapKit CoreLocation
LocationManager_LIBRARIES = applist
LocationManager_PRIVATE_FRAMEWORKS = Preferences
LocationManager_INSTALL_PATH = /Library/PreferenceBundles
LocationManager_CFLAGS = -fobjc-arc -Wno-unused-variable -Wno-missing-braces -Wno-error -Wno-incompatible-pointer-types-discards-qualifiers -Wno-unknown-pragmas

include $(THEOS)/makefiles/bundle.mk

after-install::
	install.exec "killall -9 Preferences"
	#install.exec "killall -9 SpringBoard"
