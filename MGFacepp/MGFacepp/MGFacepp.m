//
//  MGFacepp.m
//  LandMask
//
//  Created by Megvii on 16/9/5.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGFacepp.h"
#import "MG_Facepp.h"
#import "MG_Common.h"
#import "MGFaceInfo_Creat.h"
#import "MGAlgorithmInfo_Creat.h"

@interface MGFacepp () {
    MG_FPP_APIHANDLE _apiHandle;
    MG_FPP_IMAGEHANDLE _imageHandle;
}

@property (nonatomic, strong) MGImageData *tempImageData;
@property (nonatomic, assign) BOOL currentFrameIsImage;
@property (nonatomic, assign) BOOL canDetect;
@property (nonatomic, strong, getter = getFaceppConfig) MGFaceppConfig *faceppConfig;
@property (nonatomic, assign) MGPixelFormatType pixelFormatType; // 设置视频流格式，默认 PixelFormatTypeRGBA

@property (nonatomic, assign) int iwidth;
@property (nonatomic, assign) int iHeight;

@end

@implementation MGFacepp

- (instancetype)init {
    self = [super init];
    if (self) {
        [NSException raise:@"提示！" format:@"请使用 MGFacepp initWithModel: 初始化方式！"];
    }
    return self;
}

- (instancetype)initWithModel:(NSData *)modelData maxFaceCount:(NSInteger)maxFaceCount faceppSetting:(void(^)(MGFaceppConfig *config))config {
    if (![MGFacepp isMapSDKBundleID]) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        NSAssert(modelData.length > 0, @"modelData.length == 0");
        if (modelData.length > 0) {
            const void *modelBytes = modelData.bytes;
            MG_RETCODE initCode = mg_facepp.CreateApiHandleWithMaxFaceCount((MG_BYTE *)modelBytes, (MG_INT32)modelData.length, (MG_INT32)maxFaceCount, &_apiHandle);
            NSAssert(MG_RETCODE_OK == initCode, @"modelData 与 SDK 不匹配");
            if (initCode != MG_RETCODE_OK) {
                NSLog(@"[initWithModel:] 初始化失败，modelData 与 SDK 不匹配！，请检查后重试！errorCode:%zi", initCode);
                return nil;
            }
            
            self.faceppConfig = [[MGFaceppConfig alloc] init];
            [self updateFaceppSetting:config];
            
        } else {
            NSLog(@"[initWithModel:] 初始化失败，无法读取 modelData，请检查！");
            return nil;
        }
        
        _status = MGMarkPrepareWork;
    }
    return self;
}

- (instancetype)initWithModel:(NSData *)modelData faceppSetting:(void(^)(MGFaceppConfig *config))config {
    return [self initWithModel:modelData maxFaceCount:0 faceppSetting:config];
}

- (BOOL)updateFaceppSetting:(void(^)(MGFaceppConfig *config))config{
    if (config) {
        config(self.faceppConfig);
        
        self.pixelFormatType = self.faceppConfig.pixelFormatType;
        
        MG_FPP_APICONFIG config;
        mg_facepp.GetDetectConfig(_apiHandle, &config);
        
        MG_RECTANGLE angle;
        angle.left = self.faceppConfig.detectROI.left;
        angle.top = self.faceppConfig.detectROI.top;
        angle.right = self.faceppConfig.detectROI.right;
        angle.bottom = self.faceppConfig.detectROI.bottom;

        config.min_face_size = self.faceppConfig.minFaceSize;
        config.interval = self.faceppConfig.interval;
        config.rotation = self.faceppConfig.orientation;
        config.detection_mode = [self getDetectModel:self.faceppConfig.detectionMode];
        config.roi = angle;
        NSLog(@"%d",config.detection_mode);
        MG_RETCODE code = mg_facepp.SetDetectConfig(_apiHandle, &config);
        if (code == MG_RETCODE_OK) {
            return YES;
        }
    }
    return NO;
}

