//
//  MGAutoSessionPreset.h
//  MGBaseKit
//
//  Created by 张英堂 on 16/8/2.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MGAutoSessionPreset : NSObject

/**
 *  获取与屏幕尺寸比例相同的视频流
 *
 *  @return SessionPreset
 */
+ (NSString *)autoSessionPreset;


+ (CGSize)autoSessionPresetSize;


@end
