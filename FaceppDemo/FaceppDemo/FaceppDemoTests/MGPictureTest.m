//
//  MGPictureTest.m
//  FaceppDemo
//
//  Created by Megvii on 2017/7/19.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MGFacepp.h"
#import "MGFaceInfo.h"
#import "MGHeader.h"

@interface MGPictureTest : XCTestCase
@property (nonatomic, strong) MGFacepp *facepp;
@end

@implementation MGPictureTest

- (void)setUp {
    [super setUp];
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    _facepp = [[MGFacepp alloc] initWithModel:modelData
                                faceppSetting:^(MGFaceppConfig *config) {
                                    config.orientation = 0;
                                }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    [self detectImage:@"background.png"];
    [self detectImage:@"81_points_position.jpg"];
}

- (void)detectImage:(NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    MGImageData *imageData = [[MGImageData alloc] initWithImage:image];
    [_facepp beginDetectionFrame];
    
    NSDate *t1 = [NSDate date];
    NSArray *faceArray = [_facepp detectWithImageData:imageData];
    NSDate *t2 = [NSDate date];
    NSTimeInterval interval = [t2 timeIntervalSinceDate:t1];
    NSLog(@"detect time = %f",interval * 1000);
    
    [_facepp endDetectionFrame];
    [imageData releaseImageData];
    
    if (faceArray.count > 0) {
        MGLog(@"人脸数量 %@ ：%lu", name, (unsigned long)faceArray.count);
        MGFaceInfo *faceInfo = faceArray[0];
        [_facepp GetGetLandmark:faceInfo isSmooth:NO pointsNumber:81];
    } else {
        MGLog(@"%@ 未检测出人脸",name);
        XCTFail(@"未检测出人脸");
    }
}

- (void)testCompare {
    UIImage *image1 = [UIImage imageNamed:@"background.png"];
    UIImage *image2 = [UIImage imageNamed:@"81_points_position.jpg"];
    NSData *data1;
    NSData *data2;  
    
    // image1
    MGImageData *imageData = [[MGImageData alloc] initWithImage:image1];
    [_facepp beginDetectionFrame];
    
    NSArray *face = [_facepp detectWithImageData:imageData];
    if (face.count > 0) {
        MGFaceInfo *faceInfo = face[0];
        BOOL success = [_facepp GetFeatureData:faceInfo];
        if (success) {
            data1 = faceInfo.featureData;
        } else {
            XCTFail(@"获取人脸特征失败");
        }
    } else {
        XCTFail(@"未检测出人脸");
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
        } else {
            XCTFail(@"获取人脸特征失败");
        }
    } else {
        NSLog(@"未检测到人脸");
    }
    [_facepp endDetectionFrame];
    
    CGFloat like = [_facepp faceCompareWithFeatureData:data1 featureData2:data2];
    NSLog(@"相似度：%.2f",like);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
