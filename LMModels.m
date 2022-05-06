//
// Created by my on 2022/4/22.
//

#import <UIKit/UIKit.h>
#import "LMModels.h"
#import <AppList/AppList.h>

@implementation LMModel
- (NSDictionary *)toDictionary { return nil; }

+ (id)fromDictionary:(NSDictionary *)dictionary { return nil; }
@end

@implementation LMGlobalSetting
+ (id)fromDictionary:(NSDictionary *)dictionary {
    LMGlobalSetting * retValue = [[self alloc] init];
    retValue.isEnable = [[dictionary valueForKey:@"isEnable"] boolValue];
    retValue.location = [LMLocation fromDictionary:[dictionary valueForKey:@"location"]];
    return retValue;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary * dictionary = [@{} mutableCopy];
    [dictionary setValue:@(_isEnable) forKey:@"isEnable"];
    [dictionary setValue:[_location toDictionary] forKey:@"location"];
    return [dictionary copy];
}
@end

@implementation LMSettings

+ (id)fromDictionary:(NSDictionary *)dictionary {
    NSMutableArray * applicationSettingList = [@[] mutableCopy];
    NSDictionary * applications = [[ALApplicationList sharedApplicationList] applications];
    NSArray * allIdentifiers = [applications allKeys];
    for (NSDictionary * dictionary1 in [dictionary valueForKey:@"applicationSettingList"]) {
        if ([allIdentifiers containsObject: [dictionary1 valueForKey:@"identifier"]]) {
            LMApplicationSetting *applicationSetting = [LMApplicationSetting fromDictionary:dictionary1];
            [applicationSettingList addObject:applicationSetting];
        }
    }

    LMSettings * retValue = [[self alloc] init];
    retValue.isEnable = [[dictionary valueForKey:@"isEnable"] boolValue];
    retValue.globalSetting = [LMGlobalSetting fromDictionary:[dictionary valueForKey:@"globalSetting"]];
    retValue.applicationSettingList = [applicationSettingList copy];
    return retValue;
}

- (NSDictionary *)toDictionary {
    NSMutableArray * applicationSettingList = [@[] mutableCopy];
    for (LMApplicationSetting * applicationSetting in _applicationSettingList) {
        [applicationSettingList addObject:[applicationSetting toDictionary]];
    }

    NSMutableDictionary * dictionary = [@{} mutableCopy];
    [dictionary setValue:@(_isEnable) forKey:@"isEnable"];
    [dictionary setValue:[_globalSetting toDictionary] forKey:@"globalSetting"];

    [dictionary setValue:[applicationSettingList copy] forKey: @"applicationSettingList"];
    return [dictionary copy];
}

- (void)reset {
    self.globalSetting = [LMGlobalSetting fromDictionary:@{}];
    self.applicationSettingList = @[];
}
@end

@implementation LMApplicationSetting
+ (id)fromDictionary:(NSDictionary *)dictionary {
    LMApplicationSetting * retValue = [[self alloc] init];
    retValue.isEnable = [[dictionary valueForKey:@"isEnable"] boolValue];
    retValue.identifier = [dictionary valueForKey:@"identifier"];
    retValue.name = [dictionary valueForKey:@"name"];
    retValue.iconPath = [dictionary valueForKey:@"iconPath"];
    retValue.location = [LMLocation fromDictionary: [dictionary valueForKey: @"location"]];
    return retValue;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary * dictionary = [@{} mutableCopy];
    [dictionary setValue:@(_isEnable) forKey:@"isEnable"];
    [dictionary setValue:[_identifier copy] forKey:@"identifier"];
    [dictionary setValue:[_name copy] forKey:@"name"];
    [dictionary setValue:[_iconPath copy] forKey:@"iconPath"];
    [dictionary setValue:[_location toDictionary] forKey:@"location"];
    return [dictionary copy];
}
@end

@implementation LMLocation
+ (id)fromDictionary:(NSDictionary *)dictionary {
    NSDictionary * coordinate = [dictionary valueForKey:@"coordinate"];

    LMLocation * retValue = [[self alloc] init];
    retValue.name = [dictionary valueForKey:@"name"];
    retValue.detail = [dictionary valueForKey:@"detail"];
    retValue.coordinate = (CLLocationCoordinate2D){[[coordinate valueForKey:@"latitude"] doubleValue], [[coordinate valueForKey:@"longitude"] doubleValue]};
    return retValue;
}

- (NSDictionary *)toDictionary {
    NSDictionary * coordinate = nil;
    if (CLLocationCoordinate2DIsValid(_coordinate)) coordinate = @{@"latitude": @(_coordinate.latitude), @"longitude": @(_coordinate.longitude)};

    NSMutableDictionary * dictionary = [@{} mutableCopy];
    [dictionary setValue:_name forKey:@"name"];
    [dictionary setValue:_detail forKey:@"detail"];
    [dictionary setValue:coordinate forKey:@"coordinate"];
    return [dictionary copy];
}
@end