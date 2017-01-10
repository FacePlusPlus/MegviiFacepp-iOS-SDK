//
//  MGFaceInfo_Creat.h
//  MGLandMark
//
//  Created by 张英堂 on 16/9/5.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGFaceInfo.h"
#import "MG_Common.h"
#import "MGFaceppConfig.h"

@interface MGFaceInfo ()

+ (instancetype)modelWithPoint:(MG_FACELANDMARKS )points
                   pointsCount:(NSInteger)count
                    mgFaceInfo:(MG_RECTANGLE)faceinfo
                    confidence:(CGFloat)confidence;



- (void)resetPoints:(MG_POINT *)points pointsCount:(int)count;


- (void)setFace3D:(MG_FACE)face;

- (void)set_eyes_status:(float *)eyesStatus isLeft:(BOOL)left;
- (void)set_mouse_status:(float *)mouseStatus;

- (void)set_age_status:(float)age;
- (void)set_blurness_status:(float)blurness;
- (void)set_minority_status:(float)minority;

- (void)setProperty:(int64_t)Property MGFACE:(MG_FACE)face;

- (void)set_feature_data:(NSData *)data;



@end
