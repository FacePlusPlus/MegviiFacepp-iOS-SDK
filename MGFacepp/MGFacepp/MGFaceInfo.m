//
//  MGFaceModel.m
//  LandMask
//
//  Created by 张英堂 on 16/7/11.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGFaceInfo.h"
#import "MG_Common.h"
#import "MG_Facepp.h"

@implementation MGFaceInfo

-(void)dealloc{
    _featureData = nil;
    _points = nil;
}

+ (instancetype)modelWithPoint:(MG_FACELANDMARKS )points
                   pointsCount:(NSInteger)count
                    mgFaceInfo:(MG_RECTANGLE)faceinfo
                    confidence:(CGFloat)confidence{
    
    MGFaceInfo *model = [[MGFaceInfo alloc] init];
    if (model) {
        
        CGRect headerRect = CGRectMake(faceinfo.left,
                                       faceinfo.top,
                                       faceinfo.right - faceinfo.left,
                                       faceinfo.bottom - faceinfo.top);
        model.rect = headerRect;
        model.confidence = confidence;
        
        NSMutableArray *tempArray = [NSMutableArray array];
        
        for (int i = 0; i < count; i++){
            CGPoint drawPoint = CGPointMake(points.point[i].x, points.point[i].y);
            [tempArray addObject:[NSValue valueWithCGPoint:drawPoint]];
        }
        
        model.points = [NSArray arrayWithArray:tempArray];
    }
    return model;
}

- (void)resetPoints:(MG_POINT *)points pointsCount:(int)count{
    NSMutableArray *tempArray = [NSMutableArray array];
    
    for (int i = 0; i < count; i++){
        CGPoint drawPoint = CGPointMake(points[i].x, points[i].y);
        
        [tempArray addObject:[NSValue valueWithCGPoint:drawPoint]];
    }
    
    self.points = [NSArray arrayWithArray:tempArray];
}

- (void)setFace3D:(MG_FACE)face{
    self.pitch = face.pose.pitch;
    self.yaw = face.pose.yaw;
    self.roll = face.pose.roll;
}

- (void)set_eyes_status:(float *)eyesStatus isLeft:(BOOL)left{
    
    int maxStatus = MG_EYESTATUS_NOGLASSES_EYEOPEN;
    float size = 0;
    for (int i = 0; i < MG_EYESTATUS_COUNT; i++) {
        float temp = eyesStatus[i];
        if (temp >= size) {
            maxStatus = i;
            size = temp;
        }
    }
    if (YES == left) {
        self.leftEyesStatus = (MGEyeStatus)maxStatus;
    }else{
        self.rightEyesStatus = (MGEyeStatus)maxStatus;
    }
}

- (void)set_mouse_status:(float *)mouseStatus{
    
    int maxStatus = MG_MOUTHSTATUS_OPEN;
    float size = 0;
    for (int i = 0; i < MG_MOUTHSTATUS_COUNT; i++) {
        float temp = mouseStatus[i];
        if (temp >= size) {
            maxStatus = i;
            size = temp;
        }
    }
    self.mouseStatus = (MGMouthStatus)maxStatus;
}

- (void)set_age_status:(float)age gender:(MG_GENDER)gender{
    self.age = age;
    
    if (gender.female > gender.male) {
        self.gender = 0;
    }else{
        self.gender = 1;
    }
}

- (void)set_blurness_status:(float)blurness{
    self.blurness = blurness;
}

- (void)set_minority_status:(float)minority{
    self.minority = minority;
}

- (void)set_feature_data:(NSData *)data{
    _featureData = data;
}


- (void)setProperty:(int64_t)Property MGFACE:(MG_FACE)face{
    
    switch (Property) {
        case MG_FPP_ATTR_POSE3D:
            [self setFace3D:face];
            break;
        case MG_FPP_ATTR_EYESTATUS:
            [self set_eyes_status:face.left_eyestatus isLeft:YES];
            [self set_eyes_status:face.right_eyestatus isLeft:NO];
            break;
        case MG_FPP_ATTR_MOUTHSTATUS:
            [self set_mouse_status:face.moutstatus];
            break;
        case MG_FPP_ATTR_MINORITY:
            [self set_minority_status:face.minority];
            break;
        case MG_FPP_ATTR_BLURNESS:
            [self set_blurness_status:face.blurness];
            break;
        case MG_FPP_ATTR_AGE_GENDER:
            [self set_age_status:face.age gender:face.gender];
            break;
        case MG_FPP_ATTR_EXTRACT_FEATURE:
            break;
        default:
            break;
    }
}





@end
