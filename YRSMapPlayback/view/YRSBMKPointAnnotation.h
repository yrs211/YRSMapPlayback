//
//  YRSBMKPointAnnotation.h
//  YRSMapPlayback
//
//  Created by 七宗罪 on 16/7/8.
//  Copyright © 2016年 七宗罪. All rights reserved.
//

#import <BaiduMapAPI_Map/BMKMapComponent.h>

@interface YRSBMKPointAnnotation : BMKPointAnnotation
/**判断类型区别起点还是终点*/
@property(assign,nonatomic) NSInteger  type;
@end
