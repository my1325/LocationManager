#include <CoreLocation/CoreLocation.h>
#include <UIKit/UIKit.h>
#include "LocationTransformer.h"

@interface CLLocation(Coordinate)
- (CLLocationCoordinate2D)handleCoordinate: (CLLocationCoordinate2D)coordinate withBundleIdentifier: (NSString *)identifier;
@end
@implementation CLLocation(Coordinate)
- (CLLocationCoordinate2D)handleCoordinate: (CLLocationCoordinate2D)coordinate withBundleIdentifier: (NSString *)identifier {
    LocationTransformer * lt = [[LocationTransformer alloc] initWithLatitude:coordinate.latitude andLongitude:coordinate.longitude];
    LocationTransformer * earth = [lt transformFromGDToGPS];
    if ([identifier isEqualToString: @"com.autonavi.amap"]) {
        coordinate = (CLLocationCoordinate2D){earth.latitude, earth.longitude};
    } else if ([identifier isEqualToString: @"com.baidu.map"]) {
        coordinate = (CLLocationCoordinate2D){earth.latitude, earth.longitude};
    }
    return coordinate;
}
@end

%group HookLocationManager
%hook CLLocation
- (CLLocationCoordinate2D)coordinate {
     NSString * bundleIdentifier = [NSBundle mainBundle].bundleIdentifier;
    if ([bundleIdentifier isEqualToString: @"com.apple.Preferences"]) return %orig;

    NSDictionary * settings = [[NSDictionary alloc] initWithContentsOfFile: @"/var/mobile/Library/Preferences/com.my.re.lm.plist"];
    BOOL isEnable = [[settings valueForKey: @"isEnable"] boolValue];
    if (!isEnable) return %orig;

    NSDictionary * globalSetting = [settings valueForKey: @"globalSetting"];
    isEnable = [[globalSetting valueForKey: @"isEnable"] boolValue];

    if (isEnable) {
        NSDictionary * locationSetting = [globalSetting valueForKey: @"location"];
        NSDictionary * coordinate  = [locationSetting valueForKey: @"coordinate"];

        double latitude = [[coordinate valueForKey: @"latitude"] doubleValue];
        double longitude = [[coordinate valueForKey: @"longitude"] doubleValue];
        CLLocationCoordinate2D retCoordinate = (CLLocationCoordinate2D){latitude, longitude};
        if (!CLLocationCoordinate2DIsValid(retCoordinate)) retCoordinate = %orig;
        else retCoordinate =  [self handleCoordinate: retCoordinate withBundleIdentifier: bundleIdentifier];
        return retCoordinate;
    }

    NSArray * applicationSettingList = [settings valueForKey: @"applicationSettingList"];
    for (NSDictionary * applicationSetting in applicationSettingList) {
        NSString * identifier = [applicationSetting valueForKey: @"identifier"];
        if (![identifier isEqualToString: bundleIdentifier]) continue;
        if (![[applicationSetting valueForKey: @"isEnable"] boolValue]) return %orig;

         NSDictionary * locationSetting = [applicationSetting valueForKey: @"location"];
         NSDictionary * coordinate  = [locationSetting valueForKey: @"coordinate"];

        double latitude = [[coordinate valueForKey: @"latitude"] doubleValue];
        double longitude = [[coordinate valueForKey: @"longitude"] doubleValue];
        CLLocationCoordinate2D retCoordinate = (CLLocationCoordinate2D){latitude, longitude};
        if (!CLLocationCoordinate2DIsValid(retCoordinate)) retCoordinate = %orig;
        else retCoordinate =  [self handleCoordinate: retCoordinate withBundleIdentifier: bundleIdentifier];
        return retCoordinate;
    }
    return %orig;
}

%end

%end

%ctor {
    %init(HookLocationManager);
}