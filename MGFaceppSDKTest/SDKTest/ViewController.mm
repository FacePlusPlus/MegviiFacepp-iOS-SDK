//
//  ViewController.m
//  SDKTest
//
//  Created by 张英堂 on 2017/1/10.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "ViewController.h"
#import "../../MGFacepp/MGFacepp/MGFacepp.h"
#import "../../MGFacepp/MGFacepp/MGFaceppConfig.h"
#import "../../MGFacepp/MGFacepp/MGFaceppCommon.h"
#import "../../MGFacepp/MGFacepp/MGAlgorithmInfo.h"

@interface ViewController ()
@property (nonatomic, strong) MGFacepp *facepp;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:KMGFACEMODELTYPE];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    MGAlgorithmInfo *sdkInfo = [MGFacepp getSDKAlgorithmInfoWithModel:modelData];

    NSLog(@"\n************\nSDK 功能列表: %@\n是否需要联网授权: %d\n版本号:%@\n过期时间:%@ \n************", sdkInfo.SDKAbility, sdkInfo.needNetLicense, sdkInfo.version, sdkInfo.expireDate);
    
    _facepp = [[MGFacepp alloc] initWithModel:modelData
                                faceppSetting:^(MGFaceppConfig *config) {
                                    [config setOrientation:0];
                                }];
    
}

- (IBAction)detectAction:(id)sender {
    UIImage *image = [UIImage imageNamed:@"3.jpg"];
    MGImageData *imageData = [[MGImageData alloc] initWithImage:image];

    [_facepp beginDetectionFrame];
    
    NSArray *faceArray = [_facepp detectWithImageData:imageData];
    if (faceArray.count > 0) {
        NSLog(@"检测到人脸，数量:%zi", faceArray.count);
        MGFaceInfo *face = faceArray[0];
        [_facepp GetAttributeAgeGenderStatus:face];
        NSLog(@"年龄：%.2f", face.age);
    } else {
        NSLog(@"3.jpg 未检测到人脸");
    }
    
    [_facepp endDetectionFrame];
}

- (IBAction)compareAction:(id)sender {
    UIImage *image1 = [UIImage imageNamed:@"3.jpg"];
    UIImage *image2 = [UIImage imageNamed:@"2.png"];
    NSData *data1, *data2;
    
    // image1
    MGImageData *imageData = [[MGImageData alloc] initWithImage:image1];
    [_facepp beginDetectionFrame];
    
    NSArray *face = [_facepp detectWithImageData:imageData];
    if (face.count > 0) {
        MGFaceInfo *faceInfo = face[0];
        BOOL success = [_facepp GetFeatureData:faceInfo];
        if (success) {
            data1 = faceInfo.featureData;
        }
    } else {
        NSLog(@"3.jpg 未检测到人脸");
    }
    [_facepp endDetectionFrame];
    
    // image2
    MGImageData *imageData2 = [[MGImageData alloc] initWithImage:image2];
    [_facepp beginDetectionFrame];
    
    NSArray *face2 = [_facepp detectWithImageData:imageData2];
    if (face.count > 0) {
        MGFaceInfo *faceInfo2 = face2[0];
        BOOL success = [_facepp GetFeatureData:faceInfo2];
        if (success) {
            data2 = faceInfo2.featureData;
        }
    } else {
        NSLog(@"2.png 未检测到人脸");
    }
    [_facepp endDetectionFrame];
    
    CGFloat like = [_facepp faceCompareWithFeatureData:data1 featureData2:data2];
    NSLog(@"相似度：%.2f",like);
}


@end
