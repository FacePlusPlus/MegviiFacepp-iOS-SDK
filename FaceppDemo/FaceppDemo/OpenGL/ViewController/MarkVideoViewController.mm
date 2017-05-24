//
//  MarkVideoViewController.m
//  Test
//
//  Created by 张英堂 on 16/4/20.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MarkVideoViewController.h"
#import "MGOpenGLView.h"
#import "MGOpenGLRenderer.h"
#import "MGFaceModelArray.h"
#import <CoreMotion/CoreMotion.h>
#import "MGFaceListViewController.h"
#import "MGFaceCompareModel.h"
#import "MGFileManager.h"
#import <MGBaseKit/MGImage.h>

#define RETAINED_BUFFER_COUNT 6

@interface MarkVideoViewController ()<MGVideoDelegate>
{
    dispatch_queue_t _detectImageQueue;
    dispatch_queue_t _drawFaceQueue;
    dispatch_queue_t _compareQueue;
}

@property (nonatomic, strong) MGOpenGLView *previewView;
@property (nonatomic, strong) UILabel *debugMessageView;

@property (nonatomic, assign) BOOL hasVideoFormatDescription;
@property (nonatomic, strong) MGOpenGLRenderer *renderer;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) int orientation;

@property (nonatomic, strong) NSArray *dbModels; // 数据库存储的model
//@property (nonatomic, strong) NSMutableArray *oldModels; //
@property (nonatomic, strong) NSMutableDictionary *trackId_name;
@property (nonatomic, strong) NSMutableDictionary *trackId_label;
@property (nonatomic, assign) BOOL showFaceCompareVC;
@property (nonatomic, strong) NSMutableArray *labels;
@property (nonatomic, assign) BOOL isCompareing;
@end

@implementation MarkVideoViewController
-(void)dealloc{
    self.previewView = nil;
    self.renderer = nil;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pointsNum = 81;
        self.orientation = 90;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatView];
    
    _detectImageQueue = dispatch_queue_create("com.megvii.image.detect", DISPATCH_QUEUE_SERIAL);
    _drawFaceQueue = dispatch_queue_create("com.megvii.image.drawFace", DISPATCH_QUEUE_SERIAL);
    _compareQueue = dispatch_queue_create("com.megvii.faceCompare", DISPATCH_QUEUE_SERIAL);
    
    self.renderer = [[MGOpenGLRenderer alloc] init];
    [self.renderer setShow3DView:self.show3D];
    
    if (self.videoManager.videoDelegate != self) {
        self.videoManager.videoDelegate = self;
    }
    if (YES == self.faceInfo) {
        self.debug = YES;
    }
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 0.3f;
    
    AVCaptureDevicePosition devicePosition = [self.videoManager devicePosition];
    
    NSOperationQueue *motionQueue = [[NSOperationQueue alloc] init];
    [motionQueue setName:@"com.megvii.gryo"];
    [self.motionManager startAccelerometerUpdatesToQueue:motionQueue
                                             withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
                                                 
                                                 if (fabs(accelerometerData.acceleration.z) > 0.7) {
                                                     self.orientation = 90;
                                                 }else{
                                                     
                                                     if (AVCaptureDevicePositionBack == devicePosition) {
                                                         if (fabs(accelerometerData.acceleration.x) < 0.4) {
                                                             self.orientation = 90;
                                                         }else if (accelerometerData.acceleration.x > 0.4){
                                                             self.orientation = 180;
                                                         }else if (accelerometerData.acceleration.x < -0.4){
                                                             self.orientation = 0;
                                                         }
                                                     }else{
                                                         if (fabs(accelerometerData.acceleration.x) < 0.4) {
                                                             self.orientation = 90;
                                                         }else if (accelerometerData.acceleration.x > 0.4){
                                                             self.orientation = 0;
                                                         }else if (accelerometerData.acceleration.x < -0.4){
                                                             self.orientation = 180;
                                                         }
                                                     }
                                                     
                                                     if (accelerometerData.acceleration.y > 0.6) {
                                                         self.orientation = 270;
                                                     }
                                                 }
                                             }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    _dbModels = nil;
    [_trackId_name removeAllObjects];
    _trackId_name = nil;
    [_trackId_label removeAllObjects];
    _trackId_label = nil;
    [self.videoManager startRecording];
    [self setUpCameraLayer];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.motionManager stopAccelerometerUpdates];
    [self.videoManager stopRunning];
    for (UILabel *label in self.trackId_label.allValues) {
        [label removeFromSuperview];
    }
}

