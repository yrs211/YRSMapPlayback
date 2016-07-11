//
//  YRSMapPlaybackVC.m
//  YRSMapPlayback
//
//  Created by 七宗罪 on 16/7/8.
//  Copyright © 2016年 七宗罪. All rights reserved.
//

#import "YRSMapPlaybackVC.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import "YRSPlaybackModel.h"
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>
#import "YRSBMKPointAnnotation.h"
//当前屏幕宽度
#define kMainScreenWidth [[UIScreen mainScreen] bounds].size.width
//当前屏幕高度
#define kMainScreenHeight [[UIScreen mainScreen] bounds].size.height

//坐标rect 设置
#define RECT(X,Y,W,H) CGRectMake(X, Y, W, H)
@interface YRSMapPlaybackVC ()<BMKMapViewDelegate>
{
    
    
    /**百度地图View*/
    BMKMapView * _mapView;
    
    
    /**经纬度信息数据源*/
    NSMutableArray * _dataArray;
    
    /**百度折线*/
    BMKPolyline * _polyline;
   
    /**获取经纬度数组*/
    CLLocationCoordinate2D * _coors;
    
    /**统计定时器执行次数和数组执行的次数*/
    int _index ;
    
    
    /**回放定时器*/
    NSTimer * _PlayTime ;
    
    /**播放按钮*/
    UIButton  * _playButton;
    
    
    /**当前时间*/
    UILabel *_currentLabel;
    
    /**总时间*/
    UILabel *_totalLabel;
    
    /**播放进度*/
    UISlider *_slider;
    
    /**按钮判断*/
    BOOL  isfite ;

}


@end

@implementation YRSMapPlaybackVC
-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    _mapView.delegate = self;
    
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    
    [_mapView viewWillDisappear];
    _mapView.delegate = nil;
    
    
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
  
  [ self createMapUI];
  [self getLocationData];
 [self initConfiguration];

    isfite = YES;

   
}
//创建进度显示背景
-(void)setPlaybackButtonView{
      // 背景view
    UIView * bgView = [[UIView alloc]init];
    bgView.frame = RECT(0, 0, kMainScreenWidth,60);
    bgView.backgroundColor =  [UIColor colorWithRed:103/255.0 green:104/255.0 blue:98/255.0 alpha:0.5];
    
    //播放按钮
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = RECT(10, 5, 30, 30);
    [_playButton setBackgroundImage:[UIImage imageNamed:@"starting"] forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(setclick:) forControlEvents:UIControlEventTouchUpInside];
    [bgView addSubview:_playButton];
    
    //  里程显示
    UILabel * lable = [[UILabel alloc]init];
    lable.frame = RECT(10, 35, 150, 20);
    lable.font = [UIFont systemFontOfSize:15];
    lable.text =@"总里程:52公里";
    lable.textColor = [UIColor whiteColor];
    [bgView addSubview:lable];
    
    
    //当前时间显示
    _currentLabel = [[UILabel alloc]initWithFrame:CGRectMake(45, 5, 50, 30)];
    _currentLabel.text = @"00:00";
    _currentLabel.font = [UIFont systemFontOfSize:15];
    _currentLabel.textColor = [UIColor whiteColor];
    [bgView addSubview:_currentLabel];
    
    
    //进度条
    _slider = [[UISlider alloc]initWithFrame:CGRectMake(100, 5, kMainScreenWidth-100-60, 30)];
    [_slider addTarget:self action:@selector(timeChange:) forControlEvents:UIControlEventValueChanged];
    _slider.minimumValue=0.2;
    
    //设置初始值
    _slider.value=0.2;
    _slider.maximumValue = _dataArray.count*0.2;
    NSLog(@"%f",_slider.maximumValue);
    _slider.tintColor=[UIColor whiteColor];
    [bgView addSubview:_slider];
    
    
    NSInteger totime=_dataArray.count*0.2;
    //总时间显示
    _totalLabel = [[UILabel alloc]initWithFrame:CGRectMake(kMainScreenWidth-60, 5, 50, 30)];
    _totalLabel.textColor = [UIColor whiteColor];
    _totalLabel.text = [NSString stringWithFormat:@"%02ld:%02ld",totime/60,totime%60];
    _totalLabel.font = [UIFont systemFontOfSize:15];
    
    [bgView addSubview:_totalLabel];

    [self.view addSubview:bgView];
}
#pragma mark-------初始化地图服务---------
-(void)createMapUI{
    
    
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {
        //由于IOS8中定位的授权机制改变 需要进行手动授权
        CLLocationManager  *locationManager = [[CLLocationManager alloc] init];
        //获取授权认证
        [locationManager requestAlwaysAuthorization];
        [locationManager requestWhenInUseAuthorization];
    }
    
    //百度基础地图初始化
    _mapView=[[BMKMapView alloc]initWithFrame:RECT(0, 0, kMainScreenWidth, kMainScreenHeight-64)];;
    _mapView.showMapScaleBar = YES;
    _mapView.delegate = self;
    _mapView.userTrackingMode = BMKUserTrackingModeFollow;//设置定位的状态
    _mapView.mapType = BMKMapTypeStandard;//设定为标准地图
    _mapView.showsUserLocation = YES;//显示定位图层
    _mapView.zoomLevel=17;
    _mapView.trafficEnabled=YES;
    
    _mapView.compassPosition = CGPointMake(40, 40);
    
    CLLocationCoordinate2D coordinate;
    //    coordinate.latitude = [[_carInfo objectForKey:@"lat"] floatValue];
    //    coordinate.longitude = [[_carInfo objectForKey:@"lon"] floatValue];
    
    
    
    coordinate.latitude = 39.92;
    coordinate.longitude = 116.46;
   [_mapView setCenterCoordinate:coordinate];
    [self.view addSubview:_mapView];
    
    
    
}

