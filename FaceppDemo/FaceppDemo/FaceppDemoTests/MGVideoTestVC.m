//
//  MGVideoTestVC.m
//  FaceppDemo
//
//  Created by Megvii on 2017/7/20.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGVideoTestVC.h"
#import "VideoBufferReader.h"
#import "MGFacepp.h"
#import "MGFaceModelArray.h"

@interface MGVideoTestVC () <VideoBufferReaderDelegate>
@property (nonatomic, strong) VideoBufferReader *videoReader;
@property (nonatomic, strong) dispatch_queue_t detectQueue;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) MGFacepp *facepp;
@property (nonatomic, strong) NSDate *t1, *t2;
@property (nonatomic, assign) int min_face_size;
@end

@implementation MGVideoTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _videoReader = [[VideoBufferReader alloc] initWithDelegate:self];
    _detectQueue = dispatch_queue_create("com.megvii.detect", DISPATCH_QUEUE_SERIAL);
    _videoQueue = dispatch_queue_create("com.megvii.video", DISPATCH_QUEUE_SERIAL);
    
    _min_face_size =170;
    [self start];
}

- (void)start {
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    int width = 480;
    int height= 640;
    
    MGDetectROI detectROI = MGDetectROIMake(0, 0, 0, 0);
    CGFloat angeleW = width * 0.8;
    CGFloat angeleL = (width - angeleW) / 2;
    CGFloat angeleT = (height - angeleW) / 2;
    detectROI = MGDetectROIMake(angeleT, angeleL, angeleW+angeleT, angeleW+angeleL);
    
    _facepp = [[MGFacepp alloc] initWithModel:modelData
                                faceppSetting:^(MGFaceppConfig *config) {
                                    config.orientation = 0;
                                    config.minFaceSize = 40;
                                    config.detectionMode = MGFppDetectionModeTrackingFast;
                                }];
    [_facepp updateFaceppSetting:^(MGFaceppConfig *config) {
        NSLog(@"track min_face_size = %d",_min_face_size);
        config.minFaceSize = _min_face_size;
    }];
    dispatch_async(_videoQueue, ^{
//        [_videoReader startReading:@"1.m4v"];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)track:(CMSampleBufferRef)sampleBuffer {
    if (MGMarkWorking == _facepp.status) {
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
                
                [_videoReader cancelReading];
            }
            
            
//            MGFaceModelArray *faceModelArray = [[MGFaceModelArray alloc] init];
//            faceModelArray.faceArray = [NSMutableArray arrayWithArray:tempArray];
//            faceModelArray.getFaceInfo = NO;
//            
//            for (int i = 0; i < faceModelArray.count; i ++) {
//                MGFaceInfo *faceInfo = faceModelArray.faceArray[i];
//                [_facepp GetGetLandmark:faceInfo isSmooth:YES pointsNumber:81];
//            }
            
            
            [_facepp endDetectionFrame];
            
            [imageData releaseImageData];
        }
    });
    
    if (detectSampleBufferRef) {
        CFRelease(detectSampleBufferRef);
    }
}



#pragma mark - VideoBufferReaderDelegate

- (void)bufferReader:(VideoBufferReader *)reader didFinishReadingAsset:(AVAsset *)asset{
    NSLog(@"didFinishReadingAsset %@", asset);
    _t2 = nil;
    _t1 = nil;
    NSLog(@"track time : 未检出");
    [self reTest];
}

- (void)bufferReader:(VideoBufferReader *)reader didGetNextVideoSample:(CMSampleBufferRef)bufferRef {
    @synchronized(self) {
        [self track:bufferRef];
    }
}

- (void)bufferReader:(VideoBufferReader *)reader didGetErrorRedingSample:(NSError *)error{
    NSLog(@"decoding error %@", error);
}

- (void)bufferReaderDidCancelled {
    [self reTest];
}

- (void)reTest {
    if (_min_face_size > 40) {
        _min_face_size --;
        [self start];
    }
}

@end
