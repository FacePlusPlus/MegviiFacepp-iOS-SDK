//
//  MarkVideoViewController.h
//  Test
//
//  Created by 张英堂 on 16/4/20.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MGBaseKit/MGBaseKit.h>
#import "MGFacepp.h"

/**
 *  视频流检测---OpenGLES 版本
 */
@interface MarkVideoViewController : UIViewController

@property (nonatomic, strong) MGFacepp *markManager;

@property (nonatomic, strong) MGVideoManager *videoManager;

@property (nonatomic, assign) CGRect detectRect;
@property (nonatomic, assign) CGSize videoSize;

@property (nonatomic, assign) BOOL debug;
@property (nonatomic, assign) BOOL show3D;
@property (nonatomic, assign) BOOL faceInfo;


@property (nonatomic, assign) int pointsNum;

@end
