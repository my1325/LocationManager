//
// Created by my on 2022/4/21.
//

#import "PSViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "LMModels.h"

typedef void(^LocationSelectCompletion)(NSDictionary * location);
@interface LMMapViewController : PSViewController
@property (nonatomic, copy) LocationSelectCompletion completion;
@property (nonatomic, strong) LMLocation * location;
@end