- (MG_FPP_DETECTIONMODE)getDetectModel:(MGFppDetectionMode)detectionMode{
    MG_FPP_DETECTIONMODE model = MG_FPP_DETECTIONMODE_NORMAL;
    switch (self.faceppConfig.detectionMode) {
        case MGFppDetectionModeDetect:
            model = MG_FPP_DETECTIONMODE_NORMAL;
            break;
        case MGFppDetectionModeTracking:
            NSLog(@"tracking 模式已经废弃，请使用 robust 模式");
//            model = MG_FPP_DETECTIONMODE_TRACKING;
            model = MG_FPP_DETECTIONMODE_TRACKING_ROBUST;
            break;
        case MGFppDetectionModeTrackingFast:
            model = MG_FPP_DETECTIONMODE_TRACKING_FAST;
            break;
        case MGFppDetectionModeTrackingRobust:
            model = MG_FPP_DETECTIONMODE_TRACKING_ROBUST;
            break;
        case MGFppDetectionModeDetectRect:
            model = MG_FPP_DETECTIONMODE_DETECT_RECT;
            break;
        default:
            break;
    }
    return model;
}

- (MG_IMAGEMODE)getImageModel{
    MG_IMAGEMODE tempModel = MG_IMAGEMODE_RGBA;
    switch (self.pixelFormatType) {
        case PixelFormatTypeBGR:
            tempModel = MG_IMAGEMODE_BGR;
            break;
        case PixelFormatTypeRGB:
            tempModel = MG_IMAGEMODE_RGB;
            break;
        case PixelFormatTypeGRAY:
            tempModel = MG_IMAGEMODE_GRAY;
            break;
        case PixelFormatTypeNV21:
            tempModel = MG_IMAGEMODE_NV21;
            break;
        case PixelFormatTypeRGBA:
            tempModel = MG_IMAGEMODE_RGBA;
            break;
        default:
            tempModel = MG_IMAGEMODE_RGBA;
            break;
    }
    return tempModel;
}

#pragma mark -
- (NSArray <MGFaceInfo *>*)detectWithImageData:(MGImageData *)imagedata{
    @synchronized (self) {
        NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:1];
        
        if (nil == imagedata) {
            return returnArray;
        }
        
        int width = imagedata.width;
        int height = imagedata.height;
        
        if (NO == self.canDetect) {
            returnArray = nil;
        } else {
            if (self.status == MGMarkWaiting || self.status == MGMarkPrepareWork) {
                _status = MGMarkWorking;
                
                void *rawData = (unsigned char*)[imagedata getData];
                
                if (YES == imagedata.isUIImage && NULL != _imageHandle) {
                    mg_facepp.ReleaseImageHandle(_imageHandle);
                    _imageHandle = NULL;
                }
                
                if (_imageHandle == NULL) {
                    mg_facepp.CreateImageHandle(width, height, &_imageHandle);
                }
                int faceCount = 0;
                
                MG_RETCODE setimageCode = mg_facepp.SetImageData(_imageHandle, rawData, [self getImageModel]);
                MG_RETCODE DetectCode = mg_facepp.Detect(_apiHandle, _imageHandle, &faceCount);
                if (setimageCode == MG_RETCODE_OK || DetectCode == MG_RETCODE_OK) {
                    NSArray *faceinfoArray = [self getFaceInfoWithFaceCount:faceCount mgApiHandle:_apiHandle];
                    [returnArray addObjectsFromArray:faceinfoArray];
                }
                
            }else if(self.status == MGMarkWorking){
                returnArray = nil;
            }else if(self.status == MGMarkStopped){
                returnArray = nil;
            }
        }
        return returnArray;
    }
}

