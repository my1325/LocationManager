//
// Created by my on 2022/4/22.
//

#import "LMRootViewController.h"
#import "LMModels.h"
#import "LMMapViewController.h"
#import "LMApplicationListController.h"

#ifndef appList
#define appList [ALApplicationList sharedApplicationList]
#endif

@interface LMSwitch: UISwitch
@property (nonatomic, strong) id userInfo;
@end

@implementation LMSwitch
@end

@interface LMRootViewController()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) LMSettings * settings;
@property (nonatomic, strong) UITableView * tableView;
@end

@implementation LMRootViewController {
    UIImage * _defaultImage;
//    NSMutableArray * _iconsLoadQueue;
//    OSSpinLock _spinLock;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame: self.view.bounds style: UITableViewStyleGrouped];
        _tableView.rowHeight = 44;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorInset = (UIEdgeInsets){0, 15, 0, 15};
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [self.view addSubview: _tableView];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _defaultImage = [appList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:@"com.apple.WebSheet"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iconLoadedFromNotification:) name:ALIconLoadedNotification object:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(clear)];
    self.navigationItem.title = @"LocationManager";
}

- (void)clear {
    [_settings reset];
    [[_settings toDictionary] writeToFile:settingFilePath atomically:YES];
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    NSDictionary * dictionary = [[NSDictionary alloc] initWithContentsOfFile:settingFilePath];
    _settings = [LMSettings fromDictionary:dictionary];
    [self.tableView reloadData];
}

#pragma - tableView dataSource & delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!_settings.isEnable) return 1;
    if (_settings.globalSetting.isEnable) return 2;
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (0 == section) return 1;
    if (1 == section) return _settings.globalSetting.isEnable ? 2 : 1;
    return _settings.applicationSettingList.count + 1;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (0 == section) return @"";
    if (1 == section) return @"全局设置";
    return @"已选择的应用";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: @"CELL"];
        cell.detailTextLabel.textColor = UIColor.lightGrayColor;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    }

    if (0 == indexPath.section || (1 == indexPath.section && 0 == indexPath.row)) {
        LMSwitch * isOn = (LMSwitch *)cell.accessoryView;
        if (!isOn) {
            isOn = [LMSwitch new];
            [isOn addTarget:self action:@selector(_switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        isOn.userInfo = indexPath;
        cell.accessoryView = isOn;
        cell.imageView.image = nil;
        if (0 == indexPath.section) {
            cell.textLabel.text = @"启用插件";
            isOn.on = _settings.isEnable;
        } else {
            cell.textLabel.text = @"启用全局定位";
            isOn.on = _settings.globalSetting.isEnable;
        }
    } else if (1 == indexPath.section) {
        BOOL isSettleGlobalLocation = _settings.globalSetting.location.name.length;
        cell.textLabel.text = isSettleGlobalLocation ? _settings.globalSetting.location.name : @"未设置";
        cell.detailTextLabel.text = isSettleGlobalLocation ? _settings.globalSetting.location.detail : @"去选择";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = nil;
    } else {
        if (0 == indexPath.row) {
            cell.textLabel.text = @"选择";
            cell.detailTextLabel.text = @"";
        } else {
            LMApplicationSetting * applicationSetting = [_settings.applicationSettingList objectAtIndex: indexPath.row - 1];
            cell.textLabel.text = applicationSetting.name;
            cell.detailTextLabel.text = applicationSetting.location.name;
            UIImage * image =  [appList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:applicationSetting.identifier];
            cell.imageView.image = image ? image : _defaultImage;
        }
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0 != indexPath.row || 2 == indexPath.section;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (1 == indexPath.section && 1 == indexPath.row) {
        LMMapViewController * mapViewController = [LMMapViewController new];
        mapViewController.location = _settings.globalSetting.location;
        [mapViewController setCompletion:^(NSDictionary *location) {
            LMGlobalSetting * globalSetting = self->_settings.globalSetting;
            globalSetting.location.name = [location valueForKey:@"name"];
            globalSetting.location.detail = [location valueForKey:@"detail"];
            globalSetting.location.coordinate = (CLLocationCoordinate2D){[[[location valueForKey:@"location"] valueForKey: @"latitude"] doubleValue], [[[location valueForKey:@"location"] valueForKey: @"longitude"] doubleValue]};
            [[self->_settings toDictionary] writeToFile:settingFilePath atomically:YES];
            [self.tableView reloadData];
        }];
        [self.navigationController pushViewController: mapViewController animated: YES];
    } else if (2 == indexPath.section && 0 < indexPath.row) {
        LMApplicationSetting * applicationSetting = [_settings.applicationSettingList objectAtIndex: indexPath.row - 1];
        LMMapViewController * mapViewController = [LMMapViewController new];
        mapViewController.location = applicationSetting.location;
        [mapViewController setCompletion:^(NSDictionary *location) {
            applicationSetting.location.name = [location valueForKey:@"name"];
            applicationSetting.location.detail = [location valueForKey:@"detail"];
            applicationSetting.location.coordinate = (CLLocationCoordinate2D){ [[[location valueForKey:@"location"] valueForKey: @"latitude"] doubleValue],  [[[location valueForKey:@"location"] valueForKey: @"longitude"] doubleValue]};
            [[self->_settings toDictionary] writeToFile:settingFilePath atomically:YES];
            [self.tableView reloadData];
        }];
        [self.navigationController pushViewController: mapViewController animated: YES];
    } else if (2 == indexPath.section && 0 == indexPath.row) {
        LMApplicationListController * applicationListController = [LMApplicationListController new];
        [self.navigationController pushViewController: applicationListController animated: YES];
    }
}

#pragma - action
- (void)_switchValueChanged: (LMSwitch *)isOn {
    NSIndexPath * indexPath = (NSIndexPath *)isOn.userInfo;
    if (0 == indexPath.section) {
        _settings.isEnable = isOn.isOn;
    } else if (1 == indexPath.section) {
        _settings.globalSetting.isEnable = isOn.isOn;
    }
    NSDictionary * dictionary = [_settings toDictionary];
    [dictionary writeToFile:settingFilePath atomically:YES];
    [self.tableView reloadData];
}

- (void)iconLoadedFromNotification:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSString *displayIdentifier = [userInfo objectForKey:ALDisplayIdentifierKey];
    for (NSIndexPath *indexPath in _tableView.indexPathsForVisibleRows) {
        if (2 == indexPath.section && 0 < indexPath.row) {
            NSString *rowDisplayIdentifier = [_settings.applicationSettingList[indexPath.row - 1] identifier];
            if ([rowDisplayIdentifier isEqualToString:displayIdentifier]) {
                UITableViewCell *cell = [_tableView cellForRowAtIndexPath:indexPath];
                UIImageView *imageView = cell.imageView;
                UIImage *image = imageView.image;
                if (!image || (image == _defaultImage)) {
                    imageView.image = [appList iconOfSize:ALApplicationIconSizeSmall forDisplayIdentifier:displayIdentifier];
                    [cell setNeedsLayout];
                }
            }
        }
    }
}
@end

#ifdef appList
#undef appList
#endif