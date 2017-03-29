//
//  MGFacepp.m
//  LandMask
//
//  Created by 张英堂 on 16/9/5.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGFacepp.h"
#import "MG_Facepp.h"
#import "MG_Common.h"
#import "MGFaceInfo_Creat.h"
#import "MGAlgorithmInfo_Creat.h"

@interface MGFacepp ()
{
    MG_FPP_APIHANDLE _apiHandle;
    MG_FPP_IMAGEHANDLE _imageHandle;
    
    int32_t _tempLength;
}
@property (nonatomic, strong) MGImageData *tempImageData;

@property (nonatomic, assign) BOOL currentFrameIsImage;
@property (nonatomic, assign) BOOL canDetect;

@property (nonatomic, strong, getter = getFaceppConfig) MGFaceppConfig *faceppConfig;

/** 设置视频流格式，默认 PixelFormatTypeRGBA */
@property (nonatomic, assign) MGPixelFormatType pixelFormatType;

@end

@implementation MGFacepp

- (MGFaceppConfig *)getFaceppConfig{
    return _faceppConfig;
}

-(void)dealloc{
    mg_facepp.ReleaseApiHandle(_apiHandle);
    mg_facepp.ReleaseImageHandle(_imageHandle);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [NSException raise:@"提示！" format:@"请使用 MGFacepp initWithModel: 初始化方式！"];
    }
    return self;
}

- (instancetype)initWithModel:(NSData *)modelData faceppSetting:(void(^)(MGFaceppConfig *config))config{
    self = [super init];
    if (self) {
        if (modelData.length > 0) {
            const void *modelBytes = modelData.bytes;
            MG_RETCODE initCode = mg_facepp.CreateApiHandle((MG_BYTE *)modelBytes, (MG_INT32)modelData.length, &_apiHandle);
            
            if (initCode != MG_RETCODE_OK) {
                NSLog(@"[initWithModel:] 初始化失败，modelData 与 SDK 不匹配！，请检查后重试！errorCode:%zi", initCode);
                return nil;
            }
            
            self.faceppConfig = [[MGFaceppConfig alloc] init];
            [self updateFaceppSetting:config];
            
            _tempLength = 0;
        }else{
            NSLog(@"[initWithModel:] 初始化失败，无法读取 modelData，请检查！");
            return nil;
        }
        
        _status = MGMarkPrepareWork;
        self.currentFrameIsImage = NO;
        self.canDetect = NO;
    }
    return self;
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
        case MGFppDetectionModeNormal:
            model = MG_FPP_DETECTIONMODE_NORMAL;
            break;
        case MGFppDetectionModeTracking:
            model = MG_FPP_DETECTIONMODE_TRACKING;
            break;
        case MGFppDetectionModeTrackingSmooth:
            model = MG_FPP_DETECTIONMODE_TRACKING_SMOOTH;
            break;
        case MGFppDetectionModeTrackingFast:
            model = MG_FPP_DETECTIONMODE_TRACKING_FAST;
            break;
        case MGFppDetectionModeTrackingRobust:
            model = MG_FPP_DETECTIONMODE_TRACKING_ROBUST;
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
        }else{
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
                    NSArray *faceinfoArray = [self getFaceInfoWithFaceCount:faceCount FPPAPIHANDLE:_apiHandle];
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

/* 如果人脸数量超过 1 个，进行人脸关键点检测  */
- (NSArray <MGFaceInfo *>*)getFaceInfoWithFaceCount:(NSInteger)count FPPAPIHANDLE:(MG_FPP_APIHANDLE)apiHandle{
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++){
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
        MG_RETCODE returnCode2 = mg_facepp.ExtractFeature(_apiHandle, _imageHandle, faceInfo.index, &_tempLength);
        if (returnCode2 != MG_RETCODE_OK) return NO;

        float *tempFloat = (float*)malloc(_tempLength * sizeof(float));
        MG_RETCODE returnCode3 = mg_facepp.GetFeatureData(_apiHandle, tempFloat, _tempLength);
        
        if (returnCode3 != MG_RETCODE_OK) return NO;

        NSData *tempResult = [NSData dataWithBytes:tempFloat length:_tempLength * sizeof(float)];
        [faceInfo set_feature_data:tempResult];

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
    
    MG_RETCODE returnCode = mg_facepp.FaceCompare(_apiHandle, a1, a2, _tempLength, &like);
    
    if (returnCode == MG_RETCODE_OK) {
        return like;
    }
    return -1.0;
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
/** 获取API 联网授权使用 */
+ (NSUInteger)getAPIName{
   NSUInteger result = (NSUInteger)mg_facepp.GetApiVersion;
    return result;
}

+ (NSDate *)getApiExpiration{

    NSUInteger result = (NSUInteger)mg_facepp.GetApiExpiration();
    NSData *date = [NSDate dateWithTimeIntervalSince1970:result];

    return date;
}

/** 获取版本号 */
+ (NSString *)getVersion{
    const char *tempStr = mg_facepp.GetApiVersion();
    NSString *string = [NSString stringWithCString:tempStr encoding:NSUTF8StringEncoding];
    return string;
}

+ (MGAlgorithmInfo *)getSDKAlgorithmInfoWithModel:(NSData *)modelData{
    if (modelData) {
        MGAlgorithmInfo *infoModel = [[MGAlgorithmInfo alloc] init];
        
        const void *modelBytes = modelData.bytes;
        MG_ALGORITHMINFO info;
        MG_RETCODE sucessCode = mg_facepp.GetAlgorithmInfo((MG_BYTE *)modelBytes, (MG_INT32)modelData.length, &info);
        
        if (sucessCode != MG_RETCODE_OK) {
            NSLog(@"[initWithModel:] 初始化失败，modelData 与 SDK 不匹配！，请检查后重试！errorCode:%zi", sucessCode);
            return nil;
        }
        
        BOOL needLicense = (info.auth_type == MG_ONLINE_AUTH? YES : NO);
        NSString *version = [self getVersion];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:info.expire_time];
        
        [infoModel setAbility:info.ability];
        [infoModel setDate:date];
        [infoModel setLicense:needLicense];
        [infoModel setVersionCode:version];
        
        return infoModel;
    }else{
        NSLog(@"[initWithModel:] 初始化失败，无法读取 modelData，请检查！");
        return nil;
    }
}

@end