- (NSInteger)getFaceNumberWithImageData:(MGImageData *)imagedata {
    @synchronized (self) {
        int faceCount = 0;
        if (nil == imagedata) return (NSInteger)faceCount;
        
        _iwidth = imagedata.width;
        _iHeight = imagedata.height;
        
        if (YES == self.canDetect) {
            if (self.status == MGMarkWaiting || self.status == MGMarkPrepareWork) {
                _status = MGMarkWorking;
                
                void *rawData = (unsigned char*)[imagedata getData];
                
                if (YES == imagedata.isUIImage && NULL != _imageHandle) {
                    mg_facepp.ReleaseImageHandle(_imageHandle);
                    _imageHandle = NULL;
                }
                
                if (_imageHandle == NULL) {
                    mg_facepp.CreateImageHandle(_iwidth, _iHeight, &_imageHandle);
                }
                
                MG_RETCODE setimageCode = mg_facepp.SetImageData(_imageHandle, rawData, [self getImageModel]);
                MG_RETCODE DetectCode = mg_facepp.Detect(_apiHandle, _imageHandle, &faceCount);
                if (setimageCode != MG_RETCODE_OK || DetectCode != MG_RETCODE_OK) {
                    faceCount = 0;
                }
                
            } else if(self.status == MGMarkWorking){
                faceCount = 0;
            } else if(self.status == MGMarkStopped){
                faceCount = 0;
            }
        }
        return (NSInteger)faceCount;
    }
}

/* 如果人脸数量超过 1 个，进行人脸关键点检测  */
- (NSArray <MGFaceInfo *>*)getFaceInfoWithFaceCount:(NSInteger)count mgApiHandle:(MG_FPP_APIHANDLE)apiHandle {
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        MG_FACE face;
        mg_facepp.GetFaceInfo(apiHandle, i, &face);
        
        MGFaceInfo *faceModel = [MGFaceInfo modelWithPoint:face.points
                                               pointsCount:MG_LANDMARK_NR
                                                mgFaceInfo:face.rect
                                                confidence:face.confidence];
        faceModel.index = i;
        faceModel.trackID = face.track_id;
        
        [faceModel setProperty:MG_FPP_ATTR_POSE3D MGFACE:face];
        
        [tempArray addObject:faceModel];
    }
    return tempArray;
}

#pragma mark- 特效系列
- (BOOL)GetGetLandmark:(MGFaceInfo *)faceInfo isSmooth:(BOOL)isSmooth pointsNumber:(int)nr{
    @autoreleasepool {
        MG_RETCODE sucessCode = MG_RETCODE_FAILED;
        MG_POINT buff[106] = {};
        sucessCode = mg_facepp.GetLandmark(_apiHandle, faceInfo.index, isSmooth, nr, buff);
        [faceInfo resetPoints:buff pointsCount:nr];
        if (sucessCode == MG_RETCODE_OK) return YES;
        return NO;
    }
}

- (MGDetectRectInfo *)GetRectAtIndex:(int)index isSmooth:(BOOL)isSmooth {
    @autoreleasepool {
        MG_DETECT_RECT detectRect;
        MG_RETCODE sucessCode = MG_RETCODE_FAILED;
        sucessCode = mg_facepp.GetRect(_apiHandle, index, isSmooth, &detectRect);
        if (sucessCode == MG_RETCODE_OK) {
            MGDetectRectInfo *result = [[MGDetectRectInfo alloc] init];
            result.angle = detectRect.angle;
            result.confidence = detectRect.confidence;
            
            NSInteger x = 0;
            NSInteger y = 0;
            NSInteger w = 0;
            NSInteger h = 0;
            x = _iwidth - detectRect.rect.right;
            y = detectRect.rect.top;
            w = detectRect.rect.right - detectRect.rect.left;
            h = detectRect.rect.bottom - detectRect.rect.top;
            // SDK返回方向相对于手机方向逆时针旋转了90度
            switch (detectRect.orient) {
                case MG_left:
                    result.orient = MGOrientationLeft;
                    break;
                case MG_Top:
                    result.orient = MGOrientationUp;
                    break;
                case MG_right:
                    result.orient = MGOrientationRight;
                    break;
                case MG_Bottom:
                    result.orient = MGOrientationDown;
                    break;
                default:
                    break;
            }
        
            result.rect = CGRectMake(x, y, w, h);
            return result;
        } else {
            NSLog(@"获取人脸框失败");
            return nil;
        }
    }
}

