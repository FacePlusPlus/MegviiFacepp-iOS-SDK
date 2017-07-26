//
//  MGLicenseCommon.h
//  MGMobileSDKAuth
//
//  Created by 张英堂 on 2017/1/10.
//  Copyright © 2017年 megvii. All rights reserved.
//

#ifndef MGLicenseCommon_h
#define MGLicenseCommon_h

typedef NS_ENUM(NSInteger, MGAPIDuration) {
    MGAPIDurationDay = 1,
    MGAPIDurationMonth = 30,
    MGAPIDurationYear = 365,
};

typedef NS_ENUM(NSInteger, MGSDKType) {
    MGSDKTypeLandmark = 1,
    MGSDKTypeIDCard = 2,
};

static NSString *MGLicenseURL_CN = @"https://api-cn.faceplusplus.com/sdk/v2/auth";
static NSString *MGLicenseURL_US = @"https://api-us.faceplusplus.com/sdk/v2/auth";


#define MG_LICENSE_DEBUG 1
#if MG_LICENSE_DEBUG
#define MG_LICENSE_LOG(FORMAT, ...) fprintf(stderr,"%s:%d   \t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSLog(FORMAT, ...) nil
#endif



#endif /* MGLicenseCommon_h */
