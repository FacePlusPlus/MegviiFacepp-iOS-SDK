//
//  MGAutoSessionPreset.m
//  MGBaseKit
//
//  Created by 张英堂 on 16/8/2.
//  Copyright © 2016年 megvii. All rights reserved.
//

#import "MGAutoSessionPreset.h"
#import "MGBaseDefine.h"
#import <sys/utsname.h>



@implementation MGAutoSessionPreset


+ (NSString *)autoSessionPreset{
    
    NSString *tempSessionPreset;
    
    if (MG_WIN_WIDTH == 320 && MG_WIN_HEIGHT == 480) {
        tempSessionPreset = AVCaptureSessionPreset640x480;
    }else{
        tempSessionPreset = AVCaptureSessionPresetiFrame1280x720;
    }
    
    return tempSessionPreset;
}

+ (CGSize)autoSessionPresetSize{
    CGSize returnSize;
    
    if (MG_WIN_WIDTH == 320 && MG_WIN_HEIGHT == 480) {
        returnSize = CGSizeMake(640, 480);
    }else{
        returnSize = CGSizeMake(1280, 720);
    }
    
    return returnSize;
}




@end
