//
//  MGLicenseManager.h
//  MGBaseKit
//
//  Created by 张英堂 on 16/9/5.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGLicenseCommon.h"

@interface MGLicenseManager : NSObject


/**
 获取过期时间

 @param version SDK 版本号
 @return 过期日期
 */
+ (NSDate *)getExpiretime:(NSString *)version;



#pragma mark - 简单调用联网授权

/**
 联网获取授权信息
 
 @param UUID UUID
 @param APIName API name
 @param sdkType SDK 类型
 @param apiKey apiKey
 @param apiSecret apiSecret
 @param duration appKey有效期类型
 @param url
 @param complete 授权结束回调
 @return SessionTask
 */
+ (NSURLSessionTask *)takeLicenseFromNetwokrUUID:(NSString *)UUID
                                         version:(NSString *)version
                                         sdkType:(MGSDKType)sdkType
                                          apiKey:(NSString *)apiKey
                                       apiSecret:(NSString *)apiSecret
                                     apiDuration:(MGAPIDuration)duration
                                       URLString:(NSString *)url
                                          finish:(void(^)(bool License, NSError *error))complete;



@end