- (BOOL)GetAttribute3D:(MGFaceInfo *)faceInfo{
    return [self getFaceAttribute:faceInfo property:MG_FPP_ATTR_POSE3D];
}
- (BOOL)GetAttributeEyeStatus:(MGFaceInfo *)faceInfo{
    return [self getFaceAttribute:faceInfo property:MG_FPP_ATTR_EYESTATUS];
}
- (BOOL)GetAttributeMouseStatus:(MGFaceInfo *)faceInfo{
    return [self getFaceAttribute:faceInfo property:MG_FPP_ATTR_MOUTHSTATUS];
}
- (BOOL)GetAttributeAgeGenderStatus:(MGFaceInfo *)faceInfo{
    return [self getFaceAttribute:faceInfo property:MG_FPP_ATTR_AGE_GENDER];
}
- (BOOL)GetBlurnessStatus:(MGFaceInfo *)faceInfo{
    return [self getFaceAttribute:faceInfo property:MG_FPP_ATTR_BLURNESS];
}
- (BOOL)GetMinorityStatus:(MGFaceInfo *)faceInfo{
    return [self getFaceAttribute:faceInfo property:MG_FPP_ATTR_MINORITY];
}
- (BOOL)getFaceAttribute:(MGFaceInfo *)faceInfo property:(int32_t)property{
    @autoreleasepool {
        MG_FACE face;
        MG_RETCODE sucessCode = mg_facepp.GetAttribute(_apiHandle, _imageHandle, faceInfo.index, property, &face);
        if (sucessCode == MG_RETCODE_OK){
            [faceInfo setProperty:property MGFACE:face];
            return YES;
        }
        return NO;
    }
}

#pragma mark - 人脸比对 相关
- (BOOL)GetFeatureData:(MGFaceInfo *)faceInfo{
    @autoreleasepool {
        int32_t featureDataLength = 0;
        MG_RETCODE returnCode2 = mg_facepp.ExtractFeature(_apiHandle, _imageHandle, faceInfo.index, &featureDataLength);
        if (returnCode2 != MG_RETCODE_OK) return NO;

        float *tempFloat = (float*)malloc(featureDataLength * sizeof(float));
        MG_RETCODE returnCode3 = mg_facepp.GetFeatureData(_apiHandle, tempFloat, featureDataLength);
        
        if (returnCode3 != MG_RETCODE_OK) return NO;

        NSData *tempResult = [NSData dataWithBytes:tempFloat length:featureDataLength * sizeof(float)];
        [faceInfo set_feature_data:tempResult];
        NSLog(@"feature length = %d",featureDataLength);
        NSLog(@"feature length = %lu",(unsigned long)tempResult.length);
        free(tempFloat);

        return YES;
    }
}

- (float)faceCompareWithFaceInfo:(MGFaceInfo *)faceInfo faceInf2:(MGFaceInfo *)faceInf2{
    return [self faceCompareWithFeatureData:faceInfo.featureData featureData2:faceInf2.featureData];
}

- (float)faceCompareWithFeatureData:(NSData *)featureData featureData2:(NSData *)featureData2{
    if (featureData == nil || featureData2 == nil) return -1.0;
    
    double like = 0;
    
    const float *a1 = featureData.bytes;
    const float *a2 = featureData2.bytes;
    // float 占4个字节  NSData.length 为字节长度
    MG_RETCODE returnCode = mg_facepp.FaceCompare(_apiHandle, a1, a2, (int)featureData.length/4, &like);
    
    if (returnCode == MG_RETCODE_OK) {
        return like;
    }
    return -1.0;
}

#pragma mark - 人脸置信度 -
- (float)getFaceConfidenceFilter {
    float confidence = 0.0;
    MG_RETCODE code = mg_facepp.GetFaceConfidenceFilter(_apiHandle, &confidence);
    if (code == MG_RETCODE_OK) {
        return confidence;
    }
    return -1.0;
}

- (BOOL)setFaceConfidenceFilter:(float)filter {
    MG_RETCODE code = mg_facepp.SetFaceConfidenceFilter(_apiHandle, filter);
    if (code == MG_RETCODE_OK) {
        return YES;
    }
    return NO;
}

- (BOOL)shutDown {
    MG_RETCODE code = mg_facepp.ShutDown();
    if (MG_RETCODE_OK == code) {
        return YES;
    }
    return NO;
}