- (void)stopDetect:(id)sender {
    [self.motionManager stopAccelerometerUpdates];
    NSString *videoPath = [self.videoManager stopRceording];
    NSLog(@"video Path: %@", videoPath);
    
    [self.videoManager stopRunning];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)creatView{
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.title = NSLocalizedString(@"icon_title17", nil);
    UIBarButtonItem *cancenItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"alert_title", nil)
                                                                   style:UIBarButtonItemStyleDone
                                                                  target:self action:@selector(stopDetect:)];
    [self.navigationItem setLeftBarButtonItem:cancenItem];
    
    self.debugMessageView = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.debugMessageView setNumberOfLines:0];
    [self.debugMessageView setTextAlignment:NSTextAlignmentLeft];
    [self.debugMessageView setTextColor:[UIColor greenColor]];
    [self.debugMessageView setFont:[UIFont systemFontOfSize:12]];
    [self.debugMessageView setFrame:CGRectMake(5, 64, 100, 160)];
    
    [self.view addSubview:self.debugMessageView];
    
    if (self.faceCompare) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 68, 68)];
        imageView.image = [UIImage imageNamed:@"regist"];
        imageView.center = CGPointMake(self.view.center.x, self.view.frame.size.height - imageView.frame.size.height/2 - 40);
        [self.view addSubview:imageView];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:imageView.bounds];
        btn.center = imageView.center;
        [btn setTitle:@"点击注册" forState:UIControlStateNormal];
        [btn setTitle:@"点击注册" forState:UIControlStateHighlighted];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        [btn addTarget:self action:@selector(registBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}

- (void)registBtnAction{
    _showFaceCompareVC = YES;
}

- (void)showfaceCompareVC:(NSArray *)currentModels{
    MGFaceListViewController *vc = [MGFaceListViewController storyboardInstance];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:currentModels];
    [arr addObjectsFromArray:self.dbModels];
    vc.models = [NSArray arrayWithArray:arr];
    [self.navigationController pushViewController:vc animated:YES];
}

//加载图层预览
- (void)setUpCameraLayer
{
    if (!self.previewView) {
        self.previewView = [[MGOpenGLView alloc] initWithFrame:CGRectZero];
        self.previewView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        // Front camera preview should be mirrored
        UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        CGAffineTransform transform =  [self.videoManager transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)currentInterfaceOrientation
                                                                                         withAutoMirroring:YES];
        self.previewView.transform = transform;
        
        [self.view insertSubview:self.previewView atIndex:0];
        CGRect bounds = CGRectZero;
        bounds.size = [self.view convertRect:self.view.bounds toView:self.previewView].size;
        self.previewView.bounds = bounds;
        self.previewView.center = CGPointMake(self.view.bounds.size.width/2.0, self.view.bounds.size.height/2.0);
    }
}

/** 根据人脸信息绘制，并且显示 */
- (void)displayWithfaceModel:(MGFaceModelArray *)modelArray SampleBuffer:(CMSampleBufferRef)sampleBuffer{
    @autoreleasepool {
        __unsafe_unretained MarkVideoViewController *weakSelf = self;
        dispatch_async(_drawFaceQueue, ^{
            if (modelArray) {
                CVPixelBufferRef renderedPixelBuffer = [weakSelf.renderer copyRenderedPixelBuffer:sampleBuffer faceModelArray:modelArray drawLandmark:!self.faceCompare];
                
                if (renderedPixelBuffer)
                {
                    [weakSelf.previewView displayPixelBuffer:renderedPixelBuffer];
                    
                    CFRelease(sampleBuffer);
                    CVBufferRelease(renderedPixelBuffer);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.debug) {
                            [weakSelf.debugMessageView setText:[modelArray getDebugString]];
                        }
                    });
                }
            }
        });
    }
}

