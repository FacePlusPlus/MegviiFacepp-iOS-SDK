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


+ (NSString*)getContextWithDuration:(MGLicenseDuration)duration
                               UUID:(NSString *)UUID
                          candidate:(NSArray <NSNumber *>*)APIName;

/**
 *  设置联网授权信息
 *
 *  @param license license
 *
 *  @return 成功或失败
 */
+ (BOOL)setLicense:(NSString*) license;



#pragma mark - 简单调用联网授权

/**
   联网获取授权信息

 @param duration 一次授权时长
 @param UUID UUID
 @param APIName API name
 @param apiKey apiKey
 @param apiSecret apiSecret
 @param finish 授权结束回调
 @return NSURLSessionTask
 */
+ (NSURLSessionTask *)takeLicenseFromNetwokrDuration:(MGLicenseDuration)duration
                                                UUID:(NSString *)UUID
                                           candidate:(NSArray <NSNumber *>*)APIName
                                              apiKey:(NSString *)apiKey
                                           apiSecret:(NSString *)apiSecret
                                              finish:(void(^)(BOOL License, NSError *error))finish;



@end
