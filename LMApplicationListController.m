//
// Created by my on 2022/4/19.
//

#import "LMApplicationListController.h"
#import <AppList/AppList.h>
#import "LMModels.h"

@interface  LMApplicationListController()<UITableViewDelegate>
@property (nonatomic, strong) UITableView * tableView;

- (void)cellAtIndexPath:(NSIndexPath *)indexPath didChangeToValue:(id)newValue;
- (id)valueForCellAtIndexPath:(NSIndexPath *)indexPath;
@end

__attribute__((visibility("hidden")))
@interface LMPreferencesTableDataSource : ALApplicationTableDataSource<ALValueCellDelegate> {
@private
    __weak LMApplicationListController *_controller;
}

- (id)initWithController:(LMApplicationListController *)controller;
@end

@implementation LMPreferencesTableDataSource
- (id)initWithController:(LMApplicationListController *)controller {
    if ((self = [super init])) {
        _controller = controller;
    }
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[ALValueCell class]]) {
        [cell setDelegate:self];
        [cell loadValue:[_controller valueForCellAtIndexPath:indexPath]];
    }
    return cell;
}

- (void)valueCell:(ALValueCell *)valueCell didChangeToValue:(id)newValue {
    [_controller cellAtIndexPath:[self.tableView indexPathForCell:valueCell] didChangeToValue:newValue];
}

@end

@implementation LMApplicationListController {
    LMPreferencesTableDataSource * _dataSource;
    LMSettings * _settings;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame: self.view.bounds style: UITableViewStyleGrouped];
        _tableView.rowHeight = 44;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorInset = (UIEdgeInsets){0, 15, 0, 15};
        _tableView.delegate = self;
        [self.view addSubview: _tableView];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"应用列表";

    _settings = [LMSettings fromDictionary:[[NSMutableDictionary  alloc] initWithContentsOfFile:settingFilePath]];

    _dataSource = [[LMPreferencesTableDataSource alloc] initWithController:self];
    NSMutableArray * _descriptors = [@[] mutableCopy];
    NSArray * descriptors = [ALApplicationTableDataSource standardSectionDescriptors];
    for (int i = 0; i < descriptors.count; i++) {
        NSMutableDictionary * _dscriptor = [[descriptors objectAtIndex: i] mutableCopy];
        [_dscriptor setValue:@"ALSwitchCell" forKey:ALSectionDescriptorCellClassNameKey];
        if (0 == i) {
            [_dscriptor setValue:@"用户已安装" forKey:ALSectionDescriptorTitleKey];
            [_dscriptor setValue:@"isSystemApplication = FALSE" forKey:ALSectionDescriptorPredicateKey];
        } else {
            [_dscriptor setValue:@"系统已安装" forKey:ALSectionDescriptorTitleKey];
            [_dscriptor setValue:@"isSystemApplication = TRUE" forKey:ALSectionDescriptorPredicateKey];
        }
        [_descriptors addObject:_dscriptor];
    }
    [_dataSource setSectionDescriptors: _descriptors];
    self.tableView.dataSource = _dataSource;
}

- (void)viewWillAppear: (BOOL)animated {
    [super viewWillAppear: animated];
    _dataSource.tableView = self.tableView;
    [self.tableView reloadData];
}

- (void)viewWillDisappear: (BOOL)animated {
    [super viewWillDisappear: animated];
    _dataSource.tableView = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)cellAtIndexPath:(NSIndexPath *)indexPath didChangeToValue:(id)newValue {
    id cellDescriptor = [_dataSource cellDescriptorForIndexPath:indexPath];
    if ([cellDescriptor isKindOfClass:[NSString class]]) {
        LMApplicationSetting * targetApplicationSetting = nil;
        for (LMApplicationSetting * applicationSetting in _settings.applicationSettingList) {
            if ([applicationSetting.identifier isEqualToString: cellDescriptor]) {
                applicationSetting.isEnable = [newValue boolValue];
                targetApplicationSetting = applicationSetting;
                break;
            }
        }

        if (!targetApplicationSetting) {
            targetApplicationSetting = [LMApplicationSetting new];
            targetApplicationSetting.isEnable = [newValue boolValue];
            targetApplicationSetting.identifier = [cellDescriptor copy];
            targetApplicationSetting.name = [[[[ALApplicationList sharedApplicationList] applications] valueForKey: cellDescriptor] copy];
            NSMutableArray *applicationSettingList = [_settings.applicationSettingList mutableCopy];
            [applicationSettingList addObject:targetApplicationSetting];
            _settings.applicationSettingList = [applicationSettingList copy];
        }
        [[_settings toDictionary] writeToFile:settingFilePath atomically:YES];
    }
}

- (id)valueForCellAtIndexPath:(NSIndexPath *)indexPath {
    id cellDescriptor = [_dataSource cellDescriptorForIndexPath:indexPath];
    if ([cellDescriptor isKindOfClass:[NSString class]]) {
        for (LMApplicationSetting * applicationSetting in _settings.applicationSettingList) {
            if ([applicationSetting.identifier isEqualToString: cellDescriptor]) {
                return @(applicationSetting.isEnable);
            }
        }
    }
    return @(NO);
}

@end