/** 旋转并且，并且显示 */
- (void)rotateAndDetectSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    if (self.markManager.status != MGMarkWorking) {
        
        CMSampleBufferRef detectSampleBufferRef = NULL;
        CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &detectSampleBufferRef);
        
        /* 进入检测人脸专用线程 */
        dispatch_async(_detectImageQueue, ^{
            
            @autoreleasepool {
                
                if ([self.markManager getFaceppConfig].orientation != self.orientation) {
                    [self.markManager updateFaceppSetting:^(MGFaceppConfig *config) {
                        config.orientation = self.orientation;
                    }];
                }
                
                MGImageData *imageData = [[MGImageData alloc] initWithSampleBuffer:detectSampleBufferRef];
                
                [self.markManager beginDetectionFrame];
                
                NSDate *date1, *date2, *date3;
                date1 = [NSDate date];
                
                NSArray *tempArray = [self.markManager detectWithImageData:imageData];
                
                date2 = [NSDate date];
                double timeUsed = [date2 timeIntervalSinceDate:date1] * 1000;
                
                MGFaceModelArray *faceModelArray = [[MGFaceModelArray alloc] init];
                faceModelArray.getFaceInfo = self.faceInfo;
                faceModelArray.faceArray = [NSMutableArray arrayWithArray:tempArray];
                faceModelArray.timeUsed = timeUsed;
                faceModelArray.get3DInfo = self.show3D;
                [faceModelArray setDetectRect:self.detectRect];
                
                NSMutableDictionary *faces = [NSMutableDictionary dictionary];
                for (int i = 0; i < faceModelArray.count; i ++) {
                    MGFaceInfo *faceInfo = faceModelArray.faceArray[i];
                    [self.markManager GetGetLandmark:faceInfo isSmooth:YES pointsNumber:self.pointsNum];
                    
                    if (self.show3D) {
#warning 0.4.6 以后版本不需要单独调用该方法
                        //                    [self.markManager GetAttribute3D:faceInfo];
                    }
                    if (self.faceInfo && self.debug) {
                        [self.markManager GetAttributeAgeGenderStatus:faceInfo];
                        [self.markManager GetAttributeMouseStatus:faceInfo];
                        [self.markManager GetAttributeEyeStatus:faceInfo];
                        [self.markManager GetMinorityStatus:faceInfo];
                        [self.markManager GetBlurnessStatus:faceInfo];
                    }
                    
                    if (self.faceCompare) {
                        [faces setObject:faceInfo forKey:[NSNumber numberWithInteger:faceInfo.trackID]];
                    }
                }
                
                if (self.faceCompare && faces.count > 0) {
                    UIImage *image = [MGImage imageFromSampleBuffer:detectSampleBufferRef orientation:UIImageOrientationRightMirrored];
                    [self compareFace:faces.allValues image:image];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        NSMutableArray *oldIds = [NSMutableArray array];
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        for (NSNumber *num in self.trackId_name.allKeys) {
                            if ([self.trackId_label.allKeys containsObject:num]) {
                                UILabel *label = [self.trackId_label objectForKey:num];
                                [self setLabelCenter:label faceInfo:[faces objectForKey:num] image:image];
                                label.text = [self.trackId_name objectForKey:num];
                                [oldIds addObject:num];
                                [dict setObject:[self.trackId_label objectForKey:num] forKey:num];
                            } else {
                                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
                                label.textAlignment = NSTextAlignmentCenter;
                                label.textColor = [UIColor colorWithRed:0 green:181/255. blue:232/255. alpha:1];
                                label.font = [UIFont systemFontOfSize:20];
                                [self setLabelCenter:label faceInfo:[faces objectForKey:num] image:image];
                                label.text = [self.trackId_name objectForKey:num];
                                [self.view addSubview:label];
                                [dict setObject:label forKey:num];
                            }
                        }
                        
                        for (NSNumber *num in oldIds) {
                            [self.trackId_label removeObjectForKey:num];
                        }
                        for (UILabel *label in self.trackId_label.allValues) {
                            [label removeFromSuperview];
                        }
                        [self.trackId_label removeAllObjects];
                        self.trackId_label = dict;
                    });
                } else if (self.faceCompare) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        for (UILabel *label in self.trackId_label.allValues) {
                            [label removeFromSuperview];
                        }
                        [self.trackId_label removeAllObjects];
                    });
                }
                
                
                date3 = [NSDate date];
                double timeUsed3D = [date3 timeIntervalSinceDate:date2] * 1000;
                faceModelArray.AttributeTimeUsed = timeUsed3D;
                
                [self.markManager endDetectionFrame];
                
                