#pragma mark - 检测器控制方法
- (void)beginDetectionFrame{
    @synchronized (self) {
        if (MGMarkWaiting == self.status  || MGMarkPrepareWork == self.status) {
            _status = MGMarkWaiting;
            self.canDetect = YES;
        }
    }
}
- (void)endDetectionFrame{
    @synchronized (self) {
        if (_status != MGMarkStopped) {
            _status = MGMarkWaiting;
            self.canDetect = NO;
            
            [self.tempImageData releaseImageData];
        }
    }
}
- (void)stopAllDetection{
    @synchronized (self) {
        _status = MGMarkStopped;
        self.canDetect = NO;
    }
}

#pragma mark - get sdk info

+ (NSDate *)getApiExpiration {
    NSUInteger result = (NSUInteger)mg_facepp.GetApiExpiration();
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:result];

    return date;
}

/** 获取版本号 */
+ (NSString *)getJenkinsNumber {
    const char *tempStr = mg_facepp.GetJenkinsNumber();
    NSString *string = [NSString stringWithCString:tempStr encoding:NSUTF8StringEncoding];
    return string;
}

+ (NSString *)getSDKVersion {
    const char *tempStr = mg_facepp.GetApiVersion();
    NSString *string = [NSString stringWithCString:tempStr encoding:NSUTF8StringEncoding];
    return string;
}

+ (NSString *)getSDKBundleID {
    const char *tempStr = mg_facepp.GetSDKBundleId();
    NSString *string = [NSString stringWithCString:tempStr encoding:NSUTF8StringEncoding];
    return string;
}

- (BOOL)resetTrack {
    MG_RETCODE code = mg_facepp.ResetTrack(_apiHandle);
    if (MG_RETCODE_OK == code) {
        return YES;
    }
    return NO;
}

+ (BOOL)isMapSDKBundleID {
    NSString *currentBundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *SDKBundleID = [MGFacepp getSDKBundleID];
    NSArray *arr = [SDKBundleID componentsSeparatedByString:@","];
    for (NSString *bundleId in arr) {
        if ([bundleId hasSuffix:@"."] || [bundleId hasSuffix:@"*"]) {
            if ([currentBundleID hasPrefix:bundleId]) {
                return YES;
            }
        } else {
            if ([currentBundleID isEqualToString:bundleId]) {
                return YES;
            }
        }
    }
    
    NSLog(@"error: Bundle id error \r\n your APP bundle id: %@ \r\n SDK bundle id: %@",currentBundleID, SDKBundleID);
    return NO;
}

+ (MGAlgorithmInfo *)getSDKAlgorithmInfoWithModel:(NSData *)modelData{
    if (modelData) {
        MGAlgorithmInfo *infoModel = [[MGAlgorithmInfo alloc] init];
        
        const void *modelBytes = modelData.bytes;
        MG_ABILITY abilityInfo;
        
        MG_RETCODE sucessCode = mg_facepp.GetAbility((MG_BYTE *)modelBytes, (MG_INT32)modelData.length, &abilityInfo);
        
        if (sucessCode != MG_RETCODE_OK) {
            NSLog(@"[initWithModel:] 初始化失败，modelData 与 SDK 不匹配！，请检查后重试！errorCode:%zi", sucessCode);
            return nil;
        }
        
        MG_SDKAUTHTYPE auth = mg_facepp.GetSDKAuthType();
        BOOL needLicense = (auth == MG_ONLINE_AUTH? YES : NO);
        NSString *version = [self getSDKVersion];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:mg_facepp.GetApiExpiration()];
        
        [infoModel setAbility:abilityInfo.ability];
        [infoModel setDate:date];
        [infoModel setLicense:needLicense];
        [infoModel setVersionCode:version];
        
        return infoModel;
    }else{
        NSLog(@"[initWithModel:] 初始化失败，无法读取 modelData，请检查！");
        return nil;
    }
}

- (MGFaceppConfig *)getFaceppConfig{
    return _faceppConfig;
}

- (void)dealloc{
    mg_facepp.ReleaseApiHandle(_apiHandle);
    mg_facepp.ReleaseImageHandle(_imageHandle);
}

@end




