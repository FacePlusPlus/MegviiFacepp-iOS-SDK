//
//  MGFaceppConfig.m
//  MGFacepp
//
//  Created by 张英堂 on 2016/12/27.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGFaceppConfig.h"

@interface MGFaceppConfig ()

////** 测试使用 */
@property (nonatomic, assign) float dzt;

@end

@implementation MGFaceppConfig


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.detectionMode = MGFppDetectionModeNormal;
        self.minFaceSize = 100;
        self.interval = 40;
        self.orientation = 0;
        self.pixelFormatType = PixelFormatTypeRGBA;
        
        self.detectROI = MGDetectROIMake(0, 0, 0, 0);
    }
    return self;
}


@end
