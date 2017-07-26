//
//  MGLicenseHandle.m
//  MGSDKV2Test
//
//  Created by 张英堂 on 16/9/7.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGFaceLicenseHandle.h"
#import "MGFacepp.h"
#import "MGNetAccount.h"


@implementation MGFaceLicenseHandle


#if MG_USE_ONLINE_AUTH

+ (BOOL)getLicense{
    NSDate *sdkDate = [self getLicenseDate];
    return [self compareSDKDate:sdkDate];
}


+ (void)licenseForNetwokrFinish:(void(^)(bool License, NSDate *sdkDate))finish{
    
    NSDate *licenSDKDate = [self getLicenseDate];
    
    if ([self compareSDKDate:licenSDKDate] == NO) {
        if (finish) {
            finish(YES, [self getLicenseDate]);
        }
        return;
    }
    
    NSNumber *facelicenSDK = [NSNumber numberWithUnsignedInteger:[MGFacepp getAPIName]];
    NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    [MGLicenseManager takeLicenseFromNetwokrUUID:uuid
                                       candidate:facelicenSDK
                                         sdkType:MGSDKTypeLandmark
                                          apiKey:MG_LICENSE_KEY
                                       apiSecret:MG_LICENSE_SECRET
                                     apiDuration:MGAPIDurationDay
                                       URLString:MGLicenseURL_CN
                                          finish:^(bool License, NSError *error) {
                                              NSLog(@"%@", error);
                                              if (License) {
                                                  NSDate  *nowSDKDate = [self getLicenseDate];
                                                  if (finish) {
                                                      finish(License, nowSDKDate);
                                                  }
                                              } else {
                                                  if (finish) {
                                                      finish(License, licenSDKDate);
                                                  }
                                              }
                                          }];
}

+ (NSDate *)getLicenseDate{
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    MGAlgorithmInfo *sdkInfo = [MGFacepp getSDKAlgorithmInfoWithModel:modelData];
    
    if (sdkInfo.needNetLicense) {
        return [MGFacepp getApiExpiration];
    }
    
    return sdkInfo.expireDate;
}

+ (BOOL)compareSDKDate:(NSDate *)sdkDate{
    
    NSDate *nowDate = [NSDate date];
    double result = [sdkDate timeIntervalSinceDate:nowDate];

    
    if (result >= 1*24*60*60.0) {
        return NO;
    }
    return YES;
}

+ (BOOL)getNeedNetLicense{
    
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:KMGFACEMODELNAME ofType:@""];
    NSData *modelData = [NSData dataWithContentsOfFile:modelPath];
    
    MGAlgorithmInfo *sdkInfo = [MGFacepp getSDKAlgorithmInfoWithModel:modelData];
    NSLog(@"\n************\nSDK 功能列表: %@\n是否需要联网授权: %d\n版本号:%@\n过期时间:%@ \n************", sdkInfo.SDKAbility, sdkInfo.needNetLicense, sdkInfo.version, sdkInfo.expireDate);
    
    return sdkInfo.needNetLicense;
}

#else

#endif

@end
