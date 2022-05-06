//
// Created by my on 2022/4/21.
//

#import "LMMapViewController.h"
#import <MapKit/MapKit.h>

@interface CLLocationManager()
+ (void)setAuthorizationStatus:(bool)arg1 forBundle:(id)arg2;
+ (void)setAuthorizationStatus:(bool)arg1 forBundleIdentifier:(id)arg2;
@end

@interface MKMapView(ZOOM)
@property (nonatomic) NSUInteger zoomLevel;
// 缩放级别3-20
- (void)setZoomLevel:(NSUInteger)zoomLevel animated:(BOOL)animated;
@end

@implementation MKMapView(ZOOM)
- (void)setZoomLevel:(NSUInteger)zoomLevel {
    [self setZoomLevel:zoomLevel animated:NO];
}

- (NSUInteger)zoomLevel {
    return round(log2(360 * (((double)self.frame.size.width/256) / self.region.span.longitudeDelta)));
}

- (void)setZoomLevel:(NSUInteger)zoomLevel animated:(BOOL)animated {
    MKCoordinateSpan span = MKCoordinateSpanMake(0,
            360 / pow(2, (double)zoomLevel) * (double)self.frame.size.width / 256);
    [self setRegion:(MKCoordinateRegionMake(self.centerCoordinate, span)) animated:animated];
}
@end

@interface LMMapViewController() <MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@end

@implementation LMMapViewController {
    MKMapView * _mapView;
    CLLocationManager * _locationManager;
    UIButton * _locationButton;
    UITableView * _tableView;
    UISearchBar * _searchBar;
    NSArray * _searchList;
    MKLocalSearch * _search;
}

- (void)_initMapView {
    _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mapView.delegate = self;
    _mapView.mapType = MKMapTypeStandard;
    _mapView.showsScale = YES;
    _mapView.showsTraffic = YES;
    _mapView.showsUserLocation = YES;
    _mapView.userTrackingMode = MKUserTrackingModeNone;
    [self.view addSubview: _mapView];
}

- (void)_initLocationManager {
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.distanceFilter = 100;

    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.backgroundColor = UIColor.whiteColor;
    _locationButton.layer.cornerRadius = 6;
    _locationButton.clipsToBounds = true;
    _locationButton.frame = (CGRect){20, self.view.bounds.size.height - 52, 32, 32};
    [_locationButton addTarget:self action:@selector(touchLocationButton) forControlEvents:UIControlEventTouchUpInside];
    [_locationButton setImage:[UIImage imageWithContentsOfFile: @"/Library/PreferenceBundles/LocationManager.bundle/icon_current_location.png"]
                     forState:UIControlStateNormal];
    [self.view addSubview: _locationButton];
}

- (void)_initSearchBarAndTableView {
    _tableView = [[UITableView alloc] initWithFrame: self.view.bounds style: UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.whiteColor;
    _tableView.rowHeight = 44;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView.separatorInset = (UIEdgeInsets){0, 15, 0, 15};
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.frame = (CGRect){15, 0, self.view.bounds.size.width - 30, self.view.bounds.size.height - 30};
    _tableView.alpha = 0;
    _tableView.tableFooterView = [UIView new];
    [self.view addSubview: _tableView];

    _searchBar = [[UISearchBar alloc] init];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"搜索想要的地点";
    _searchBar.showsCancelButton = YES;
    for (UIView * subView in _searchBar.subviews) {
        for (UITextField *  sSubView in subView.subviews) {
            // 移除背景，防止出现黑线
            if ([sSubView isKindOfClass: NSClassFromString(@"UISearchBarBackground")]) [sSubView removeFromSuperview];
            // 设置字体颜色
            if ([sSubView isKindOfClass: [UITextField class]]) sSubView.textColor = UIColor.darkGrayColor;
        }
    }
    self.navigationItem.titleView = _searchBar;
}

- (void)touchLocationButton {
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
            [CLLocationManager setAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways forBundleIdentifier: [[NSBundle mainBundle] bundleIdentifier]];
            break;
        default: break;
    }
    [_locationManager startUpdatingLocation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self _initMapView];
    [self _initSearchBarAndTableView];
    [self _initLocationManager];
    self.navigationItem.leftBarButtonItem = [UIBarButtonItem new];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1), dispatch_get_main_queue(), ^{
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusNotDetermined:
                [CLLocationManager setAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways forBundleIdentifier: [[NSBundle mainBundle] bundleIdentifier]];
                break;
            default: break;
        }
        [self->_locationManager startUpdatingLocation];
    });

    if (_location && CLLocationCoordinate2DIsValid(_location.coordinate)) {
        MKPointAnnotation * annotation = [MKPointAnnotation new];
        annotation.coordinate = _location.coordinate;
        annotation.title = _location.name;
        annotation.subtitle = _location.detail;
        [_mapView addAnnotation:annotation];
    }
}

