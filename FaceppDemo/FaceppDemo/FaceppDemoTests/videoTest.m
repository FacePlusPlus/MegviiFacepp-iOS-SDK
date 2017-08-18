//
//  videoTest.m
//  FaceppDemo
//
//  Created by Megvii on 2017/7/20.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "VideoBufferReader.h"
#import "MGFacepp.h"
#import "MGFaceModelArray.h"

@interface videoTest : XCTestCase

@property (nonatomic, strong) VideoBufferReader *videoReader;
@property (nonatomic, strong) dispatch_queue_t detectQueue;
@property (nonatomic, strong) MGFacepp *facepp;
@property (nonatomic, strong) NSDate *t1, *t2;

@end

@implementation videoTest

- (void)setUp {
    [super setUp];

    _videoReader = [[VideoBufferReader alloc] initWithDelegate:self];
    _detectQueue = dispatch_queue_create("com.megvii.detect", DISPATCH_QUEUE_SERIAL);
    int width = 480;
    int height= 640;
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    MGDetectROI detectROI = MGDetectROIMake(0, 0, 0, 0);
    CGFloat angeleW = width * 0.8;
    CGFloat angeleL = (width - angeleW) / 2;
    CGFloat angeleT = (height - angeleW) / 2;
    detectROI = MGDetectROIMake(angeleT, angeleL, angeleW+angeleT, angeleW+angeleL);
    
    _facepp = [[MGFacepp alloc] initWithModel:modelData
                                faceppSetting:^(MGFaceppConfig *config) {
                                    config.orientation = 0;
                                    config.detectROI = detectROI;
                                    config.minFaceSize = 150;
                                    config.detectionMode = MGFppDetectionModeTracking;
                                }];
}

- (void)start {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_videoReader startReading:@"1.m4v"];
    });
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    [self start];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)track:(CMSampleBufferRef)sampleBuffer {
    if (MGMarkWorking == _facepp.status) {
        NSLog(@"1");
        return;
    }
    
    CMSampleBufferRef detectSampleBufferRef = NULL;
    CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &detectSampleBufferRef);
    
    /* 进入检测人脸专用线程 */
    dispatch_sync(_detectQueue, ^{
        @autoreleasepool {
            MGImageData *imageData = [[MGImageData alloc] initWithSampleBuffer:detectSampleBufferRef];
            
            [_facepp beginDetectionFrame];
            
            if (!_t1) {
                _t1 = [NSDate date];
            }
            
            NSArray *tempArray = [_facepp detectWithImageData:imageData];
            
            if (tempArray.count > 0) {
                _t2 = [NSDate date];
                double timeUsed = [_t2 timeIntervalSinceDate:_t1] * 1000;
                NSLog(@"track time : %f",timeUsed);
                _t1 = nil;
            }
            
            
            MGFaceModelArray *faceModelArray = [[MGFaceModelArray alloc] init];
            faceModelArray.faceArray = [NSMutableArray arrayWithArray:tempArray];
            faceModelArray.getFaceInfo = NO;
            
            for (int i = 0; i < faceModelArray.count; i ++) {
                MGFaceInfo *faceInfo = faceModelArray.faceArray[i];
                [_facepp GetGetLandmark:faceInfo isSmooth:YES pointsNumber:81];
            }
            
            
            [_facepp endDetectionFrame];
            
            [imageData releaseImageData];
        }
    });
    
    if (detectSampleBufferRef) {
        //        CFRelease(detectSampleBufferRef);
    }
}



#pragma mark - VideoBufferReaderDelegate

- (void)bufferReader:(VideoBufferReader *)reader didFinishReadingAsset:(AVAsset *)asset{
    NSLog(@"didFinishReadingAsset %@", asset);
}

- (void)bufferReader:(VideoBufferReader *)reader didGetNextVideoSample:(CMSampleBufferRef)bufferRef {
    @synchronized(self) {
        [self track:bufferRef];
    }
}

- (void)bufferReader:(VideoBufferReader *)reader didGetErrorRedingSample:(NSError *)error{
    NSLog(@"decoding error %@", error);
}

@end