#pragma mark-------BMKMapViewDelegate 添加标注---------
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation{
    
    
    BMKAnnotationView *newAnnotationView = nil;
    
    if ([annotation isKindOfClass:[YRSBMKPointAnnotation class]]) {
        
        YRSBMKPointAnnotation * yrsAnnotation = (YRSBMKPointAnnotation*)annotation;
        
        //起点位置
        if (yrsAnnotation.type == 0) {
            
            newAnnotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"start"];
            if (newAnnotationView == nil) {
                newAnnotationView= [[BMKPinAnnotationView alloc] initWithAnnotation:yrsAnnotation reuseIdentifier:@"start"];
                
                newAnnotationView.image = [UIImage imageNamed:@"start"];
                newAnnotationView.centerOffset = CGPointMake(0, -(newAnnotationView.frame.size.height * 0.37));
                
                newAnnotationView.draggable = NO;
                newAnnotationView.centerOffset = CGPointMake(0, -1);
                newAnnotationView.calloutOffset = CGPointMake(0, 5);
                newAnnotationView.canShowCallout = YES;
                newAnnotationView.enabled3D = YES;
                
            }
            
            
        }else   //终点位置
            if (yrsAnnotation.type == 1) {
                
                newAnnotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"end"];
                if (newAnnotationView == nil) {
                    newAnnotationView= [[BMKPinAnnotationView alloc] initWithAnnotation:yrsAnnotation reuseIdentifier:@"end"];
                    
                    newAnnotationView.image =[UIImage imageNamed:@"end"];
                    newAnnotationView.centerOffset = CGPointMake(0, -(newAnnotationView.frame.size.height * 0.37));
                    
                    newAnnotationView.draggable = NO;
                    newAnnotationView.centerOffset = CGPointMake(0, -1);
                    newAnnotationView.calloutOffset = CGPointMake(0, 5);
                    newAnnotationView.canShowCallout = YES;
                    newAnnotationView.enabled3D = YES;
                    
                }
                
                
            }
        
    
        return newAnnotationView;
        
    }else if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        
        BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        
        
        
        newAnnotationView.animatesDrop = NO;// 设置该标注点动画显示
        
        newAnnotationView.annotation = annotation;
        
        newAnnotationView.image = [UIImage imageNamed:@"car"];   //把大头针换成别的图片
        
        return newAnnotationView;
    }
    
    return nil;
    
    
}

#pragma mark - -------------获取经纬度数据
- (void)getLocationData
{

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"point" ofType:@"plist"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    NSMutableArray * locationArray = [dictionary objectForKey:@"location"];
    
     _dataArray = [[NSMutableArray alloc]init];
            
            
            for (NSMutableDictionary * mudic in locationArray) {
                
                YRSPlaybackModel * model = [[YRSPlaybackModel alloc]init];
                
                [model setValuesForKeysWithDictionary:mudic];
                
                [_dataArray addObject:model];
            }
    
             [self setMapPoly];
      
            [self setPlaybackButtonView];
}


#pragma mark---------划线代理回调----------
- (BMKOverlayView*)mapView:(BMKMapView *)map viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:1];
        polylineView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        polylineView.lineWidth = 3.0f;
        return polylineView;
    }
    return nil;
}


