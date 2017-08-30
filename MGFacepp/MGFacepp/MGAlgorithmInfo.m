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
    NSDictionary *abilityName = @{@(1U<<0)  : @"pose3D",
                                  @(1U<<1)  : @"eyeStatus",
                                  @(1U<<2)  : @"mouthStatus",
                                  @(1U<<3)  : @"minority",
                                  @(1U<<4)  : @"blurness",
                                  @(1U<<5)  : @"ageGender",
                                  @(1U<<6)  : @"extractFeature",
                                  @(1U<<7)  : @"trackFast",
                                  @(1U<<8)  : @"trackRobust",
                                  @(1U<<9)  : @"",
                                  @(1U<<10) : @"",
                                  @(1U<<11) : @"",
                                  @(1U<<12) : @"detect",
                                  @(1U<<13) : @"IDCardQuality",
                                  @(1U<<14) : @"track",};
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
