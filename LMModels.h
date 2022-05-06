//
// Created by my on 2022/4/22.
//

#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>

@interface LMModel: NSObject
- (NSDictionary *)toDictionary;

+ (id)fromDictionary: (NSDictionary *)dictionary;
@end

@interface LMLocation: LMModel
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * detail;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@end

@interface LMApplicationSetting: LMModel
@property (nonatomic, assign) BOOL isEnable;
@property (nonatomic, copy) NSString * identifier;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * iconPath;
@property (nonatomic, strong) LMLocation * location;
@end

@interface LMGlobalSetting: LMModel
@property (nonatomic, assign) BOOL isEnable;
@property (nonatomic, strong) LMLocation * location;
@end

@interface LMSettings : LMModel
@property (nonatomic, assign) BOOL isEnable;
@property (nonatomic, strong) LMGlobalSetting * globalSetting;
@property (nonatomic, copy) NSArray * applicationSettingList;

- (void)reset;
@end