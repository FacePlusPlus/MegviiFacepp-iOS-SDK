//
//  YTLogManager.h
//  BankCardTest
//
//  Created by 张英堂 on 15/12/9.
//  Copyright © 2015年 megvii. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface MGLogManager : NSObject

/**
 *  单例
 *
 *  @return 返回实例化对象
 */
+ (instancetype)sharedInstance;



/**
 *  添加一条Log （子线程中进行文件读写处理）
 *
 *  @param logString log内容
 *  @param fileName  要写入的文件名
 */
- (void)addLog:(NSString *)logString fileName:(NSString *)fileName;


@end
