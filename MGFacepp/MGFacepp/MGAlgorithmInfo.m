//
//  MGAlgorithmInfo.m
//  MGFacepp
//
//  Created by 张英堂 on 2017/1/10.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import "MGAlgorithmInfo.h"
#import "MG_Facepp.h"
#import "MGFaceppCommon.h"

@implementation MGAlgorithmInfo

- (void)setAbility:(uint64_t )ability{
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:3];

    const int functionCount = 9;
    
    int funcArray[functionCount] = {
        MG_FPP_TRACK, MG_FPP_DETECT,
        MG_FPP_ATTR_POSE3D, MG_FPP_ATTR_EYESTATUS,
        MG_FPP_ATTR_MOUTHSTATUS, MG_FPP_ATTR_MINORITY,
        MG_FPP_ATTR_BLURNESS, MG_FPP_ATTR_AGE_GENDER,
        MG_FPP_ATTR_EXTRACT_FEATURE
    };
    
    for (int i = 0; i < functionCount; i++) {
        int64_t temp = funcArray[i];
        int64_t a = ability & temp;
        
        if (a == temp) {
            MGFaceAbility Ability = (MGFaceAbility)i;
            [tempArray addObject:[NSNumber numberWithLongLong:Ability]];
        }
    }
    
    _SDKAbility = tempArray;
    
}

-(void)setDate:(NSDate *)date{
    _expireDate = date;
}


- (void)setLicense:(BOOL)license{
    _needNetLicense = license;
}

- (void)setVersionCode:(NSString *)version{
    _version = version;
}

@end
