//
//  MGConvertImage.h
//  FaceppDemo
//
//  Created by Li Bo on 2017/5/22.
//  Copyright © 2017年 megvii. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@interface MGConvertImage : NSObject

+ (UIImage *)convertSampleBufferToImage:(CMSampleBufferRef)sampleBuffer;

+ (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect;

@end
