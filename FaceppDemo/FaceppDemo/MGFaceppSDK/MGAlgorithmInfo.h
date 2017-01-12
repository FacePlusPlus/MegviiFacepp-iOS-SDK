//
//  MGAlgorithmInfo.h
//  MGFacepp
//
//  Created by 张英堂 on 2017/1/10.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MGAlgorithmInfo : NSObject



/**
 SDK 版本号
 */
@property (nonatomic, copy, readonly) NSString *version;

/**
 SDK 过期时间
 */
@property (nonatomic, strong, readonly) NSDate *expireDate;


/**
 是否需要联网授权
 */
@property (nonatomic, assign, readonly) BOOL needNetLicense;


/**
 SDK 功能列表
 */
@property (nonatomic, strong, readonly) NSArray <NSValue *>* SDKAbility;


@end