//                [imageData releaseImageData];
//                imageData = nil;
                
                [self displayWithfaceModel:faceModelArray SampleBuffer:detectSampleBufferRef];
            }
            
        });
    }
}

- (void)setLabelCenter:(UILabel *)label faceInfo:(MGFaceInfo *)faceInfo image:(UIImage *)image{
    CGPoint point19 = [faceInfo.points[19] CGPointValue];
    CGPoint point26 = [faceInfo.points[26] CGPointValue];
    
    CGPoint center = CGPointMake((point19.y+point26.y)/2 - 1.7*([UIScreen mainScreen].bounds.size.height - image.size.height),
                                 (point19.x+point26.x)/2 - (point19.y-point26.y)*0.8);
    label.center = center;
}

- (void)compareFace:(NSArray *)faceArray image:(UIImage *)image {
    if (faceArray.count < 1) return;
    if (_isCompareing) return;
    _isCompareing = YES;
    
    dispatch_async(_compareQueue, ^{
        // 检测当前帧人脸属性 和数据库人脸对比，获取用户名
        NSMutableDictionary *currentID_name = [NSMutableDictionary dictionary];
        NSMutableArray *currentModels = [NSMutableArray array];
        for (int i = 0; i < faceArray.count; i ++) {
            MGFaceInfo *faceInfo = faceArray[i];
            [self.markManager GetFeatureData:faceInfo];
            MGFaceCompareModel *model = [[MGFaceCompareModel alloc] initWithImage:image faceInfo:faceInfo];
            [currentModels addObject:model];
            
            float faceSimilarity = 0.0;
            NSString *name = @"";
            for (MGFaceCompareModel *oldModel in self.dbModels) {
                float f = [self.markManager faceCompareWithFeatureData:model.feature featureData2:oldModel.feature];
                if (faceSimilarity < f) {
                    faceSimilarity = f;
                    name = oldModel.name;
                }
            }
            if (faceSimilarity > 0.7) {
                [currentID_name setObject:name forKey:[NSNumber numberWithInteger:faceInfo.trackID]];
            }
        }
        
        @synchronized(self.trackId_name){
            [self.trackId_name removeAllObjects];
            self.trackId_name = currentID_name;
        }
        
        if (_showFaceCompareVC) {
            _showFaceCompareVC = NO;
            for (MGFaceCompareModel *model in currentModels) {
                [model getName];
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self showfaceCompareVC:currentModels];
            });
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            _isCompareing = NO;
        });
    });
}


#pragma mark - video delegate
-(void)MGCaptureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    @synchronized(self) {
        if (self.hasVideoFormatDescription == NO) {
            [self setupVideoPipelineWithInputFormatDescription:[self.videoManager formatDescription]];
        }
    
        [self rotateAndDetectSampleBuffer:sampleBuffer];
    }
}

- (void)MGCaptureOutput:(AVCaptureOutput *)captureOutput error:(NSError *)error{
    NSLog(@"%@", error);
    if (error.code == 101) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_message2", nil)
                                                            message:NSLocalizedString(@"alert_message2", nil)
                                                           delegate:nil cancelButtonTitle:NSLocalizedString(@"alert_message3", nil)
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}

#pragma mark-
- (void)setupVideoPipelineWithInputFormatDescription:(CMFormatDescriptionRef)inputFormatDescription
{
    MGLog( @"-[%@ %@] called", NSStringFromClass([self class]), NSStringFromSelector(_cmd) );
    self.hasVideoFormatDescription = YES;
    
    [_renderer prepareForInputWithFormatDescription:inputFormatDescription
                      outputRetainedBufferCountHint:RETAINED_BUFFER_COUNT];
}



#pragma mark - getter setter -
- (NSArray *)dbModels{
    if (!_dbModels) {
        _dbModels = [MGFileManager getModels];
    }
    if (!_dbModels) {
        _dbModels = @[];
    }
    return _dbModels;
}

- (NSMutableArray *)labels{
    if (!_labels) {
        _labels = [NSMutableArray array];
    }
    return _labels;
}

- (NSMutableDictionary *)trackId_name{
    if (!_trackId_name) {
        _trackId_name = [NSMutableDictionary dictionary];
    }
    return _trackId_name;
}

- (NSMutableDictionary *)trackId_label{
    if (!_trackId_label) {
        _trackId_label = [NSMutableDictionary dictionary];
    }
    return _trackId_label;
}

@end
