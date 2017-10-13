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

typedef NS_OPTIONS(NSInteger, MGFaceppAbilityType) {
    MGFaceppAbilityTypePose3D           = 1U<<0,
    MGFaceppAbilityTypeEyeStatus        = 1U<<1,
    MGFaceppAbilityTypeMouthStatus      = 1U<<2,
    MGFaceppAbilityTypeMinority         = 1U<<3,
    MGFaceppAbilityTypeBlurness         = 1U<<4,
    MGFaceppAbilityTypeAgeGender        = 1U<<5,
    MGFaceppAbilityTypeExtractFeature   = 1U<<6,
    MGFaceppAbilityTypeTrackFast        = 1U<<7,
    MGFaceppAbilityTypeTrackRobust      = 1U<<8,
    MGFaceppAbilityTypeDetect           = 1U<<12,
    MGFaceppAbilityTypeIDCardQuality    = 1U<<13,
    MGFaceppAbilityTypeTrack            = 1U<<14,
};

@implementation MGAlgorithmInfo

- (void)setAbility:(uint64_t )ability {

    NSDictionary *abilityName = @{@(1U<<0)  : MG_ABILITY_KEY_POSE3D,
                                  @(1U<<1)  : MG_ABILITY_KEY_EYE_STATUS,
                                  @(1U<<2)  : MG_ABILITY_KEY_MOUTH_SATUS,
                                  @(1U<<3)  : MG_ABILITY_KEY_MINORITY,
                                  @(1U<<4)  : MG_ABILITY_KEY_BLURNESS,
                                  @(1U<<5)  : MG_ABILITY_KEY_AGE_GENDER,
                                  @(1U<<6)  : MG_ABILITY_KEY_EXTRACT_FEATURE,
                                  @(1U<<7)  : MG_ABILITY_KEY_TRACK_FAST,
                                  @(1U<<8)  : MG_ABILITY_KEY_TRACK_ROBUST,
                                  @(1U<<12) : MG_ABILITY_KEY_DETECT,
                                  @(1U<<13) : MG_ABILITY_KEY_IDCARD_QUALITY,
                                  @(1U<<14) : MG_ABILITY_KEY_TRACK};

    NSMutableArray *names = [NSMutableArray array];
    for (int i = 0; i < 15; i++) {
        if (ability & 1<<i) {
            [names addObject:abilityName[@(1<<i)]];
        }
    }

    _SDKAbility = [NSArray arrayWithArray:names];
}

- (void)setDate:(NSDate *)date {
    _expireDate = date;
}

- (void)setLicense:(BOOL)license {
    _needNetLicense = license;
}

- (void)setVersionCode:(NSString *)version {
    _version = version;
}

@end
