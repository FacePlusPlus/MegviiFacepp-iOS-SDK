//
//  MGFaceppTest.m
//  FaceppDemo
//
//  Created by Megvii on 2017/8/30.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MGFacepp.h"

@interface MGFaceppTest : XCTestCase
@property (nonatomic, strong) MGFacepp *facepp;
@property (nonatomic, strong) MGAlgorithmInfo *faceppInfo;
@end

@implementation MGFaceppTest

- (void)setUp {
    [super setUp];
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    _facepp = [[MGFacepp alloc] initWithModel:modelData
                                faceppSetting:^(MGFaceppConfig *config) {
                                    config.orientation = 0;
                                    config.detectionMode = MGFppDetectionModeNormal;
                                }];
    XCTAssertNotNil(_facepp);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}


- (void)testUpdateFaceSetting {
    BOOL result = [_facepp updateFaceppSetting:^(MGFaceppConfig *config) {
        config.minFaceSize = 100;
        config.interval = 40;
        config.detectionMode = MGFppDetectionModeNormal;
        MGDetectROI roi = {0, 0, 0, 0};
        config.detectROI = roi;
        config.pixelFormatType = PixelFormatTypeRGBA;
    }];
    XCTAssertTrue(result);
}

- (void)testGetLandmark {
    MGImageData *imageData = [[MGImageData alloc] initWithImage:[UIImage imageNamed:@"test_one_face.png"]];
    MGFaceInfo *faceInfo = [self getFaceInfo:imageData];
    BOOL result = [_facepp GetGetLandmark:faceInfo isSmooth:NO pointsNumber:81];
    XCTAssertTrue(result);
    [imageData releaseImageData];
}

- (void)testGetAgeGenderStatus{
    if ([_faceppInfo.SDKAbility containsObject:MG_ABILITY_KEY_AGE_GENDER]) {
        MGImageData *imageData = [[MGImageData alloc] initWithImage:[UIImage imageNamed:@"test_one_face.png"]];
        MGFaceInfo *faceInfo = [self getFaceInfo:imageData];
        [imageData releaseImageData];
        BOOL result = [_facepp GetAttributeAgeGenderStatus:faceInfo];
        XCTAssertTrue(result);
        XCTAssert(faceInfo.age > 0);
        XCTAssert(faceInfo.gender == MGFemale);
        
        MGImageData *imageData1 = [[MGImageData alloc] initWithImage:[UIImage imageNamed:@"test_male.jpg"]];
        MGFaceInfo *maleFaceInfo = [self getFaceInfo:imageData1];
        [imageData1 releaseImageData];
        BOOL maleResult = [_facepp GetAttributeAgeGenderStatus:maleFaceInfo];
        XCTAssertTrue(maleResult);
        XCTAssert(maleFaceInfo.age > 0);
        XCTAssert(maleFaceInfo.gender == MGMale);
    }
}

- (void)testCompareFaces {
    if ([_faceppInfo.SDKAbility containsObject:MG_ABILITY_KEY_EXTRACT_FEATURE]) {
        MGImageData *imageData = [[MGImageData alloc] initWithImage:[UIImage imageNamed:@"test_one_face.png"]];
        MGFaceInfo *faceInfo = [self getFaceInfo:imageData];
        BOOL result0 = [_facepp GetFeatureData:faceInfo];
        XCTAssertTrue(result0);
        [imageData releaseImageData];
        
        // 同一个人
        MGImageData *imageData1 = [[MGImageData alloc] initWithImage:[UIImage imageNamed:@"test_one_face.png"]];
        MGFaceInfo *faceInfo1 = [self getFaceInfo:imageData1];
        BOOL result1 = [_facepp GetFeatureData:faceInfo1];
        XCTAssertTrue(result1);
        [imageData1 releaseImageData];
        float score1 = [_facepp faceCompareWithFaceInfo:faceInfo faceInf2:faceInfo1];
        XCTAssert(score1 > 0.9);
        
        // 不同人
        MGImageData *imageData2 = [[MGImageData alloc] initWithImage:[UIImage imageNamed:@"test_male.jpg"]];
        MGFaceInfo *faceInfo2 = [self getFaceInfo:imageData2];
        BOOL result2 = [_facepp GetFeatureData:faceInfo2];
        XCTAssertTrue(result2);
        [imageData2 releaseImageData];
        float score2 = [_facepp faceCompareWithFeatureData:faceInfo.featureData featureData2:faceInfo2.featureData];
        XCTAssert(score2 < 0.5);
    }
}

- (void)testGetVsersion {
    NSString *version = [MGFacepp getVersion];
    BOOL result = [version containsString:@"MegviiFacepp 0.5.0"];
    XCTAssertTrue(result);
}


- (MGFaceInfo *)getFaceInfo:(MGImageData *)imageData {
    [_facepp beginDetectionFrame];
    NSArray *faces = [_facepp detectWithImageData:imageData];
    [_facepp endDetectionFrame];
    XCTAssert(faces.count == 1);
    MGFaceInfo *faceInfo = faces[0];
    return faceInfo;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