#pragma mark---------定时器设置标注点的回放----------
-(void)setMapPlayback:(NSTimer*)timer{
    
    //删除前面插入的标注，只显示最后添加的这个

    if (![_mapView.annotations isKindOfClass:[YRSBMKPointAnnotation class]]) {
        
        NSArray *array = [[NSArray alloc] initWithArray:_mapView.annotations];
        [_mapView removeAnnotations:array];
        array = [NSArray arrayWithArray:_mapView.overlays];
        [_mapView removeOverlays:array];
    }
    
    const int  Max  = (int)_dataArray.count;
    
    _index++; //统计运动到那一个经纬度标注
    for (int i = _index; i<_dataArray.count; i++) {
    
        YRSPlaybackModel * model = [_dataArray objectAtIndex:_index];
        _coors[_index].latitude = model.lat.doubleValue;
        _coors[_index].longitude = model.lon.doubleValue;
        
    }
    
    BMKPointAnnotation * antion = [[BMKPointAnnotation alloc]init];
    
    antion.title = @"";
    antion.coordinate = _coors[_index-1];
    [_mapView addAnnotation:antion];
    
    
    //重复再添加一次起点和终点
    YRSBMKPointAnnotation * Annotation = [[YRSBMKPointAnnotation alloc]init];
    Annotation.type =0;
    Annotation.title = @"起点";
    Annotation.coordinate = _coors[0];
    [_mapView addAnnotation:Annotation];
    
    
    Annotation = [[YRSBMKPointAnnotation alloc] init];
    Annotation.type = 1;
    Annotation.title = @"终点";
    Annotation.coordinate = _coors[Max-1];
    [_mapView addAnnotation:Annotation];
    
    
    BMKPolyline  * polyline = [BMKPolyline polylineWithCoordinates:_coors count:Max-1];
    [_mapView addOverlay:polyline];
    
    _slider.value = _index*0.2;
    
    
    NSString * string= [NSString stringWithFormat:@"%0.1f",_slider.value];
    
    NSInteger time = string.integerValue;
    if (_slider.value ==_slider.maximumValue) {
        
        [_playButton setBackgroundImage:[UIImage imageNamed:@"starting"] forState:UIControlStateNormal];
    }
    
    _currentLabel.text = [NSString stringWithFormat:@"%02d:%02d",(int)time/60,(int)time%60];
    
    
    if (_index==_dataArray.count) {
        _index=0;
        isfite = YES;
        [_PlayTime invalidate];
    }
    
    
}
#pragma mark---------初始化地图的时候先划出线条----------
-(void)setMapPoly{
    
        NSArray *array = [NSArray arrayWithArray:_mapView.overlays];
        [_mapView removeOverlays:array];
        
        [_mapView removeAnnotations:array];
        
        //添加折线覆盖物
        array = [NSArray arrayWithArray:_mapView.annotations];
        [_mapView removeAnnotations:array];
        
        const int  Max  = (int)_dataArray.count;
        
        _coors = malloc(Max *sizeof(CLLocationCoordinate2D));
    
        for (int i = 0; i<_dataArray.count; i++) {
          YRSPlaybackModel * model = [_dataArray objectAtIndex:i];
    
            _coors[i].latitude = model.lat.doubleValue;
            _coors[i].longitude = model.lon.doubleValue;
            
        }
    
        _polyline = [BMKPolyline polylineWithCoordinates:_coors count:Max-1];
        [_mapView addOverlay:_polyline];
        
     [self mapViewFitPolyLine:_polyline];
        
        YRSBMKPointAnnotation * antion = [[YRSBMKPointAnnotation alloc]init];
        antion.type =0;
        antion.title = @"起点";
        antion.coordinate = _coors[0];
        [_mapView addAnnotation:antion];
        
        
        antion = [[YRSBMKPointAnnotation alloc] init];
        antion.type = 1;
        antion.title = @"终点";
        antion.coordinate = _coors[Max-1];
        [_mapView addAnnotation:antion];
        
        
        
        [_mapView setCenterCoordinate:_coors[0]]; //起点作为地图中心

    
}


#pragma mark----------------播放按钮点击------------------
-(void)setclick:(UIButton *)button{
    
    if (isfite) {
        
        
        _PlayTime =[NSTimer timerWithTimeInterval:0.2  target:self selector:@selector(setMapPlayback:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_PlayTime forMode:NSDefaultRunLoopMode];
        
        [_PlayTime fire];
        [_playButton setBackgroundImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        isfite = NO;
        
    }else if (isfite==NO) {
        [_playButton setBackgroundImage:[UIImage imageNamed:@"starting"] forState:UIControlStateNormal];
        isfite = YES;
        [_PlayTime invalidate];
    }

}

// 根据polyline设置地图范围
- (void)mapViewFitPolyLine:(BMKPolyline *) polyLine {
    CGFloat ltX, ltY, rbX, rbY;
    if (polyLine.pointCount < 1) {
        return;
    }
    BMKMapPoint pt = polyLine.points[0];
    ltX = pt.x, ltY = pt.y;
    rbX = pt.x, rbY = pt.y;
    for (int i = 1; i < polyLine.pointCount; i++) {
        BMKMapPoint pt = polyLine.points[i];
        if (pt.x < ltX) {
            ltX = pt.x;
        }
        if (pt.x > rbX) {
            rbX = pt.x;
        }
        if (pt.y > ltY) {
            ltY = pt.y;
        }
        if (pt.y < rbY) {
            rbY = pt.y;
        }
    }
    BMKMapRect rect;
    rect.origin = BMKMapPointMake(ltX , ltY);
    rect.size = BMKMapSizeMake(rbX - ltX, rbY - ltY);
    [_mapView setVisibleMapRect:rect];
    _mapView.zoomLevel = _mapView.zoomLevel - 0.3;
}

-(void)timeChange:(UISlider * )selder{
    
    
    _index = _slider.value/0.2;
    
    
    
}

#pragma mark - 初始控制器基础设置
- (void)initConfiguration
{
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navibar-bg"] forBarMetrics:UIBarMetricsDefault];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"行驶回放";
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