#pragma - locationManager Delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.count) {
        CLLocation * location = locations.firstObject;
        [_mapView setZoomLevel:13];
        [_mapView setCenterCoordinate:location.coordinate animated:YES];
        [_locationManager stopUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"didFailWithError" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController: alert animated: YES completion: nil];
}

#pragma - mapView Delegate

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view isKindOfClass:[MKUserLocationView class]]) return ;
    [_searchBar endEditing:YES];
    UIAlertAction * deleteAction = [UIAlertAction actionWithTitle:@"删除"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {
                                                              [mapView removeAnnotation:view.annotation];
                                                          }];


    UIAlertAction * saveAction = [UIAlertAction actionWithTitle:@"保存"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            MKPointAnnotation * annotation = (MKPointAnnotation *)view.annotation;
                                                            NSMutableDictionary * saveDict = [
                                                                    @{
                                                                            @"location": @{
                                                                                    @"latitude": @(annotation.coordinate.latitude),
                                                                                    @"longitude": @(annotation.coordinate.longitude)
                                                                            },
                                                                            @"name": annotation.title,
                                                                            @"detail": annotation.subtitle
                                                                    } mutableCopy];

                                                            if (self.completion) self.completion(saveDict);
                                                        }];

    UIAlertAction * cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:nil
                                                                       preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:saveAction];
    [alertController addAction:deleteAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma - tableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _searchList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: @"CELL"];
        cell.detailTextLabel.textColor = UIColor.lightGrayColor;
        cell.detailTextLabel.font = [UIFont systemFontOfSize:10];
    }
    MKMapItem * item = [_searchList objectAtIndex: indexPath.row];
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ %@", item.placemark.administrativeArea, item.placemark.locality, item.placemark.subLocality];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MKMapItem * item = [_searchList objectAtIndex: indexPath.row];
    MKPointAnnotation * annotation = [MKPointAnnotation new];
    annotation.coordinate = item.placemark.coordinate;
    annotation.title = item.name;
    annotation.subtitle = [NSString stringWithFormat:@"%@ %@ %@", item.placemark.administrativeArea, item.placemark.locality, item.placemark.subLocality];

    [_mapView addAnnotation: annotation];
    [_mapView setCenterCoordinate:item.placemark.coordinate animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [UIView animateWithDuration:0.25 animations:^{
        tableView.alpha = 0.0;
    }];
}

#pragma - search
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar endEditing:YES];
    [self.navigationController popViewControllerAnimated: YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self search:searchText];
    if (_tableView.alpha == 0 && searchText.length) {
        [UIView animateWithDuration:0.25 animations:^{
            self->_tableView.alpha = 1;
        }];
    } else if (!searchText.length) {
        [UIView animateWithDuration:0.25 animations:^{
            self->_tableView.alpha = 0;
        }];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self search:searchBar.text];
}

- (void)search: (NSString *)searchText {
    [_search cancel];
    MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = searchText;
    request.region = _mapView.region;
    _search = [[MKLocalSearch alloc] initWithRequest: request];
    __weak typeof(self) _wself = self;
    [_search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        __strong typeof(_wself) sself = _wself;
        if (error == nil) {
            sself->_searchList = response.mapItems;
            [sself->_tableView reloadData];
        }
    }];
}

@end
