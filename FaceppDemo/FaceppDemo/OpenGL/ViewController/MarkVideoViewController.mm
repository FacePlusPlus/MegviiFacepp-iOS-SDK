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
#import "MGFaceContrast.h"
#import "MGFaceContrastModel.h"
#import "MGFileManager.h"

#define RETAINED_BUFFER_COUNT 6

@interface MarkVideoViewController ()<MGVideoDelegate>
{
    dispatch_queue_t _detectImageQueue;
    dispatch_queue_t _drawFaceQueue;
}

@property (nonatomic, strong) MGOpenGLView *previewView;
@property (nonatomic, strong) UILabel *debugMessageView;

@property (nonatomic, assign) BOOL hasVideoFormatDescription;
@property (nonatomic, strong) MGOpenGLRenderer *renderer;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, assign) int orientation;

@property (nonatomic, strong) NSArray *models;
@property (nonatomic, assign) BOOL showFaceContrastVC;
@property (nonatomic, strong) NSMutableSet *labels;
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
    _models = nil;
    [self.videoManager startRecording];
    [self setUpCameraLayer];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.motionManager stopAccelerometerUpdates];
    [self.videoManager stopRunning];
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
    
    if (self.faceContrast) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 68, 68)];
        imageView.image = [UIImage imageNamed:@"regist"];
        imageView.center = CGPointMake(self.view.center.x, self.view.frame.size.height - imageView.frame.size.height/2 - 80);
        [self.view addSubview:imageView];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:imageView.bounds];
        btn.center = imageView.center;
        [btn setTitle:@"点击注册" forState:UIControlStateNormal];
        [btn setTitle:@"点击注册" forState:UIControlStateHighlighted];
        btn.titleLabel.font = [UIFont systemFontOfSize:14];
        [btn addTarget:self action:@selector(registBtnAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}

- (void)registBtnAction{
    _showFaceContrastVC = YES;
}

- (void)showfaceContrastVC:(NSArray *)currentModels{
    MGFaceContrast *vc = [MGFaceContrast storyboardInstance];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:currentModels];
    [arr addObjectsFromArray:self.models];
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
                CVPixelBufferRef renderedPixelBuffer = [weakSelf.renderer copyRenderedPixelBuffer:sampleBuffer faceModelArray:modelArray drawLandmark:!self.faceContrast];
                
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
                
                NSMutableArray *mutableArr = [NSMutableArray array];
                for (int i = 0; i < faceModelArray.count; i ++) {
                    MGFaceInfo *faceInfo = faceModelArray.faceArray[0];
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
                    if (self.faceContrast) {
                        [self.markManager GetFeatureData:faceInfo];
                        MGFaceContrastModel *model = [[MGFaceContrastModel alloc] initWithSampleBuffer:detectSampleBufferRef faceInfo:faceInfo];
                        [mutableArr addObject:model];
                    }
                }
                if (self.faceContrast && mutableArr.count > 0) {
                    // 与数据库对比
                    NSMutableArray *showModels = [NSMutableArray array];
                    for (MGFaceContrastModel *model in mutableArr) {
                        float faceSimilarity = 0.0;
                        MGFaceContrastModel *maybeModel;
                        for (MGFaceContrastModel *oldModel in self.models) {
                            float f = [self.markManager faceCompareWithFeatureData:model.feature featureData2:oldModel.feature];
                            if (faceSimilarity < f) {
                                faceSimilarity = f;
                                maybeModel = oldModel;
                            }
                        }
                        if (faceSimilarity > 0.7) {
                            model.maybeName = maybeModel.name;
                            [showModels addObject:model];
                        }
                    }
                    
                    // 在界面上显示 人名
                    NSMutableSet *tempArr = [NSMutableSet set];
                    for (MGFaceContrastModel *model in showModels) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UILabel *label;
                            for (UILabel *oldLabel in self.labels) {
                                if (oldLabel.tag == model.trackID) {
                                    label = oldLabel;
                                    break;
                                }
                            }
                            if (label) {
                                label.center = model.center;
                                [tempArr addObject:label];
                            } else {
                                label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
                                label.textAlignment = NSTextAlignmentCenter;
                                label.text = model.maybeName;
                                label.textColor = [UIColor whiteColor];
                                label.center = model.center;
                                label.tag = model.trackID;
                                [self.view addSubview:label];
                                [tempArr addObject:label];
                            }
                        });
                    }
                    for (UILabel *oldLabel in self.labels) {
                        if (![tempArr containsObject:oldLabel]) {
                            [oldLabel removeFromSuperview];
                        }
                    }
                    
                    [self.labels removeAllObjects];
                    self.labels = tempArr;
                }
                if (_showFaceContrastVC) {
                    _showFaceContrastVC = NO;
                    for (MGFaceContrastModel *model in mutableArr) {
                        [model getName];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showfaceContrastVC:mutableArr];
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
- (NSArray *)models{
    if (!_models) {
        _models = [MGFileManager getModels];
    }
    if (!_models) {
        _models = @[];
    }
    return _models;
}

- (NSMutableSet *)labels{
    if (!_labels) {
        _labels = [NSMutableSet set];
    }
    return _labels;
}


@end
